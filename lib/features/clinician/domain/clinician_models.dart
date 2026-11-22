import '../../../app/localization/app_strings.dart';
import '../../insights/data/pattern_awareness_service.dart';
import '../../insights/domain/pattern_divergence_model.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Active workspace mode for the two-sided Mind Forensics platform.
enum AppWorkspaceRole {
  patient,
  clinician;

  static AppWorkspaceRole fromString(String? raw) {
    return raw == 'clinician'
        ? AppWorkspaceRole.clinician
        : AppWorkspaceRole.patient;
  }
}

/// SOAP-lite categorization for private clinician consultation notes.
enum ClinicianNoteCategory {
  subjective,
  objective,
  assessment,
  plan,
  general;

  String get shortCode {
    switch (this) {
      case ClinicianNoteCategory.subjective:
        return 'S';
      case ClinicianNoteCategory.objective:
        return 'O';
      case ClinicianNoteCategory.assessment:
        return 'A';
      case ClinicianNoteCategory.plan:
        return 'P';
      case ClinicianNoteCategory.general:
        return 'G';
    }
  }

  String localizedLabel(AppStrings strings) {
    if (strings.isArabic) {
      switch (this) {
        case ClinicianNoteCategory.subjective:
          return 'معطى ذاتي (S)';
        case ClinicianNoteCategory.objective:
          return 'ملاحظة موضوعية (O)';
        case ClinicianNoteCategory.assessment:
          return 'تقييم سريري (A)';
        case ClinicianNoteCategory.plan:
          return 'متابعة / خطة (P)';
        case ClinicianNoteCategory.general:
          return 'ملاحظة عامة';
      }
    }
    if (strings.isFrench) {
      switch (this) {
        case ClinicianNoteCategory.subjective:
          return 'Subjectif (S)';
        case ClinicianNoteCategory.objective:
          return 'Objectif (O)';
        case ClinicianNoteCategory.assessment:
          return 'Évaluation (A)';
        case ClinicianNoteCategory.plan:
          return 'Suivi / Plan (P)';
        case ClinicianNoteCategory.general:
          return 'Général';
      }
    }
    switch (this) {
      case ClinicianNoteCategory.subjective:
        return 'Subjective (S)';
      case ClinicianNoteCategory.objective:
        return 'Objective (O)';
      case ClinicianNoteCategory.assessment:
        return 'Assessment (A)';
      case ClinicianNoteCategory.plan:
        return 'Plan (P)';
      case ClinicianNoteCategory.general:
        return 'General';
    }
  }

  static ClinicianNoteCategory fromString(String? raw) {
    return ClinicianNoteCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => ClinicianNoteCategory.general,
    );
  }
}

/// Granular patient consent contract governing what enters a clinical sync packet.
class ClinicalConsentScope {
  const ClinicalConsentScope({
    this.windowDays = 30,
    this.includeMoodMetrics = true,
    this.includeSleepEnergyAnxiety = true,
    this.includePersonalNotes = false,
    this.includeSharedCases = true,
    this.includeSymptomReports = true,
    this.includePsychologicalProfile = false,
    this.includePreVisitAgenda = true,
  });

  final int windowDays;
  final bool includeMoodMetrics;
  final bool includeSleepEnergyAnxiety;
  final bool includePersonalNotes;
  final bool includeSharedCases;
  final bool includeSymptomReports;
  final bool includePsychologicalProfile;
  final bool includePreVisitAgenda;

  ClinicalConsentScope copyWith({
    int? windowDays,
    bool? includeMoodMetrics,
    bool? includeSleepEnergyAnxiety,
    bool? includePersonalNotes,
    bool? includeSharedCases,
    bool? includeSymptomReports,
    bool? includePsychologicalProfile,
    bool? includePreVisitAgenda,
  }) {
    return ClinicalConsentScope(
      windowDays: windowDays ?? this.windowDays,
      includeMoodMetrics: includeMoodMetrics ?? this.includeMoodMetrics,
      includeSleepEnergyAnxiety:
          includeSleepEnergyAnxiety ?? this.includeSleepEnergyAnxiety,
      includePersonalNotes: includePersonalNotes ?? this.includePersonalNotes,
      includeSharedCases: includeSharedCases ?? this.includeSharedCases,
      includeSymptomReports:
          includeSymptomReports ?? this.includeSymptomReports,
      includePsychologicalProfile:
          includePsychologicalProfile ?? this.includePsychologicalProfile,
      includePreVisitAgenda:
          includePreVisitAgenda ?? this.includePreVisitAgenda,
    );
  }

  Map<String, dynamic> toJson() => {
        'windowDays': windowDays,
        'includeMoodMetrics': includeMoodMetrics,
        'includeSleepEnergyAnxiety': includeSleepEnergyAnxiety,
        'includePersonalNotes': includePersonalNotes,
        'includeSharedCases': includeSharedCases,
        'includeSymptomReports': includeSymptomReports,
        'includePsychologicalProfile': includePsychologicalProfile,
        'includePreVisitAgenda': includePreVisitAgenda,
      };

  factory ClinicalConsentScope.fromJson(Map<String, dynamic> json) {
    return ClinicalConsentScope(
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 30,
      includeMoodMetrics: json['includeMoodMetrics'] as bool? ?? true,
      includeSleepEnergyAnxiety:
          json['includeSleepEnergyAnxiety'] as bool? ?? true,
      includePersonalNotes: json['includePersonalNotes'] as bool? ?? false,
      includeSharedCases: json['includeSharedCases'] as bool? ?? true,
      includeSymptomReports: json['includeSymptomReports'] as bool? ?? true,
      includePsychologicalProfile:
          json['includePsychologicalProfile'] as bool? ?? false,
      includePreVisitAgenda: json['includePreVisitAgenda'] as bool? ?? true,
    );
  }
}

/// Optional options-first patient pre-visit preparation attached to a sync packet.
class PreVisitAgenda {
  const PreVisitAgenda({
    this.selectedTopics = const [],
    this.patientQuestion = '',
    this.whatHelpedRecently = '',
    required this.updatedAt,
  });

  final List<String> selectedTopics;
  final String patientQuestion;
  final String whatHelpedRecently;
  final DateTime updatedAt;

  bool get isEmpty =>
      selectedTopics.isEmpty &&
      patientQuestion.trim().isEmpty &&
      whatHelpedRecently.trim().isEmpty;

  PreVisitAgenda copyWith({
    List<String>? selectedTopics,
    String? patientQuestion,
    String? whatHelpedRecently,
    DateTime? updatedAt,
  }) {
    return PreVisitAgenda(
      selectedTopics: selectedTopics ?? this.selectedTopics,
      patientQuestion: patientQuestion ?? this.patientQuestion,
      whatHelpedRecently: whatHelpedRecently ?? this.whatHelpedRecently,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedTopics': selectedTopics,
        'patientQuestion': patientQuestion,
        'whatHelpedRecently': whatHelpedRecently,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PreVisitAgenda.fromJson(Map<String, dynamic> json) {
    return PreVisitAgenda(
      selectedTopics: (json['selectedTopics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      patientQuestion: json['patientQuestion'] as String? ?? '',
      whatHelpedRecently: json['whatHelpedRecently'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Versioned, consent-scoped handoff bundle sent from patient to psychiatrist.
///
/// Hard Privacy Rule: `isPrivate == true` cases are stripped both on construction
/// and defensively inside [ClinicianSyncPacket.fromJson].
class ClinicianSyncPacket {
  const ClinicianSyncPacket({
    this.schemaVersion = 1,
    required this.packetId,
    required this.generatedAt,
    required this.patientDisplayName,
    required this.patientAnonymousId,
    required this.consentScope,
    this.traces = const [],
    this.sharedCases = const [],
    this.symptomReports = const [],
    this.profileSnapshot,
    this.preVisitAgenda,
    this.integrityHash = '',
  });

  final int schemaVersion;
  final String packetId;
  final DateTime generatedAt;
  final String patientDisplayName;
  final String patientAnonymousId;
  final ClinicalConsentScope consentScope;
  final List<MindTraceModel> traces;
  final List<CaseModel> sharedCases;
  final List<SymptomReport> symptomReports;
  final PsychologicalProfileModel? profileSnapshot;
  final PreVisitAgenda? preVisitAgenda;
  final String integrityHash;

  ClinicianSyncPacket copyWith({
    int? schemaVersion,
    String? packetId,
    DateTime? generatedAt,
    String? patientDisplayName,
    String? patientAnonymousId,
    ClinicalConsentScope? consentScope,
    List<MindTraceModel>? traces,
    List<CaseModel>? sharedCases,
    List<SymptomReport>? symptomReports,
    PsychologicalProfileModel? profileSnapshot,
    bool clearProfileSnapshot = false,
    PreVisitAgenda? preVisitAgenda,
    bool clearPreVisitAgenda = false,
    String? integrityHash,
  }) {
    return ClinicianSyncPacket(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      packetId: packetId ?? this.packetId,
      generatedAt: generatedAt ?? this.generatedAt,
      patientDisplayName: patientDisplayName ?? this.patientDisplayName,
      patientAnonymousId: patientAnonymousId ?? this.patientAnonymousId,
      consentScope: consentScope ?? this.consentScope,
      traces: traces ?? this.traces,
      sharedCases: (sharedCases ?? this.sharedCases)
          .where((c) => !c.isPrivate)
          .toList(growable: false),
      symptomReports: symptomReports ?? this.symptomReports,
      profileSnapshot:
          clearProfileSnapshot ? null : (profileSnapshot ?? this.profileSnapshot),
      preVisitAgenda:
          clearPreVisitAgenda ? null : (preVisitAgenda ?? this.preVisitAgenda),
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }

  /// Canonical JSON payload (excluding `integrityHash`) for SHA-256 verification.
  Map<String, dynamic> toCanonicalBodyJson() => {
        'schemaVersion': schemaVersion,
        'packetId': packetId,
        'generatedAt': generatedAt.toIso8601String(),
        'patientDisplayName': patientDisplayName,
        'patientAnonymousId': patientAnonymousId,
        'consentScope': consentScope.toJson(),
        'traces': traces.map((t) => t.toJson()).toList(growable: false),
        'sharedCases': sharedCases
            .where((c) => !c.isPrivate)
            .map((c) => c.toJson())
            .toList(growable: false),
        'symptomReports':
            symptomReports.map((r) => r.toJson()).toList(growable: false),
        'profileSnapshot': profileSnapshot?.toJson(),
        'preVisitAgenda': preVisitAgenda?.toJson(),
      };

  Map<String, dynamic> toJson() => {
        ...toCanonicalBodyJson(),
        'integrityHash': integrityHash,
      };

  factory ClinicianSyncPacket.fromJson(Map<String, dynamic> json) {
    final scope = json['consentScope'] is Map<String, dynamic>
        ? ClinicalConsentScope.fromJson(
            json['consentScope'] as Map<String, dynamic>,
          )
        : const ClinicalConsentScope();

    final parsedTraces = scope.includeMoodMetrics
        ? ((json['traces'] as List<dynamic>?) ?? const [])
            .map((e) => MindTraceModel.fromJson(e as Map<String, dynamic>))
            .map((t) {
              var cleaned = t;
              if (!scope.includePersonalNotes) {
                cleaned = cleaned.copyWith(
                  clearJournalText: true,
                  clearSituation: true,
                  clearBehavioralResponse: true,
                  clearAiReflection: true,
                  clearVoiceNotePath: true,
                  dynamicAnswers: const {},
                  investigationAnswers: const {},
                  clearSymptomsAndExperiences: !scope.includeSymptomReports,
                );
              }
              if (!scope.includeSleepEnergyAnxiety) {
                cleaned = cleaned.copyWith(
                  clearSleepHours: true,
                  clearSleepQuality: true,
                  clearEnergyLevel: true,
                  clearAnxietyLevel: true,
                  clearPhysicalTension: true,
                  contextTags: const [],
                );
              }
              return cleaned;
            })
            .toList(growable: false)
        : const <MindTraceModel>[];

    // Hard exclusion of any CaseModel marked private, even from altered JSON.
    final parsedCases = scope.includeSharedCases
        ? ((json['sharedCases'] as List<dynamic>?) ?? const [])
            .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
            .where((c) => !c.isPrivate)
            .toList(growable: false)
        : const <CaseModel>[];

    final parsedSymptoms = scope.includeSymptomReports
        ? ((json['symptomReports'] as List<dynamic>?) ?? const [])
            .map((e) => SymptomReport.fromJson(e as Map<String, dynamic>))
            .toList(growable: false)
        : const <SymptomReport>[];

    PsychologicalProfileModel? parsedProfile;
    if (scope.includePsychologicalProfile &&
        json['profileSnapshot'] is Map<String, dynamic>) {
      parsedProfile = PsychologicalProfileModel.fromJson(
        json['profileSnapshot'] as Map<String, dynamic>,
      );
      if (!scope.includePersonalNotes) {
        parsedProfile = parsedProfile.copyWith(
          personalIntroduction: '',
          additionalContext: '',
          personalContext: '',
          notesForAiCompanion: '',
          symptomNotes: '',
          customAiDirectives: '',
        );
      }
    }

    final parsedAgenda = scope.includePreVisitAgenda &&
            json['preVisitAgenda'] is Map<String, dynamic>
        ? PreVisitAgenda.fromJson(
            json['preVisitAgenda'] as Map<String, dynamic>,
          )
        : null;

    return ClinicianSyncPacket(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      packetId: json['packetId'] as String? ?? 'pkt_unknown',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      patientDisplayName:
          json['patientDisplayName'] as String? ?? 'Shared Patient',
      patientAnonymousId:
          json['patientAnonymousId'] as String? ?? 'anon_patient',
      consentScope: scope,
      traces: parsedTraces,
      sharedCases: parsedCases,
      symptomReports: parsedSymptoms,
      profileSnapshot: parsedProfile,
      preVisitAgenda: parsedAgenda,
      integrityHash: json['integrityHash'] as String? ?? '',
    );
  }
}

/// Private consultation note kept exclusively inside the clinician workspace.
class ClinicianSessionNote {
  const ClinicianSessionNote({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.category = ClinicianNoteCategory.general,
    required this.content,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClinicianNoteCategory category;
  final String content;

  ClinicianSessionNote copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClinicianNoteCategory? category,
    String? content,
  }) {
    return ClinicianSessionNote(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'category': category.name,
        'content': content,
      };

  factory ClinicianSessionNote.fromJson(Map<String, dynamic> json) {
    return ClinicianSessionNote(
      id: json['id'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ClinicianNoteCategory.fromString(json['category'] as String?),
      content: json['content'] as String? ?? '',
    );
  }
}

/// Practitioner identity metadata displayed in Practice settings & EHR headers.
class ClinicianProfile {
  const ClinicianProfile({
    this.displayName = 'Dr. Salma Ben Amor',
    this.specialty = 'Psychiatrist',
    this.clinicName = 'Tunis Mind Forensics Practice',
    this.licenseRef = '',
  });

  final String displayName;
  final String specialty;
  final String clinicName;
  final String licenseRef;

  ClinicianProfile copyWith({
    String? displayName,
    String? specialty,
    String? clinicName,
    String? licenseRef,
  }) {
    return ClinicianProfile(
      displayName: displayName ?? this.displayName,
      specialty: specialty ?? this.specialty,
      clinicName: clinicName ?? this.clinicName,
      licenseRef: licenseRef ?? this.licenseRef,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'specialty': specialty,
        'clinicName': clinicName,
        'licenseRef': licenseRef,
      };

  factory ClinicianProfile.fromJson(Map<String, dynamic> json) {
    return ClinicianProfile(
      displayName: json['displayName'] as String? ?? 'Dr. Salma Ben Amor',
      specialty: json['specialty'] as String? ?? 'Psychiatrist',
      clinicName:
          json['clinicName'] as String? ?? 'Tunis Mind Forensics Practice',
      licenseRef: json['licenseRef'] as String? ?? '',
    );
  }
}

/// Stored clinician dossier for a single imported or demo patient.
class ClinicianPatientRecord {
  const ClinicianPatientRecord({
    required this.patientId,
    required this.displayName,
    this.isDemoCase = false,
    required this.importedAt,
    required this.lastSyncedAt,
    required this.latestPacket,
    this.clinicianNotes = const [],
    this.reviewedAt,
  });

  final String patientId;
  final String displayName;
  final bool isDemoCase;
  final DateTime importedAt;
  final DateTime lastSyncedAt;
  final ClinicianSyncPacket latestPacket;
  final List<ClinicianSessionNote> clinicianNotes;
  final DateTime? reviewedAt;

  PersonalBaseline get baseline =>
      PersonalBaseline.fromTraces(latestPacket.traces);

  PersonalBaseline get recentBaseline {
    if (latestPacket.traces.isEmpty) {
      return PersonalBaseline.fromTraces(const []);
    }
    final sorted = List<MindTraceModel>.from(latestPacket.traces)
      ..sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));
    final anchor = sorted.first.date;
    final cutoff = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(const Duration(days: 6));
    final recentTraces = sorted.where((t) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      return !d.isBefore(cutoff);
    }).toList(growable: false);
    return PersonalBaseline.fromTraces(recentTraces);
  }

  List<PatternDivergence> divergences(AppStrings strings) =>
      PatternAwarenessService.detectDivergences(
        traces: latestPacket.traces,
        baseline: baseline,
        strings: strings,
      );

  MindTraceModel? get latestTrace {
    if (latestPacket.traces.isEmpty) return null;
    final sorted = List<MindTraceModel>.from(latestPacket.traces)
      ..sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));
    return sorted.first;
  }

  bool get hasUnreviewedUpdate =>
      reviewedAt == null || lastSyncedAt.isAfter(reviewedAt!);

  ClinicianPatientRecord copyWith({
    String? patientId,
    String? displayName,
    bool? isDemoCase,
    DateTime? importedAt,
    DateTime? lastSyncedAt,
    ClinicianSyncPacket? latestPacket,
    List<ClinicianSessionNote>? clinicianNotes,
    DateTime? reviewedAt,
  }) {
    return ClinicianPatientRecord(
      patientId: patientId ?? this.patientId,
      displayName: displayName ?? this.displayName,
      isDemoCase: isDemoCase ?? this.isDemoCase,
      importedAt: importedAt ?? this.importedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      latestPacket: latestPacket ?? this.latestPacket,
      clinicianNotes: clinicianNotes ?? this.clinicianNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'displayName': displayName,
        'isDemoCase': isDemoCase,
        'importedAt': importedAt.toIso8601String(),
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
        'latestPacket': latestPacket.toJson(),
        'clinicianNotes':
            clinicianNotes.map((n) => n.toJson()).toList(growable: false),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  factory ClinicianPatientRecord.fromJson(Map<String, dynamic> json) {
    final packet = ClinicianSyncPacket.fromJson(
      (json['latestPacket'] as Map<String, dynamic>?) ?? const {},
    );
    return ClinicianPatientRecord(
      patientId: json['patientId'] as String? ?? packet.patientAnonymousId,
      displayName:
          json['displayName'] as String? ?? packet.patientDisplayName,
      isDemoCase: json['isDemoCase'] as bool? ?? false,
      importedAt: json['importedAt'] != null
          ? DateTime.tryParse(json['importedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      latestPacket: packet,
      clinicianNotes: (json['clinicianNotes'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ClinicianSessionNote.fromJson(e as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const [],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
    );
  }
}
