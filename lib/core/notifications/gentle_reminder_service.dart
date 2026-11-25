import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import '../widgets/mind_button.dart';
import '../widgets/mind_sheet.dart';

final gentleReminderServiceProvider = Provider<GentleReminderService>((ref) {
  return GentleReminderService();
});

/// Real on-device notification scheduler for opt-in Gentle Reminders.
///
/// Uses localized zero-guilt rotating messages from [AppStrings] and provides
/// a calm pre-permission bottom sheet before prompting the OS dialog.
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

  /// Displays a calm 1-card explanation before triggering the OS permission prompt.
  static Future<bool> showPrePermissionSheet(
    BuildContext context,
    AppStrings strings,
  ) async {
    final result = await showMindSheet<bool>(
      context: context,
      showCloseButton: true,
      title: strings.reminderPermissionTitle,
      builder: (ctx) {
        final tokens = ctx.tokens;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.reminderPermissionBody,
              style: LabTheme.textStyle(
                fontSize: 15.5,
                height: 1.5,
                color: tokens.ink2,
              ),
            ),
            const SizedBox(height: 20),
            MindButton(
              text: strings.enableReminderBtn,
              isFullWidth: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: tokens.ink2,
                ),
                child: Text(
                  strings.notNowBtn,
                  style: LabTheme.textStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
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

      final bodies = strings.gentleReminderBodies;
      final body = bodies[DateTime.now().day % bodies.length];

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
        title: strings.reminderPermissionTitle,
        body: body,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelReminders() async {
    if (_isTestOrUnsupported) return;
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _reminderNotificationId);
    } catch (_) {}
  }
}
