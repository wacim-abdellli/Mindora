import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_data_cipher.dart';

/// Coordinator for transparent encryption at rest and safe legacy plaintext migration.
class EncryptedStorageHelper {
  /// Reads a record from SharedPreferences under [key].
  ///
  /// - If the record begins with [LocalDataCipher.prefixV1], it decrypts and authenticates it via AES-256-GCM.
  /// - If the record is legacy plaintext, it validates it, encrypts it with a fresh nonce,
  ///   verifies round-trip decryption in-memory, persists the encrypted record to storage,
  ///   and returns the plaintext.
  static Future<String?> readAndMigrate({
    required SharedPreferences prefs,
    required String key,
    required LocalDataCipher cipher,
  }) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    if (LocalDataCipher.isEncrypted(raw)) {
      try {
        return await cipher.decryptString(raw);
      } catch (e) {
        rethrow;
      }
    }

    // Legacy plaintext detected: Execute non-destructive verified migration
    try {
      final encrypted = await cipher.encryptString(raw);
      final verified = await cipher.decryptString(encrypted);
      if (verified == raw) {
        await prefs.setString(key, encrypted);
      }
    } catch (_) {
      // In case of any migration storage issue, preserve the original data safely
    }

    return raw;
  }

  /// Encrypts [plaintext] with a unique CSPRNG nonce under AES-256-GCM and persists it.
  static Future<void> writeEncrypted({
    required SharedPreferences prefs,
    required String key,
    required String plaintext,
    required LocalDataCipher cipher,
  }) async {
    final encrypted = await cipher.encryptString(plaintext);
    await prefs.setString(key, encrypted);
  }

  /// Reads via [readAndMigrate] and recovers cleanly if platform keystore rotation
  /// (`resetOnError: true`) rendered an earlier ciphertext unreadable.
  ///
  /// Quarantines the unreadable ciphertext under `${key}_orphaned_v1`, clears [key],
  /// and returns `null` so clinic simulator and local UI caches do not permanently crash.
  static Future<String?> readAndMigrateRecoverable({
    required SharedPreferences prefs,
    required String key,
    required LocalDataCipher cipher,
  }) async {
    try {
      return await readAndMigrate(prefs: prefs, key: key, cipher: cipher);
    } on DecryptionSecurityException catch (e) {
      debugPrint(
        'EncryptedStorageHelper: quarantined undecryptable key "$key": $e',
      );
      final stale = prefs.getString(key);
      if (stale != null && stale.isNotEmpty) {
        await prefs.setString('${key}_orphaned_v1', stale);
      }
      await prefs.remove(key);
      return null;
    }
  }
}

