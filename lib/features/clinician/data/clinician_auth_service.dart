import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/data/auth_service.dart';

/// Local PBKDF2-SHA256 authentication & session-lock gate for the Doctor Edition.
///
/// Protects patient records in `main_clinician.dart` behind a clinic PIN (and
/// optional device biometrics) during Spark/offline development, designed to
/// swap cleanly to Firebase Auth custom claims (`role: 'clinician'`) in Phase 7.
class ClinicianAuthService {
  ClinicianAuthService({SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final SecureKeyManager _keyManager;

  static const String _pinHashKey = 'mf_clinician_pin_hash_v1';
  static bool _sessionUnlocked = false;

  static bool get isSessionUnlocked => _sessionUnlocked;

  static void lockSession() {
    _sessionUnlocked = false;
  }

  @visibleForTesting
  static void setUnlockedForTesting(bool unlocked) {
    _sessionUnlocked = unlocked;
  }

  Future<bool> isPinConfigured() async {
    final hash = await _readPinHash();
    return hash != null && hash.isNotEmpty;
  }

  Future<String?> _readPinHash() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('clinician_workspace_v1');
    return EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _pinHashKey,
      cipher: cipher,
    );
  }

  Future<void> setupPin(String pin) async {
    final clean = pin.trim();
    if (clean.length < 4) {
      throw const FormatException('PIN must be at least 4 digits.');
    }
    final hash = AuthService.hashPassword(clean);
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('clinician_workspace_v1');
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _pinHashKey,
      plaintext: hash,
      cipher: cipher,
    );
    _sessionUnlocked = true;
  }

  Future<bool> verifyAndUnlock(String pin) async {
    final clean = pin.trim();
    if (clean.isEmpty) return false;
    final stored = await _readPinHash();
    if (stored == null || stored.isEmpty) return false;

    final result = AuthService.verifyPasswordWithMigration(clean, stored);
    if (!result.isValid) return false;

    if (result.needsRehash) {
      await setupPin(clean);
    } else {
      _sessionUnlocked = true;
    }
    return true;
  }

  Future<bool> unlockWithBiometrics(
    BiometricSecurityService biometricService, {
    required String localizedReason,
  }) async {
    final hasPin = await isPinConfigured();
    if (!hasPin) return false;
    final ok = await biometricService.authenticate(
      reason: localizedReason,
    );
    if (ok) {
      _sessionUnlocked = true;
    }
    return ok;
  }
}

final clinicianAuthServiceProvider = Provider<ClinicianAuthService>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return ClinicianAuthService(keyManager: keyManager);
});
