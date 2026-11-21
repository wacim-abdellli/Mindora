import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/post_visit_focus_model.dart';

/// Encrypted patient-side repository storing the active between-session focus
/// plan received from a psychiatrist or clinician (`MF-CAREPLAN-V1:...`).
///
/// Partitioned per patient `userId` via [SecureKeyManager].
class LocalCarePlanRepository {
  LocalCarePlanRepository({
    this.userId,
    SecureKeyManager? keyManager,
  }) : _keyManager = keyManager ?? SecureKeyManager();

  final String? userId;
  final SecureKeyManager _keyManager;

  static const String _legacyStorageKey = 'mf_patient_focus_plan_v1';

  String get _storageKey {
    if (userId != null && userId!.trim().isNotEmpty && userId != 'local_user') {
      return 'mf_patient_focus_plan_${userId!.trim()}';
    }
    return _legacyStorageKey;
  }

  Future<LocalDataCipher> _getCipher() => _keyManager.getCipherForUser(userId);

  Future<PostVisitFocusPlan?> loadActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _storageKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      return PostVisitFocusPlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlan(PostVisitFocusPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _storageKey,
      plaintext: jsonEncode(plan.toJson()),
      cipher: cipher,
    );
  }

  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
