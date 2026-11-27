import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/clinician_models.dart';

/// Isolated, AES-256-GCM encrypted repository for the Psychiatrist Workspace.
///
/// Uses the distinct `clinician_workspace_v1` cryptographic subkey partition via
/// [SecureKeyManager] so clinician data and private session notes remain separated
/// from patient storage keys.
class LocalClinicianRepository {
  LocalClinicianRepository({required SecureKeyManager keyManager})
      : _keyManager = keyManager;

  final SecureKeyManager _keyManager;

  static const String _patientsKey = 'mf_clinician_patients_v1';
  static const String _profileKey = 'mf_clinician_profile_v1';
  static const String _demoEnabledKey = 'mf_clinician_demo_enabled_v1';
  static const String _workspaceRoleKey = 'mf_workspace_role_v1';
  static const String _demoNotesKey = 'mf_clinician_demo_notes_v1';
  static const String _demoReviewedKey = 'mf_clinician_demo_reviewed_v1';

  Future<LocalDataCipher> _getCipher() =>
      _keyManager.getCipherForUser('clinician_workspace_v1');

  Future<List<ClinicianPatientRecord>> loadImportedPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _patientsKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) =>
                ClinicianPatientRecord.fromJson(e as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.lastSyncedAt.compareTo(a.lastSyncedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveImportedPatients(
    List<ClinicianPatientRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final sanitized = records.where((r) => !r.isDemoCase).toList(growable: false);
    final payload = jsonEncode(
      sanitized.map((r) => r.toJson()).toList(growable: false),
    );
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _patientsKey,
      plaintext: payload,
      cipher: cipher,
    );
  }

  Future<void> upsertPatient(
    ClinicianPatientRecord record, {
    bool overwriteNotes = false,
  }) async {
    if (record.isDemoCase) {
      final notesMap = await loadDemoNotes();
      notesMap[record.patientId] = record.clinicianNotes;
      await saveDemoNotes(notesMap);
      if (record.reviewedAt != null) {
        final reviewed = await loadDemoReviewedMap();
        reviewed[record.patientId] = record.reviewedAt!;
        await saveDemoReviewedMap(reviewed);
      }
      return;
    }

    final existing = await loadImportedPatients();
    final idx = existing.indexWhere((r) => r.patientId == record.patientId);
    if (idx >= 0) {
      final mergedNotes = (overwriteNotes || record.clinicianNotes.isNotEmpty)
          ? record.clinicianNotes
          : existing[idx].clinicianNotes;
      existing[idx] = record.copyWith(
        importedAt: existing[idx].importedAt,
        clinicianNotes: mergedNotes,
      );
    } else {
      existing.add(record);
    }
    await saveImportedPatients(existing);
  }

  Future<void> deletePatient(String patientId) async {
    final existing = await loadImportedPatients();
    existing.removeWhere((r) => r.patientId == patientId);
    await saveImportedPatients(existing);
  }

  Future<void> clearImportedPatients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patientsKey);
  }

  Future<Map<String, List<ClinicianSessionNote>>> loadDemoNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _demoNotesKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                (n) =>
                    ClinicianSessionNote.fromJson(n as Map<String, dynamic>),
              )
              .toList(growable: false),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDemoNotes(
    Map<String, List<ClinicianSessionNote>> notesByPatient,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final payload = jsonEncode(
      notesByPatient.map(
        (k, v) => MapEntry(k, v.map((n) => n.toJson()).toList(growable: false)),
      ),
    );
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _demoNotesKey,
      plaintext: payload,
      cipher: cipher,
    );
  }

  Future<Map<String, DateTime>> loadDemoReviewedMap() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _demoReviewedKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, DateTime>{};
      for (final entry in decoded.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) out[entry.key] = parsed;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDemoReviewedMap(Map<String, DateTime> reviewedMap) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final payload = jsonEncode(
      reviewedMap.map((k, v) => MapEntry(k, v.toIso8601String())),
    );
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _demoReviewedKey,
      plaintext: payload,
      cipher: cipher,
    );
  }

  Future<ClinicianProfile> loadClinicianProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _profileKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return const ClinicianProfile();
    try {
      return ClinicianProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ClinicianProfile();
    }
  }

  Future<void> saveClinicianProfile(ClinicianProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _profileKey,
      plaintext: jsonEncode(profile.toJson()),
      cipher: cipher,
    );
  }

  Future<bool> isDemoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoEnabledKey) ?? true;
  }

  Future<void> setDemoEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoEnabledKey, enabled);
  }

  Future<AppWorkspaceRole> loadWorkspaceRole() async {
    final prefs = await SharedPreferences.getInstance();
    return AppWorkspaceRole.fromString(prefs.getString(_workspaceRoleKey));
  }

  Future<void> saveWorkspaceRole(AppWorkspaceRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workspaceRoleKey, role.name);
  }
}
