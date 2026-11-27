import 'dart:convert';

/// The authentication method used to secure the mental vault.
enum AuthType {
  /// Zero-identity footprint, completely local and encrypted on device.
  anonymous,

  /// Remote cloud sync secured with email and password credentials.
  emailPassword,

  /// Local biometric authentication (fingerprint / Face ID).
  biometric,

  /// Clinic-issued patient credentials or single-use doctor QR invite.
  clinicPin,
}

/// The authenticated Mindora user profile.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.codename,
    this.email,
    required this.authType,
    this.clinicId,
    this.doctorId,
    this.doctorName,
    this.clinicName,
    this.loginIdentifier,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Unique immutable identifier for the user.
  final String id;

  /// Display name or private alias.
  final String codename;

  /// Optional email address.
  final String? email;

  /// The primary authentication mechanism.
  final AuthType authType;

  /// Assigned clinic ID when provisioned by a doctor.
  final String? clinicId;

  /// Assigned primary clinician ID.
  final String? doctorId;

  /// Assigned primary clinician display name.
  final String? doctorName;

  /// Assigned clinic display name.
  final String? clinicName;

  /// Normalized phone/username login identifier.
  final String? loginIdentifier;

  /// Timestamp when the account was first established.
  final DateTime createdAt;

  /// Timestamp of the most recent activity.
  final DateTime? lastActiveAt;

  /// Whether this user is connected to a doctor-provisioned clinic account.
  bool get isClinicAccount => clinicId != null && doctorId != null;

  /// Returns true if this is an unlinked local session without cloud identity.
  bool get isAnonymous =>
      (authType == AuthType.anonymous || email == null) && !isClinicAccount;

  AuthUser copyWith({
    String? id,
    String? codename,
    String? email,
    AuthType? authType,
    String? clinicId,
    String? doctorId,
    String? doctorName,
    String? clinicName,
    String? loginIdentifier,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      codename: codename ?? this.codename,
      email: email ?? this.email,
      authType: authType ?? this.authType,
      clinicId: clinicId ?? this.clinicId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      loginIdentifier: loginIdentifier ?? this.loginIdentifier,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codename': codename,
      'email': email,
      'authType': authType.name,
      if (clinicId != null) 'clinicId': clinicId,
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (clinicName != null) 'clinicName': clinicName,
      if (loginIdentifier != null) 'loginIdentifier': loginIdentifier,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] as String,
      codename: map['codename'] as String? ?? 'Forensic Investigator',
      email: map['email'] as String?,
      authType: AuthType.values.firstWhere(
        (e) => e.name == map['authType'],
        orElse: () => AuthType.anonymous,
      ),
      clinicId: map['clinicId'] as String?,
      doctorId: map['doctorId'] as String?,
      doctorName: map['doctorName'] as String?,
      clinicName: map['clinicName'] as String?,
      loginIdentifier: map['loginIdentifier'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);
}

