import 'dart:convert';

import '../../clinician/domain/clinician_models.dart';
import '../../clinician/domain/post_visit_focus_model.dart';

/// Account lifecycle status managed by the Clinic Admin (Doctor).
enum ClinicAccountStatus {
  active,
  paused,
  pendingFirstLogin;

  static ClinicAccountStatus fromString(String? raw) {
    return ClinicAccountStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ClinicAccountStatus.active,
    );
  }
}

/// Specific clinic authentication and synchronization failure codes.
enum ClinicAuthErrorCode {
  invalidCredentials,
  accountPaused,
  inviteExpired,
  inviteAlreadyUsed,
  inviteRevoked,
  invalidQrFormat,
  duplicateIdentifier,
  weakPin,
  accountNotFound,
}

/// Typed exception thrown by [ClinicAuthRepository] operations.
class ClinicAuthException implements Exception {
  const ClinicAuthException(this.code, this.message);

  final ClinicAuthErrorCode code;
  final String message;

  @override
  String toString() => 'ClinicAuthException(${code.name}): $message';
}

/// Patient account record created and administered by a clinic psychiatrist.
///
/// Passwords/PINs are NEVER persisted in plaintext — only [credentialHash]
/// (PBKDF2-HMAC-SHA256) is stored.
class ClinicPatientAccount {
  const ClinicPatientAccount({
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    required this.doctorName,
    required this.clinicName,
    required this.displayName,
    required this.loginIdentifier,
    this.ageRange = '25-44',
    this.preferredLanguage = 'en',
    this.assignedTrackIds = const [],
    this.assignedConditionIds = const [],
    required this.credentialHash,
    this.requiresPinChange = true,
    this.status = ClinicAccountStatus.pendingFirstLogin,
    this.acceptedSafetyNoticeAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  final String patientId;
  final String doctorId;
  final String clinicId;
  final String doctorName;
  final String clinicName;
  final String displayName;
  final String loginIdentifier;
  final String ageRange;
  final String preferredLanguage;
  final List<String> assignedTrackIds;
  final List<String> assignedConditionIds;
  final String credentialHash;
  final bool requiresPinChange;
  final ClinicAccountStatus status;
  final DateTime? acceptedSafetyNoticeAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  bool get isPaused => status == ClinicAccountStatus.paused;
  bool get hasAcceptedSafetyNotice => acceptedSafetyNoticeAt != null;

  /// Normalizes a phone number or username so cosmetic spacing never breaks login.
  static String normalizeIdentifier(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (RegExp(r'^[\d\s+\-().]+$').hasMatch(trimmed)) {
      return trimmed.replaceAll(RegExp(r'[\s\-().]'), '');
    }
    return trimmed.toLowerCase();
  }

  ClinicPatientAccount copyWith({
    String? patientId,
    String? doctorId,
    String? clinicId,
    String? doctorName,
    String? clinicName,
    String? displayName,
    String? loginIdentifier,
    String? ageRange,
    String? preferredLanguage,
    List<String>? assignedTrackIds,
    List<String>? assignedConditionIds,
    String? credentialHash,
    bool? requiresPinChange,
    ClinicAccountStatus? status,
    DateTime? acceptedSafetyNoticeAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return ClinicPatientAccount(
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      clinicId: clinicId ?? this.clinicId,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      displayName: displayName ?? this.displayName,
      loginIdentifier: loginIdentifier ?? this.loginIdentifier,
      ageRange: ageRange ?? this.ageRange,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      assignedTrackIds: assignedTrackIds ?? this.assignedTrackIds,
      assignedConditionIds: assignedConditionIds ?? this.assignedConditionIds,
      credentialHash: credentialHash ?? this.credentialHash,
      requiresPinChange: requiresPinChange ?? this.requiresPinChange,
      status: status ?? this.status,
      acceptedSafetyNoticeAt:
          acceptedSafetyNoticeAt ?? this.acceptedSafetyNoticeAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'doctorId': doctorId,
        'clinicId': clinicId,
        'doctorName': doctorName,
        'clinicName': clinicName,
        'displayName': displayName,
        'loginIdentifier': loginIdentifier,
        'ageRange': ageRange,
        'preferredLanguage': preferredLanguage,
        'assignedTrackIds': assignedTrackIds,
        'assignedConditionIds': assignedConditionIds,
        'credentialHash': credentialHash,
        'requiresPinChange': requiresPinChange,
        'status': status.name,
        'acceptedSafetyNoticeAt': acceptedSafetyNoticeAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory ClinicPatientAccount.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ClinicPatientAccount(
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      clinicId: json['clinicId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? 'Dr. Salma Ben Amor',
      clinicName: json['clinicName'] as String? ?? 'Tunis Mindora Practice',
      displayName: json['displayName'] as String? ?? '',
      loginIdentifier: json['loginIdentifier'] as String? ?? '',
      ageRange: json['ageRange'] as String? ?? '25-44',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      assignedTrackIds: (json['assignedTrackIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      assignedConditionIds: (json['assignedConditionIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      credentialHash: json['credentialHash'] as String? ?? '',
      requiresPinChange: json['requiresPinChange'] as bool? ?? true,
      status: ClinicAccountStatus.fromString(json['status'] as String?),
      acceptedSafetyNoticeAt: json['acceptedSafetyNoticeAt'] != null
          ? DateTime.tryParse(json['acceptedSafetyNoticeAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'] as String)
          : null,
    );
  }
}

/// Decoded contents of an ephemeral single-use QR invitation scanned in-clinic.
///
/// Format v2 (current): encodes ONLY an opaque `{v: 2, t: tokenId, s: secret}`
/// pair — **zero personal data** (no name, phone, clinic, or patientId) travels
/// inside the QR matrix, producing a compact, highly scannable Version 3–4 QR.
/// Format v1 remains supported by [decode] for backward compatibility.
class ClinicInvitePayload {
  const ClinicInvitePayload({
    required this.tokenId,
    this.patientId = '',
    this.doctorId = '',
    this.clinicId = '',
    this.doctorName = '',
    this.clinicName = '',
    this.patientDisplayName = '',
    this.loginIdentifier = '',
    required this.secret,
    this.expiresAt,
  });

  static const String qrPrefix = 'MF-INVITE-V1:';

  final String tokenId;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final String doctorName;
  final String clinicName;
  final String patientDisplayName;
  final String loginIdentifier;
  final String secret;
  final DateTime? expiresAt;

  /// Encodes a zero-PII opaque invite token (`v: 2`).
  String encode() {
    final map = <String, dynamic>{
      'v': 2,
      't': tokenId,
      's': secret,
    };
    return '$qrPrefix${base64Url.encode(utf8.encode(jsonEncode(map)))}';
  }

  static ClinicInvitePayload decode(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (!trimmed.startsWith(qrPrefix)) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidQrFormat,
        'Unrecognized Mindora clinic QR code.',
      );
    }
    final encoded = trimmed.substring(qrPrefix.length).trim();
    try {
      final decodedMap =
          jsonDecode(utf8.decode(base64Url.decode(encoded)))
              as Map<String, dynamic>;
      final version = (decodedMap['v'] as num?)?.toInt() ?? 1;
      if (version >= 2) {
        final tokenId = (decodedMap['t'] as String? ?? '').trim();
        final secret = (decodedMap['s'] as String? ?? '').trim();
        if (tokenId.isEmpty || secret.isEmpty) {
          throw const FormatException('Missing required v2 QR fields');
        }
        return ClinicInvitePayload(tokenId: tokenId, secret: secret);
      }

      // Legacy v1 backward-compatible decode
      final tokenId = decodedMap['tokenId'] as String? ?? '';
      final patientId = decodedMap['patientId'] as String? ?? '';
      final secret = decodedMap['secret'] as String? ?? '';
      final expiresAt = DateTime.tryParse(
        decodedMap['expiresAt'] as String? ?? '',
      );
      if (tokenId.isEmpty ||
          patientId.isEmpty ||
          secret.isEmpty ||
          expiresAt == null) {
        throw const FormatException('Missing required QR fields');
      }
      return ClinicInvitePayload(
        tokenId: tokenId,
        patientId: patientId,
        doctorId: decodedMap['doctorId'] as String? ?? '',
        clinicId: decodedMap['clinicId'] as String? ?? '',
        doctorName: decodedMap['doctorName'] as String? ?? '',
        clinicName: decodedMap['clinicName'] as String? ?? '',
        patientDisplayName: decodedMap['patientDisplayName'] as String? ?? '',
        loginIdentifier: decodedMap['loginIdentifier'] as String? ?? '',
        secret: secret,
        expiresAt: expiresAt,
      );
    } catch (_) {
      throw const ClinicAuthException(
        ClinicAuthErrorCode.invalidQrFormat,
        'Corrupted Mindora clinic QR code.',
      );
    }
  }
}

/// Persisted server-side metadata for an issued QR invitation (never stores secret).
class ClinicInviteTokenRecord {
  const ClinicInviteTokenRecord({
    required this.tokenId,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    required this.oneTimeSecretHash,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.revoked = false,
  });

  final String tokenId;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final String oneTimeSecretHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final bool revoked;

  ClinicInviteTokenRecord copyWith({DateTime? usedAt, bool? revoked}) {
    return ClinicInviteTokenRecord(
      tokenId: tokenId,
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      oneTimeSecretHash: oneTimeSecretHash,
      createdAt: createdAt,
      expiresAt: expiresAt,
      usedAt: usedAt ?? this.usedAt,
      revoked: revoked ?? this.revoked,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'patientId': patientId,
        'doctorId': doctorId,
        'clinicId': clinicId,
        'oneTimeSecretHash': oneTimeSecretHash,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'usedAt': usedAt?.toIso8601String(),
        'revoked': revoked,
      };

  factory ClinicInviteTokenRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ClinicInviteTokenRecord(
      tokenId: json['tokenId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      clinicId: json['clinicId'] as String? ?? '',
      oneTimeSecretHash: json['oneTimeSecretHash'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? now,
      usedAt: json['usedAt'] != null
          ? DateTime.tryParse(json['usedAt'] as String)
          : null,
      revoked: json['revoked'] as bool? ?? false,
    );
  }
}

/// Returned once to the Doctor right after creating or resetting a patient account.
class ClinicProvisionResult {
  const ClinicProvisionResult({
    required this.account,
    required this.temporaryPin,
    required this.qrPayload,
    required this.expiresAt,
  });

  final ClinicPatientAccount account;
  final String temporaryPin;
  final String qrPayload;
  final DateTime expiresAt;
}

/// Audited administrative & access events across a clinic tenant.
enum ClinicAuditAction {
  createdAccount,
  resetAccess,
  pausedAccount,
  resumedAccount,
  updatedTracks,
  pushedFocusPlan,
  patientQrLogin,
  patientPinLogin,
  patientPinChanged,
  safetyNoticeAccepted,
}

class ClinicAuditEntry {
  const ClinicAuditEntry({
    required this.id,
    required this.clinicId,
    required this.doctorId,
    required this.patientId,
    required this.action,
    required this.actorRole,
    required this.timestamp,
  });

  final String id;
  final String clinicId;
  final String doctorId;
  final String patientId;
  final ClinicAuditAction action;
  final String actorRole;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinicId': clinicId,
        'doctorId': doctorId,
        'patientId': patientId,
        'action': action.name,
        'actorRole': actorRole,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ClinicAuditEntry.fromJson(Map<String, dynamic> json) {
    return ClinicAuditEntry(
      id: json['id'] as String? ?? '',
      clinicId: json['clinicId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      action: ClinicAuditAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => ClinicAuditAction.createdAccount,
      ),
      actorRole: json['actorRole'] as String? ?? 'clinician',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Live UI sync state exposed quietly in the Patient app.
enum ClinicSyncPhase { idle, savedOffline, syncing, synced, pausedOrError }

class ClinicSyncStatus {
  const ClinicSyncStatus({
    this.phase = ClinicSyncPhase.idle,
    this.lastSyncedAt,
    this.errorMessage,
  });

  final ClinicSyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  ClinicSyncStatus copyWith({
    ClinicSyncPhase? phase,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClinicSyncStatus(
      phase: phase ?? this.phase,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Container for doctor-to-patient auto-delivered items (tracks + focus plan).
class ClinicPatientSyncInbox {
  const ClinicPatientSyncInbox({
    required this.patientId,
    required this.assignedTrackIds,
    this.activeFocusPlan,
    this.updatedAt,
  });

  final String patientId;
  final List<String> assignedTrackIds;
  final PostVisitFocusPlan? activeFocusPlan;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'assignedTrackIds': assignedTrackIds,
        'activeFocusPlan': activeFocusPlan?.toJson(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ClinicPatientSyncInbox.fromJson(Map<String, dynamic> json) {
    return ClinicPatientSyncInbox(
      patientId: json['patientId'] as String? ?? '',
      assignedTrackIds: (json['assignedTrackIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      activeFocusPlan: json['activeFocusPlan'] != null
          ? PostVisitFocusPlan.fromJson(
              json['activeFocusPlan'] as Map<String, dynamic>,
            )
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Per-doctor encrypted snapshot carrier stored in the simulator/sync layer.
class ClinicDoctorRosterSnapshot {
  const ClinicDoctorRosterSnapshot({
    required this.doctorId,
    required this.recordsByPatient,
  });

  final String doctorId;
  final Map<String, ClinicianPatientRecord> recordsByPatient;
}
