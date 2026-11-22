import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';

final gentleReminderServiceProvider = Provider<GentleReminderService>((ref) {
  return GentleReminderService();
});

/// Real on-device notification scheduler for opt-in Gentle Reminders.
///
/// Uses `flutter_local_notifications` with inexact battery-friendly intervals
/// so users receive calm, non-punitive check-in prompts without requiring
/// invasive exact-alarm permissions or cloud push servers.
class GentleReminderService {
  GentleReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const int _reminderNotificationId = 1001;
  static const String _channelId = 'gentle_reminders';
  static const String _channelName = 'Gentle Check-In Reminders';
  static const String _channelDescription =
      'Optional, gentle prompts to pause and record a daily check-in.';

  static bool get _isTestOrUnsupported {
    if (kIsWeb) return true;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      return Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return true;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || _isTestOrUnsupported) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Requests OS notification permission when the user opts into reminders.
  /// Returns true if permission is granted (or not needed by the OS version).
  Future<bool> requestPermission() async {
    if (_isTestOrUnsupported) return true;
    try {
      await _ensureInitialized();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Duration _intervalForFrequency(String frequency) {
    switch (frequency) {
      case 'alternate':
        return const Duration(days: 2);
      case 'weekly':
        return const Duration(days: 7);
      case 'daily':
      default:
        return const Duration(days: 1);
    }
  }

  /// Schedules or cancels the gentle reminder loop based on user preferences.
  Future<bool> syncSchedule({
    required bool enabled,
    required String frequency,
    required AppStrings strings,
  }) async {
    if (!enabled) {
      await cancelReminders();
      return true;
    }

    if (_isTestOrUnsupported) return true;

    try {
      final permitted = await requestPermission();
      if (!permitted) return false;
      await _ensureInitialized();
      await _plugin.cancel(id: _reminderNotificationId);

      final title = strings.isArabic
          ? 'تذكير لطيف — Mindora'
          : (strings.isFrench
                ? 'Rappel doux — Mindora'
                : 'Gentle Check-In — Mindora');
      final body = strings.isArabic
          ? 'أثر ذهنك اليومي ينتظرك وقتما تكون مستعداً، بدون أي ضغط.'
          : (strings.isFrench
                ? 'Votre empreinte du jour vous attend quand vous êtes prêt(e).'
                : 'Your daily Mind Trace is waiting whenever you feel ready.');

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _plugin.periodicallyShowWithDuration(
        id: _reminderNotificationId,
        repeatDurationInterval: _intervalForFrequency(frequency),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels any active gentle reminder schedule.
  Future<void> cancelReminders() async {
    if (_isTestOrUnsupported) return;
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _reminderNotificationId);
    } catch (_) {}
  }
}
