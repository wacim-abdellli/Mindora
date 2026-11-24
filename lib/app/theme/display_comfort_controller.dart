import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kDisplayComfortPrefKey = 'mf_display_comfort_v1';

/// Overridden at app startup so Comfort & Clarity Mode renders cleanly
/// from Frame 1 with zero visual jump.
final initialComfortModeProvider = Provider<bool>((ref) => false);

final displayComfortProvider =
    NotifierProvider<DisplayComfortController, bool>(
  DisplayComfortController.new,
);

/// Controls universal Comfort & Clarity Mode (+15% clamped readable text and
/// boosted borders/contrast) for older eyes, tired evenings, and bright rooms.
class DisplayComfortController extends Notifier<bool> {
  static Future<bool> loadInitial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kDisplayComfortPrefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  bool build() => ref.watch(initialComfortModeProvider);

  Future<void> setComfortMode(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kDisplayComfortPrefKey, enabled);
    } catch (_) {
      // Best-effort local persistence; in-memory state remains responsive.
    }
  }

  Future<void> toggle() => setComfortMode(!state);
}
