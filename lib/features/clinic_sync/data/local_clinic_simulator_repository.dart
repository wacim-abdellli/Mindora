import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/data/auth_service.dart';
import '../../clinician/data/clinician_sync_service.dart';
import '../../clinician/domain/clinician_models.dart';
import '../../clinician/domain/post_visit_focus_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/clinic_account_models.dart';
import 'clinic_auth_repository.dart';

/// Zero-cost offline Clinic Simulator implementing [ClinicAuthRepository] and
/// [ClinicSyncRepository] with full cryptographic hygiene:
/// - PBKDF2-HMAC-SHA256 password/PIN hashes (zero plaintext storage)
/// - Single-use, expiring QR tokens hashed with SHA-256 + constant-time checks
/// - AES-256-GCM encrypted persistence under `clinic_directory_v1`
/// - Strict multi-tenant isolation by `doctorId` / `clinicId`
/// - Hard exclusion of `isPrivate == true` daily logs and Talks from doctor packets
class LocalClinicSimulatorRepository
    implements ClinicAuthRepository, ClinicSyncRepository {
  LocalClinicSimulatorRepository({
    SecureKeyManager? keyManager,
    ClinicianSyncService? syncService,
  })  : _keyManager = keyManager ?? SecureKeyManager(),
        _syncService = syncService ?? const ClinicianSyncService();

  final SecureKeyManager _keyManager;
  final ClinicianSyncService _syncService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  static const String _accountsKey = 'mf_clinic_sim_accounts_v1';
  static const String _tokensKey = 'mf_clinic_sim_invite_tokens_v1';
  static const String _auditKey = 'mf_clinic_sim_audit_v1';
  static const String _doctorPacketsKey = 'mf_clinic_sim_doctor_packets_v1';
  static const String _inboxKey = 'mf_clinic_sim_patient_inbox_v1';

  Future<LocalDataCipher> _getCipher() =>
      _keyManager.getCipherForUser('clinic_directory_v1');

  Future<String?> _readEncryptedValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    return EncryptedStorageHelper.readAndMigrateRecoverable(
      prefs: prefs,
      key: key,
      cipher: cipher,
    );
  }

  Future<void> _writeEncryptedValue(String key, String plaintext) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _getCipher();
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: key,
      plaintext: plaintext,
      cipher: cipher,
    );
  }

  String _generateTempPin() {
    final n = 100000 + _random.nextInt(900000);
    return n.toString();
  }

  String _generateQrSecret() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashInviteSecret(String tokenId, String secret) {
    return sha256.convert(utf8.encode('$tokenId:$secret')).toString();
  }

  Future<Map<String, ClinicPatientAccount>> _loadAccounts() async {
    final raw = await _readEncryptedValue(_accountsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          ClinicPatientAccount.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAccounts(Map<String, ClinicPatientAccount> map) async {
    final encoded = jsonEncode(map.map((k, v) => MapEntry(k, v.toJson())));
    await _writeEncryptedValue(_accountsKey, encoded);
  }

  Future<Map<String, ClinicInviteTokenRecord>> _loadTokens() async {
    final raw = await _readEncryptedValue(_tokensKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          ClinicInviteTokenRecord.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveTokens(Map<String, ClinicInviteTokenRecord> map) async {
    final encoded = jsonEncode(map.map((k, v) => MapEntry(k, v.toJson())));
    await _writeEncryptedValue(_tokensKey, encoded);
  }

  Future<List<ClinicAuditEntry>> _loadAudit() async {
    final raw = await _readEncryptedValue(_auditKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ClinicAuditEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _appendAudit(ClinicAuditEntry entry) async {
    final list = await _loadAudit();
    list.insert(0, entry);
    final capped = list.take(500).toList(growable: false);
    await _writeEncryptedValue(
      _auditKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  Future<Map<String, Map<String, ClinicianPatientRecord>>>
      _loadDoctorPackets() async {
    final raw = await _readEncryptedValue(_doctorPacketsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (docId, patientsMap) => MapEntry(
          docId,
          (patientsMap as Map<String, dynamic>).map(
            (pid, recJson) => MapEntry(
              pid,
              ClinicianPatientRecord.fromJson(
                recJson as Map<String, dynamic>,
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveDoctorPackets(
    Map<String, Map<String, ClinicianPatientRecord>> data,
  ) async {
    final encoded = jsonEncode(
      data.map(
        (docId, patientsMap) => MapEntry(
          docId,
          patientsMap.map((pid, rec) => MapEntry(pid, rec.toJson())),
        ),
      ),
    );
    await _writeEncryptedValue(_doctorPacketsKey, encoded);
  }

  Future<Map<String, ClinicPatientSyncInbox>> _loadInboxes() async {
    final raw = await _readEncryptedValue(_inboxKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (pid, jsonMap) => MapEntry(
          pid,
          ClinicPatientSyncInbox.fromJson(jsonMap as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveInboxes(
    Map<String, ClinicPatientSyncInbox> inboxes,
  ) async {
    await _writeEncryptedValue(
      _inboxKey,
      jsonEncode(inboxes.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  ClinicPatientAccount _assertDoctorOwnsPatient(
    Map<String, ClinicPatientAccount> accounts,
    String doctorId,
    String patientId,
  ) {
    final account = accounts[patientId];
    if (account == null || account.doctorId != doctorId) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountNotFound,
        'Patient account not found for this clinician.',
      );
    }
    return account;
  }

  ({
    ClinicInviteTokenRecord tokenRecord,
    String qrPayload,
    DateTime expiresAt,
  }) _issueInviteToken({
    required ClinicPatientAccount account,
    required Duration validity,
    required DateTime timestamp,
  }) {
    final tokenId = 'inv_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';
    final secret = _generateQrSecret();
    final expiresAt = timestamp.add(validity);
    final payload = ClinicInvitePayload(
      tokenId: tokenId,
      patientId: account.patientId,
      doctorId: account.doctorId,
      clinicId: account.clinicId,
      doctorName: account.doctorName,
      clinicName: account.clinicName,
      patientDisplayName: account.displayName,
      loginIdentifier: account.loginIdentifier,
      secret: secret,
      expiresAt: expiresAt,
    ).encode();

    final record = ClinicInviteTokenRecord(
      tokenId: tokenId,
      patientId: account.patientId,
      doctorId: account.doctorId,
      clinicId: account.clinicId,
      oneTimeSecretHash: _hashInviteSecret(tokenId, secret),
      createdAt: timestamp,
      expiresAt: expiresAt,
    );

    return (tokenRecord: record, qrPayload: payload, expiresAt: expiresAt);
  }

  @override
  Future<ClinicProvisionResult> createPatientAccount({
    required String doctorId,
    required String clinicId,
    required String doctorName,
    required String clinicName,
    required String displayName,
    required String loginIdentifier,
    required String ageRange,
    required String preferredLanguage,
    String? clinicianLanguage,
    List<String> assignedTrackIds = const [],
    List<String> conditionIds = const [],
    List<String> customConditions = const [],
    String? customTempPin,
    Duration inviteValidity = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final cleanName = displayName.trim();
    final cleanId = ClinicPatientAccount.normalizeIdentifier(loginIdentifier);
    if (cleanName.isEmpty || cleanId.length < 3) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidCredentials,
        'Patient name and phone or username are required.',
      );
    }

    final pin = customTempPin?.trim() ?? _generateTempPin();
    if (pin.length < 4) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.weakPin,
        'Temporary PIN must be at least 4 characters.',
      );
    }

    final accounts = await _loadAccounts();
    final duplicate = accounts.values.any(
      (a) => a.loginIdentifier == cleanId,
    );
    if (duplicate) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.duplicateIdentifier,
        'A patient account already uses this phone number or username.',
      );
    }

    final timestamp = now ?? DateTime.now();
    final patientId =
        'pat_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';

    final cleanConditionIds = <String>[];
    final derivedTracks = <String>{...assignedTrackIds};
    final documentedDiagnoses = <ClinicianDiagnosisEntry>[];
    final seenDiagnosisLabels = <String>{};
    final doctorStrings = AppStrings(clinicianLanguage ?? preferredLanguage);

    for (final rawId in conditionIds) {
      final item = ClinicalConditionCatalog.byId(rawId);
      if (item == null) continue;
      if (!cleanConditionIds.contains(item.id)) {
        cleanConditionIds.add(item.id);
      }
      derivedTracks.add(item.track.id);
      final label = item.localized(doctorStrings).trim();
      final key = label.toLowerCase();
      if (label.isNotEmpty && seenDiagnosisLabels.add(key)) {
        documentedDiagnoses.add(
          ClinicianDiagnosisEntry(
            id: 'dx_${timestamp.millisecondsSinceEpoch}_${documentedDiagnoses.length}',
            label: label,
            certainty: DiagnosisCertainty.working,
            status: DiagnosisStatus.active,
            documentedAt: timestamp,
            documentedByDoctorName: doctorName,
          ),
        );
      }
    }

    for (final rawCustom in customConditions) {
      final trimmed = rawCustom.trim();
      final key = trimmed.toLowerCase();
      if (trimmed.isEmpty || !seenDiagnosisLabels.add(key)) continue;
      documentedDiagnoses.add(
        ClinicianDiagnosisEntry(
          id: 'dx_${timestamp.millisecondsSinceEpoch}_${documentedDiagnoses.length}',
          label: trimmed,
          certainty: DiagnosisCertainty.working,
          status: DiagnosisStatus.active,
          documentedAt: timestamp,
          documentedByDoctorName: doctorName,
        ),
      );
    }

    final effectiveTracks = derivedTracks.toList(growable: false);
    final phoneField = RegExp(r'^[\d+\-().\s]{6,}$').hasMatch(loginIdentifier.trim())
        ? loginIdentifier.trim()
        : '';
    final initialClinicalRecord = (documentedDiagnoses.isNotEmpty || phoneField.isNotEmpty)
        ? ClinicianClinicalRecord(
            phone: phoneField,
            diagnoses: documentedDiagnoses,
            updatedAt: timestamp,
          )
        : const ClinicianClinicalRecord();

    final account = ClinicPatientAccount(
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      doctorName: doctorName,
      clinicName: clinicName,
      displayName: cleanName,
      loginIdentifier: cleanId,
      ageRange: ageRange,
      preferredLanguage: preferredLanguage,
      assignedTrackIds: effectiveTracks,
      assignedConditionIds: cleanConditionIds,
      credentialHash: AuthService.hashPassword(pin),
      requiresPinChange: true,
      status: ClinicAccountStatus.pendingFirstLogin,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    accounts[patientId] = account;
    await _saveAccounts(accounts);

    final issued = _issueInviteToken(
      account: account,
      validity: inviteValidity,
      timestamp: timestamp,
    );
    final tokens = await _loadTokens();
    tokens[issued.tokenRecord.tokenId] = issued.tokenRecord;
    await _saveTokens(tokens);

    // Seed an empty patient record inside the doctor's encrypted roster snapshot
    final doctorPackets = await _loadDoctorPackets();
    final docRoster = doctorPackets.putIfAbsent(doctorId, () => {});
    final emptyPacket = _syncService.buildPatientPacket(
      patientDisplayName: cleanName,
      patientAnonymousId: patientId,
      consentScope: const ClinicalConsentScope(
        windowDays: 90,
        includeMoodMetrics: true,
        includeSleepEnergyAnxiety: true,
        includePersonalNotes: true,
        includeSharedCases: true,
        includeSymptomReports: true,
        includePsychologicalProfile: true,
        includePreVisitAgenda: false,
      ),
      traces: const [],
      cases: const [],
      symptomReports: const [],
      referenceNow: timestamp,
    );
    docRoster[patientId] = ClinicianPatientRecord(
      patientId: patientId,
      displayName: cleanName,
      isDemoCase: false,
      importedAt: timestamp,
      lastSyncedAt: timestamp,
      latestPacket: emptyPacket,
      clinicalRecord: initialClinicalRecord,
      reviewedAt: timestamp,
    );
    await _saveDoctorPackets(doctorPackets);

    // Seed assigned care tracks into patient inbox
    final inboxes = await _loadInboxes();
    inboxes[patientId] = ClinicPatientSyncInbox(
      patientId: patientId,
      assignedTrackIds: effectiveTracks,
      updatedAt: timestamp,
    );
    await _saveInboxes(inboxes);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: clinicId,
        doctorId: doctorId,
        patientId: patientId,
        action: ClinicAuditAction.createdAccount,
        actorRole: 'clinician',
        timestamp: timestamp,
      ),
    );

    return ClinicProvisionResult(
      account: account,
      temporaryPin: pin,
      qrPayload: issued.qrPayload,
      expiresAt: issued.expiresAt,
    );
  }

  @override
  Future<ClinicPatientAccount> signInWithCredentials({
    required String identifier,
    required String pinOrPassword,
    DateTime? now,
  }) async {
    final normalizedId = ClinicPatientAccount.normalizeIdentifier(identifier);
    final cleanPin = pinOrPassword.trim();
    if (normalizedId.isEmpty || cleanPin.isEmpty) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidCredentials,
        'Enter both your login ID and PIN.',
      );
    }

    final accounts = await _loadAccounts();
    final matches = accounts.values.where(
      (a) => a.loginIdentifier == normalizedId,
    );
    if (matches.isEmpty) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidCredentials,
        'Incorrect login ID or PIN.',
      );
    }
    final account = matches.first;
    if (account.isPaused) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountPaused,
        'This account is paused. Please contact your clinic.',
      );
    }

    final verified = AuthService.verifyPasswordWithMigration(
      cleanPin,
      account.credentialHash,
    );
    if (!verified.isValid) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidCredentials,
        'Incorrect login ID or PIN.',
      );
    }

    final timestamp = now ?? DateTime.now();
    final updated = account.copyWith(
      credentialHash: verified.needsRehash
          ? AuthService.hashPassword(cleanPin)
          : account.credentialHash,
      status: ClinicAccountStatus.active,
      updatedAt: timestamp,
    );
    accounts[updated.patientId] = updated;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: updated.doctorId,
        patientId: updated.patientId,
        action: ClinicAuditAction.patientPinLogin,
        actorRole: 'patient',
        timestamp: timestamp,
      ),
    );

    return updated;
  }

  @override
  Future<ClinicPatientAccount> signInWithInviteQr({
    required String qrPayload,
    DateTime? now,
  }) async {
    final parsed = ClinicInvitePayload.decode(qrPayload);
    final tokens = await _loadTokens();
    final record = tokens[parsed.tokenId];
    final timestamp = now ?? DateTime.now();

    if (record == null ||
        (parsed.patientId.isNotEmpty && record.patientId != parsed.patientId)) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidQrFormat,
        'Invalid invitation QR code.',
      );
    }
    if (record.revoked) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.inviteRevoked,
        'This invitation was replaced by your doctor.',
      );
    }
    if (record.usedAt != null) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.inviteAlreadyUsed,
        'This QR code was already used once.',
      );
    }
    if (!timestamp.isBefore(record.expiresAt)) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.inviteExpired,
        'This QR code has expired. Ask your clinic for a new one.',
      );
    }

    final expectedHash = _hashInviteSecret(parsed.tokenId, parsed.secret);
    if (!AuthService.constantTimeEquals(
      utf8.encode(expectedHash),
      utf8.encode(record.oneTimeSecretHash),
    )) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidQrFormat,
        'Invalid QR invitation signature.',
      );
    }

    final accounts = await _loadAccounts();
    final account = accounts[record.patientId];
    if (account == null) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountNotFound,
        'Patient account no longer exists.',
      );
    }
    if (account.isPaused) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountPaused,
        'This account is paused. Please contact your clinic.',
      );
    }

    // Consume single-use token permanently
    tokens[record.tokenId] = record.copyWith(usedAt: timestamp);
    await _saveTokens(tokens);

    final updatedAccount = account.copyWith(
      status: ClinicAccountStatus.active,
      updatedAt: timestamp,
    );
    accounts[updatedAccount.patientId] = updatedAccount;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updatedAccount.clinicId,
        doctorId: updatedAccount.doctorId,
        patientId: updatedAccount.patientId,
        action: ClinicAuditAction.patientQrLogin,
        actorRole: 'patient',
        timestamp: timestamp,
      ),
    );

    return updatedAccount;
  }

  @override
  Future<ClinicProvisionResult> resetPatientAccess({
    required String doctorId,
    required String patientId,
    String? customTempPin,
    Duration inviteValidity = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final pin = customTempPin?.trim() ?? _generateTempPin();
    if (pin.length < 4) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.weakPin,
        'Temporary PIN must be at least 4 characters.',
      );
    }

    final accounts = await _loadAccounts();
    final account = _assertDoctorOwnsPatient(accounts, doctorId, patientId);
    final timestamp = now ?? DateTime.now();

    // Revoke all unused invite tokens for this patient
    final tokens = await _loadTokens();
    for (final entry in tokens.entries.toList()) {
      if (entry.value.patientId == patientId &&
          entry.value.usedAt == null &&
          !entry.value.revoked) {
        tokens[entry.key] = entry.value.copyWith(revoked: true);
      }
    }

    final issued = _issueInviteToken(
      account: account,
      validity: inviteValidity,
      timestamp: timestamp,
    );
    tokens[issued.tokenRecord.tokenId] = issued.tokenRecord;
    await _saveTokens(tokens);

    final updated = account.copyWith(
      credentialHash: AuthService.hashPassword(pin),
      requiresPinChange: true,
      status: ClinicAccountStatus.pendingFirstLogin,
      updatedAt: timestamp,
    );
    accounts[patientId] = updated;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: doctorId,
        patientId: patientId,
        action: ClinicAuditAction.resetAccess,
        actorRole: 'clinician',
        timestamp: timestamp,
      ),
    );

    return ClinicProvisionResult(
      account: updated,
      temporaryPin: pin,
      qrPayload: issued.qrPayload,
      expiresAt: issued.expiresAt,
    );
  }

  @override
  Future<ClinicPatientAccount> setAccountStatus({
    required String doctorId,
    required String patientId,
    required ClinicAccountStatus status,
  }) async {
    final accounts = await _loadAccounts();
    final account = _assertDoctorOwnsPatient(accounts, doctorId, patientId);
    final timestamp = DateTime.now();
    final updated = account.copyWith(status: status, updatedAt: timestamp);
    accounts[patientId] = updated;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: doctorId,
        patientId: patientId,
        action: status == ClinicAccountStatus.paused
            ? ClinicAuditAction.pausedAccount
            : ClinicAuditAction.resumedAccount,
        actorRole: 'clinician',
        timestamp: timestamp,
      ),
    );
    return updated;
  }

  @override
  Future<ClinicPatientAccount> updateAssignedTracks({
    required String doctorId,
    required String patientId,
    required List<String> trackIds,
  }) async {
    final accounts = await _loadAccounts();
    final account = _assertDoctorOwnsPatient(accounts, doctorId, patientId);
    final timestamp = DateTime.now();
    final updated = account.copyWith(
      assignedTrackIds: List<String>.from(trackIds),
      updatedAt: timestamp,
    );
    accounts[patientId] = updated;
    await _saveAccounts(accounts);

    final inboxes = await _loadInboxes();
    final currentInbox = inboxes[patientId];
    inboxes[patientId] = ClinicPatientSyncInbox(
      patientId: patientId,
      assignedTrackIds: List<String>.from(trackIds),
      activeFocusPlan: currentInbox?.activeFocusPlan,
      updatedAt: timestamp,
    );
    await _saveInboxes(inboxes);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: doctorId,
        patientId: patientId,
        action: ClinicAuditAction.updatedTracks,
        actorRole: 'clinician',
        timestamp: timestamp,
      ),
    );
    return updated;
  }

  @override
  Future<ClinicPatientAccount> changePatientPin({
    required String patientId,
    required String currentPin,
    required String newPin,
    bool skipCurrentPinCheck = false,
  }) async {
    final cleanNew = newPin.trim();
    if (cleanNew.length < 4) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.weakPin,
        'New PIN must be at least 4 characters.',
      );
    }

    final accounts = await _loadAccounts();
    final account = accounts[patientId];
    if (account == null) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountNotFound,
        'Account not found.',
      );
    }
    if (account.isPaused) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountPaused,
        'This account is paused.',
      );
    }

    final allowFirstLoginDirectPin =
        skipCurrentPinCheck &&
        (account.requiresPinChange || !account.hasAcceptedSafetyNotice);

    if (!allowFirstLoginDirectPin) {
      final verified = AuthService.verifyPasswordWithMigration(
        currentPin.trim(),
        account.credentialHash,
      );
      if (!verified.isValid) {
        throw const ClinicAuthException(
          ClinicAuthErrorCode.invalidCredentials,
          'Current PIN is incorrect.',
        );
      }
    }

    final timestamp = DateTime.now();
    final updated = account.copyWith(
      credentialHash: AuthService.hashPassword(cleanNew),
      requiresPinChange: false,
      updatedAt: timestamp,
    );
    accounts[patientId] = updated;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: updated.doctorId,
        patientId: patientId,
        action: ClinicAuditAction.patientPinChanged,
        actorRole: 'patient',
        timestamp: timestamp,
      ),
    );
    return updated;
  }

  @override
  Future<ClinicPatientAccount> markSafetyNoticeAccepted({
    required String patientId,
  }) async {
    final accounts = await _loadAccounts();
    final account = accounts[patientId];
    if (account == null) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountNotFound,
        'Account not found.',
      );
    }
    final timestamp = DateTime.now();
    final updated = account.copyWith(
      acceptedSafetyNoticeAt: account.acceptedSafetyNoticeAt ?? timestamp,
      status: account.isPaused
          ? ClinicAccountStatus.paused
          : ClinicAccountStatus.active,
      updatedAt: timestamp,
    );
    accounts[patientId] = updated;
    await _saveAccounts(accounts);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: updated.clinicId,
        doctorId: updated.doctorId,
        patientId: patientId,
        action: ClinicAuditAction.safetyNoticeAccepted,
        actorRole: 'patient',
        timestamp: timestamp,
      ),
    );
    return updated;
  }

  @override
  Future<ClinicPatientAccount?> getPatientAccount(String patientId) async {
    final accounts = await _loadAccounts();
    return accounts[patientId];
  }

  @override
  Future<List<ClinicPatientAccount>> listPatientsForDoctor(
    String doctorId,
  ) async {
    final accounts = await _loadAccounts();
    return accounts.values
        .where((a) => a.doctorId == doctorId)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ClinicAuditEntry>> listAuditLog({
    String? doctorId,
    String? patientId,
  }) async {
    final all = await _loadAudit();
    return all.where((e) {
      if (doctorId != null && e.doctorId != doctorId) return false;
      if (patientId != null && e.patientId != patientId) return false;
      return true;
    }).toList(growable: false);
  }

  @override
  Future<ClinicianSyncPacket?> syncPatientSnapshot({
    required String patientId,
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<SymptomReport> symptomReports,
    PsychologicalProfileModel? profile,
    DateTime? now,
  }) async {
    final accounts = await _loadAccounts();
    final account = accounts[patientId];
    if (account == null) return null;
    if (account.isPaused) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.accountPaused,
        'Sync blocked: patient account is paused by clinic.',
      );
    }

    final timestamp = now ?? DateTime.now();

    // Everything not explicitly locked with `isPrivate: true` syncs automatically.
    // `ClinicianSyncService.buildPatientPacket` hard-excludes all `t.isPrivate`
    // and `c.isPrivate` entries before building the doctor packet.
    final packet = _syncService.buildPatientPacket(
      patientDisplayName: account.displayName,
      patientAnonymousId: account.patientId,
      consentScope: const ClinicalConsentScope(
        windowDays: 90,
        includeMoodMetrics: true,
        includeSleepEnergyAnxiety: true,
        includePersonalNotes: true,
        includeSharedCases: true,
        includeSymptomReports: true,
        includePsychologicalProfile: true,
        includePreVisitAgenda: false,
      ),
      traces: traces,
      cases: cases,
      symptomReports: symptomReports,
      profile: profile,
      referenceNow: timestamp,
    );

    final doctorPackets = await _loadDoctorPackets();
    final docRoster = doctorPackets.putIfAbsent(account.doctorId, () => {});
    final existing = docRoster[patientId];
    final previousPackets = existing != null
        ? [existing.latestPacket, ...existing.previousPackets]
            .take(5)
            .toList(growable: false)
        : const <ClinicianSyncPacket>[];

    docRoster[patientId] = ClinicianPatientRecord(
      patientId: patientId,
      displayName: account.displayName,
      isDemoCase: false,
      importedAt: existing?.importedAt ?? timestamp,
      lastSyncedAt: timestamp,
      latestPacket: packet,
      previousPackets: previousPackets,
      clinicianNotes: existing?.clinicianNotes ?? const [],
      clinicalRecord:
          existing?.clinicalRecord ?? const ClinicianClinicalRecord(),
      reviewedAt: null,
    );
    await _saveDoctorPackets(doctorPackets);

    accounts[patientId] = account.copyWith(lastSyncAt: timestamp);
    await _saveAccounts(accounts);

    return packet;
  }

  @override
  Future<void> pushFocusPlanToPatient({
    required String doctorId,
    required String patientId,
    required PostVisitFocusPlan plan,
  }) async {
    final accounts = await _loadAccounts();
    final account = _assertDoctorOwnsPatient(accounts, doctorId, patientId);
    final timestamp = DateTime.now();

    final inboxes = await _loadInboxes();
    final existing = inboxes[patientId];
    inboxes[patientId] = ClinicPatientSyncInbox(
      patientId: patientId,
      assignedTrackIds:
          existing?.assignedTrackIds ?? account.assignedTrackIds,
      activeFocusPlan: plan.copyWith(isDismissed: false),
      updatedAt: timestamp,
    );
    await _saveInboxes(inboxes);

    await _appendAudit(
      ClinicAuditEntry(
        id: _uuid.v4(),
        clinicId: account.clinicId,
        doctorId: doctorId,
        patientId: patientId,
        action: ClinicAuditAction.pushedFocusPlan,
        actorRole: 'clinician',
        timestamp: timestamp,
      ),
    );
  }

  @override
  Future<ClinicPatientSyncInbox?> pullPatientInbox(String patientId) async {
    final accounts = await _loadAccounts();
    final account = accounts[patientId];
    if (account == null || account.isPaused) return null;
    final inboxes = await _loadInboxes();
    return inboxes[patientId];
  }

  @override
  Future<List<ClinicianPatientRecord>> listSyncedPatientsForDoctor(
    String doctorId,
  ) async {
    final doctorPackets = await _loadDoctorPackets();
    final docRoster = doctorPackets[doctorId];
    if (docRoster == null || docRoster.isEmpty) return const [];
    return docRoster.values.toList(growable: false)
      ..sort((a, b) => b.lastSyncedAt.compareTo(a.lastSyncedAt));
  }
}
