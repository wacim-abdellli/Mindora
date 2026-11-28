import '../../../app/localization/app_strings.dart';

/// Diagnostic certainty strictly documented by the treating clinician.
///
/// Epistemic rule: Never populated by AI reflections or patient self-tags.
enum DiagnosisCertainty {
  confirmed,
  working,
  ruleOut,
  historical;

  String localizedLabel(AppStrings strings) {
    if (strings.isArabic) {
      return switch (this) {
        DiagnosisCertainty.confirmed => 'مؤكّد سريرياً',
        DiagnosisCertainty.working => 'تشخيص أولي',
        DiagnosisCertainty.ruleOut => 'قيد الاستبعاد',
        DiagnosisCertainty.historical => 'سابق / تاريخي',
      };
    }
    if (strings.isFrench) {
      return switch (this) {
        DiagnosisCertainty.confirmed => 'Confirmé',
        DiagnosisCertainty.working => 'Hypothèse de travail',
        DiagnosisCertainty.ruleOut => 'À écarter',
        DiagnosisCertainty.historical => 'Antécédent',
      };
    }
    return switch (this) {
      DiagnosisCertainty.confirmed => 'Confirmed',
      DiagnosisCertainty.working => 'Working',
      DiagnosisCertainty.ruleOut => 'Rule-out',
      DiagnosisCertainty.historical => 'Historical',
    };
  }

  static DiagnosisCertainty fromString(String? raw) {
    return DiagnosisCertainty.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => DiagnosisCertainty.working,
    );
  }
}

/// Lifecycle status of a clinician-documented diagnosis.
enum DiagnosisStatus {
  active,
  inRemission,
  resolved;

  String localizedLabel(AppStrings strings) {
    if (strings.isArabic) {
      return switch (this) {
        DiagnosisStatus.active => 'نشط',
        DiagnosisStatus.inRemission => 'في هدوء / استقرار',
        DiagnosisStatus.resolved => 'منتهي',
      };
    }
    if (strings.isFrench) {
      return switch (this) {
        DiagnosisStatus.active => 'Actif',
        DiagnosisStatus.inRemission => 'En rémission',
        DiagnosisStatus.resolved => 'Résolu',
      };
    }
    return switch (this) {
      DiagnosisStatus.active => 'Active',
      DiagnosisStatus.inRemission => 'In remission',
      DiagnosisStatus.resolved => 'Resolved',
    };
  }

  static DiagnosisStatus fromString(String? raw) {
    return DiagnosisStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => DiagnosisStatus.active,
    );
  }
}

/// Clinician-documented psychiatric or medical diagnosis entry.
class ClinicianDiagnosisEntry {
  const ClinicianDiagnosisEntry({
    required this.id,
    this.code = '',
    required this.label,
    this.certainty = DiagnosisCertainty.working,
    this.status = DiagnosisStatus.active,
    required this.documentedAt,
    this.documentedByDoctorName = '',
    this.clinicalNotes = '',
  });

  final String id;
  final String code;
  final String label;
  final DiagnosisCertainty certainty;
  final DiagnosisStatus status;
  final DateTime documentedAt;
  final String documentedByDoctorName;
  final String clinicalNotes;

  String get displayTitle =>
      code.trim().isNotEmpty ? '${code.trim()} · ${label.trim()}' : label.trim();

  ClinicianDiagnosisEntry copyWith({
    String? id,
    String? code,
    String? label,
    DiagnosisCertainty? certainty,
    DiagnosisStatus? status,
    DateTime? documentedAt,
    String? documentedByDoctorName,
    String? clinicalNotes,
  }) {
    return ClinicianDiagnosisEntry(
      id: id ?? this.id,
      code: code ?? this.code,
      label: label ?? this.label,
      certainty: certainty ?? this.certainty,
      status: status ?? this.status,
      documentedAt: documentedAt ?? this.documentedAt,
      documentedByDoctorName:
          documentedByDoctorName ?? this.documentedByDoctorName,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
        'certainty': certainty.name,
        'status': status.name,
        'documentedAt': documentedAt.toIso8601String(),
        'documentedByDoctorName': documentedByDoctorName,
        'clinicalNotes': clinicalNotes,
      };

  factory ClinicianDiagnosisEntry.fromJson(Map<String, dynamic> json) {
    return ClinicianDiagnosisEntry(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      certainty: DiagnosisCertainty.fromString(json['certainty'] as String?),
      status: DiagnosisStatus.fromString(json['status'] as String?),
      documentedAt: json['documentedAt'] != null
          ? DateTime.tryParse(json['documentedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      documentedByDoctorName: json['documentedByDoctorName'] as String? ?? '',
      clinicalNotes: json['clinicalNotes'] as String? ?? '',
    );
  }
}

/// Lifecycle status of a clinician-maintained medication entry.
enum MedicationStatus {
  active,
  tapering,
  stopped;

  String localizedLabel(AppStrings strings) {
    if (strings.isArabic) {
      return switch (this) {
        MedicationStatus.active => 'جاري',
        MedicationStatus.tapering => 'تخفيض تدريجي',
        MedicationStatus.stopped => 'متوقف',
      };
    }
    if (strings.isFrench) {
      return switch (this) {
        MedicationStatus.active => 'En cours',
        MedicationStatus.tapering => 'Diminution progressive',
        MedicationStatus.stopped => 'Arrêté',
      };
    }
    return switch (this) {
      MedicationStatus.active => 'Active',
      MedicationStatus.tapering => 'Tapering',
      MedicationStatus.stopped => 'Stopped',
    };
  }

  static MedicationStatus fromString(String? raw) {
    return MedicationStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MedicationStatus.active,
    );
  }
}

/// Clinician-maintained medication entry inside the doctor's encrypted chart.
class ClinicianMedicationEntry {
  const ClinicianMedicationEntry({
    required this.id,
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.startedAt,
    this.status = MedicationStatus.active,
    this.prescriberNote = '',
  });

  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime? startedAt;
  final MedicationStatus status;
  final String prescriberNote;

  String get regimenSummary {
    final parts = <String>[
      if (dosage.trim().isNotEmpty) dosage.trim(),
      if (frequency.trim().isNotEmpty) frequency.trim(),
    ];
    return parts.join(' · ');
  }

  ClinicianMedicationEntry copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startedAt,
    bool clearStartedAt = false,
    MedicationStatus? status,
    String? prescriberNote,
  }) {
    return ClinicianMedicationEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      status: status ?? this.status,
      prescriberNote: prescriberNote ?? this.prescriberNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'startedAt': startedAt?.toIso8601String(),
        'status': status.name,
        'prescriberNote': prescriberNote,
      };

  factory ClinicianMedicationEntry.fromJson(Map<String, dynamic> json) {
    return ClinicianMedicationEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      status: MedicationStatus.fromString(json['status'] as String?),
      prescriberNote: json['prescriberNote'] as String? ?? '',
    );
  }
}

/// Severity level for a documented allergy or adverse drug reaction.
enum AllergySeverity {
  mild,
  moderate,
  severe;

  String localizedLabel(AppStrings strings) {
    if (strings.isArabic) {
      return switch (this) {
        AllergySeverity.mild => 'خفيفة',
        AllergySeverity.moderate => 'متوسطة',
        AllergySeverity.severe => 'شديدة',
      };
    }
    if (strings.isFrench) {
      return switch (this) {
        AllergySeverity.mild => 'Légère',
        AllergySeverity.moderate => 'Modérée',
        AllergySeverity.severe => 'Sévère',
      };
    }
    return switch (this) {
      AllergySeverity.mild => 'Mild',
      AllergySeverity.moderate => 'Moderate',
      AllergySeverity.severe => 'Severe',
    };
  }

  static AllergySeverity fromString(String? raw) {
    return AllergySeverity.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AllergySeverity.moderate,
    );
  }
}

/// Clinician-documented allergy or adverse reaction entry.
class ClinicianAllergyEntry {
  const ClinicianAllergyEntry({
    required this.id,
    required this.substance,
    this.reaction = '',
    this.severity = AllergySeverity.moderate,
  });

  final String id;
  final String substance;
  final String reaction;
  final AllergySeverity severity;

  ClinicianAllergyEntry copyWith({
    String? id,
    String? substance,
    String? reaction,
    AllergySeverity? severity,
  }) {
    return ClinicianAllergyEntry(
      id: id ?? this.id,
      substance: substance ?? this.substance,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'substance': substance,
        'reaction': reaction,
        'severity': severity.name,
      };

  factory ClinicianAllergyEntry.fromJson(Map<String, dynamic> json) {
    return ClinicianAllergyEntry(
      id: json['id'] as String? ?? '',
      substance: json['substance'] as String? ?? '',
      reaction: json['reaction'] as String? ?? '',
      severity: AllergySeverity.fromString(json['severity'] as String?),
    );
  }
}

/// Strictly clinician-authored chart data stored exclusively in the isolated
/// `clinician_workspace_v1` encrypted partition (NEVER AI-generated and NEVER
/// populated from patient self-reports).
class ClinicianClinicalRecord {
  const ClinicianClinicalRecord({
    this.dateOfBirth,
    this.biologicalSex = '',
    this.phone = '',
    this.clinicFileNumber = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.referralSource = '',
    this.diagnoses = const [],
    this.medications = const [],
    this.allergies = const [],
    this.noKnownAllergies = false,
    this.psychiatricHistory = '',
    this.medicalHistory = '',
    this.familyHistory = '',
    this.safetyObservationNote = '',
    this.nextAppointmentAt,
    this.updatedAt,
  });

  final DateTime? dateOfBirth;
  final String biologicalSex;
  final String phone;
  final String clinicFileNumber;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String referralSource;
  final List<ClinicianDiagnosisEntry> diagnoses;
  final List<ClinicianMedicationEntry> medications;
  final List<ClinicianAllergyEntry> allergies;
  final bool noKnownAllergies;
  final String psychiatricHistory;
  final String medicalHistory;
  final String familyHistory;
  final String safetyObservationNote;
  final DateTime? nextAppointmentAt;
  final DateTime? updatedAt;

  bool get isEmpty =>
      dateOfBirth == null &&
      biologicalSex.trim().isEmpty &&
      phone.trim().isEmpty &&
      clinicFileNumber.trim().isEmpty &&
      emergencyContactName.trim().isEmpty &&
      emergencyContactPhone.trim().isEmpty &&
      referralSource.trim().isEmpty &&
      diagnoses.isEmpty &&
      medications.isEmpty &&
      allergies.isEmpty &&
      !noKnownAllergies &&
      psychiatricHistory.trim().isEmpty &&
      medicalHistory.trim().isEmpty &&
      familyHistory.trim().isEmpty &&
      safetyObservationNote.trim().isEmpty &&
      nextAppointmentAt == null;

  bool get hasHistoryNotes =>
      psychiatricHistory.trim().isNotEmpty ||
      medicalHistory.trim().isNotEmpty ||
      familyHistory.trim().isNotEmpty ||
      safetyObservationNote.trim().isNotEmpty;

  ClinicianClinicalRecord copyWith({
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? biologicalSex,
    String? phone,
    String? clinicFileNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? referralSource,
    List<ClinicianDiagnosisEntry>? diagnoses,
    List<ClinicianMedicationEntry>? medications,
    List<ClinicianAllergyEntry>? allergies,
    bool? noKnownAllergies,
    String? psychiatricHistory,
    String? medicalHistory,
    String? familyHistory,
    String? safetyObservationNote,
    DateTime? nextAppointmentAt,
    bool clearNextAppointmentAt = false,
    DateTime? updatedAt,
  }) {
    return ClinicianClinicalRecord(
      dateOfBirth:
          clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      biologicalSex: biologicalSex ?? this.biologicalSex,
      phone: phone ?? this.phone,
      clinicFileNumber: clinicFileNumber ?? this.clinicFileNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      referralSource: referralSource ?? this.referralSource,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      noKnownAllergies: noKnownAllergies ?? this.noKnownAllergies,
      psychiatricHistory: psychiatricHistory ?? this.psychiatricHistory,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      safetyObservationNote:
          safetyObservationNote ?? this.safetyObservationNote,
      nextAppointmentAt: clearNextAppointmentAt
          ? null
          : (nextAppointmentAt ?? this.nextAppointmentAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'biologicalSex': biologicalSex,
        'phone': phone,
        'clinicFileNumber': clinicFileNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'referralSource': referralSource,
        'diagnoses': diagnoses.map((d) => d.toJson()).toList(growable: false),
        'medications':
            medications.map((m) => m.toJson()).toList(growable: false),
        'allergies': allergies.map((a) => a.toJson()).toList(growable: false),
        'noKnownAllergies': noKnownAllergies,
        'psychiatricHistory': psychiatricHistory,
        'medicalHistory': medicalHistory,
        'familyHistory': familyHistory,
        'safetyObservationNote': safetyObservationNote,
        'nextAppointmentAt': nextAppointmentAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ClinicianClinicalRecord.fromJson(Map<String, dynamic> json) {
    return ClinicianClinicalRecord(
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      biologicalSex: json['biologicalSex'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      clinicFileNumber: json['clinicFileNumber'] as String? ?? '',
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      referralSource: json['referralSource'] as String? ?? '',
      diagnoses: (json['diagnoses'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ClinicianDiagnosisEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const [],
      medications: (json['medications'] as List<dynamic>?)
              ?.map(
                (e) => ClinicianMedicationEntry.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(growable: false) ??
          const [],
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ClinicianAllergyEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const [],
      noKnownAllergies: json['noKnownAllergies'] as bool? ?? false,
      psychiatricHistory: json['psychiatricHistory'] as String? ?? '',
      medicalHistory: json['medicalHistory'] as String? ?? '',
      familyHistory: json['familyHistory'] as String? ?? '',
      safetyObservationNote: json['safetyObservationNote'] as String? ?? '',
      nextAppointmentAt: json['nextAppointmentAt'] != null
          ? DateTime.tryParse(json['nextAppointmentAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
