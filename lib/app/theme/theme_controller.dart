import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mind_tokens.dart';

/// Preloaded [ThemeMode] override populated before `runApp` to prevent startup flash.
/// Fresh installs default to [ThemeMode.light] ("Sunrise" Warm Daylight).
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

/// Notifier controlling dynamic Sunrise (Light), Twilight (Night), and Auto theme modes.
///
/// Defaults to [ThemeMode.light] and persists selection in [SharedPreferences].
class ThemeController extends Notifier<ThemeMode> {
  static const String keyTheme = 'mind_forensics_theme_mode';
  bool _hasExplicitSelection = false;

  /// Reads persisted [ThemeMode] prior to `runApp()` so the first rendered frame
  /// matches the user's choice with zero theme flash.
  static Future<ThemeMode> loadInitialThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return parseThemeMode(prefs.getString(keyTheme));
  }

  static ThemeMode parseThemeMode(String? saved) {
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  static String serializeThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  @override
  ThemeMode build() {
    _hasExplicitSelection = false;
    final initial = ref.read(initialThemeModeProvider);
    _loadSavedTheme();
    return initial;
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyTheme);
    if (_hasExplicitSelection || !ref.mounted) return;
    if (saved != null) {
      state = parseThemeMode(saved);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _hasExplicitSelection = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTheme, serializeThemeMode(mode));
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

/// Active mood driving dynamic `m1` / `m2` accent tokens across the app.
class ActiveMoodController extends Notifier<AppMood> {
  @override
  AppMood build() => AppMood.calm;

  void setMood(AppMood mood) {
    if (state != mood) {
      state = mood;
    }
  }

  void setMoodByKey(String? key) {
    setMood(AppMood.fromKey(key));
  }
}

final activeMoodProvider = NotifierProvider<ActiveMoodController, AppMood>(
  ActiveMoodController.new,
);
