import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../auth/data/auth_service.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/clinician_models.dart';
import '../domain/post_visit_focus_model.dart';

enum ClinicianSyncErrorCode {
  invalidFormat,
  unsupportedVersion,
  decryptionFailed,
  integrityMismatch,
}

class ClinicianSyncException implements Exception {
  const ClinicianSyncException(this.code, this.message);

  final ClinicianSyncErrorCode code;
  final String message;

  @override
  String toString() => 'ClinicianSyncException(${code.name}): $message';
}

/// Privacy-first Care Handoff Protocol between Patient and Psychiatrist workspaces.
///
/// Enforces:
/// 1. Strict consent scoping (`ClinicalConsentScope`).
/// 2. Hard exclusion of `isPrivate == true` investigation cases.
/// 3. PBKDF2-HMAC-SHA256 + AES-256-GCM authenticated encryption (`MF-CLINIC-V1:...`).
/// 4. Deterministic SHA-256 packet integrity verification.
class ClinicianSyncService {
  const ClinicianSyncService({
    this.defaultPbkdf2Iterations = 100000,
  });

  final int defaultPbkdf2Iterations;

  static const String codePrefix = 'MF-CLINIC-V1:';
  static const String carePlanPrefix = 'MF-CAREPLAN-V1:';
  static const Uuid _uuid = Uuid();

  /// Recursively canonicalizes JSON maps (sorted keys) so integrity hashes
  /// remain deterministic regardless of map construction order.
  static dynamic _canonicalizeValue(dynamic value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      return {
        for (final k in sortedKeys) k: _canonicalizeValue(value[k]),
      };
    }
    if (value is List) {
      return value.map(_canonicalizeValue).toList(growable: false);
    }
    return value;
  }

  /// Computes lowercase SHA-256 hex digest over canonicalized JSON body.
  static String computeIntegrityHash(Map<String, dynamic> bodyWithoutHash) {
    final canonical = _canonicalizeValue(bodyWithoutHash);
    final encoded = jsonEncode(canonical);
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  /// Builds a sanitized, consent-scoped [ClinicianSyncPacket] from patient data.
  ClinicianSyncPacket buildPatientPacket({
    required String patientDisplayName,
    required String patientAnonymousId,
    required ClinicalConsentScope consentScope,
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<SymptomReport> symptomReports,
    PsychologicalProfileModel? profile,
    PreVisitAgenda? preVisitAgenda,
    DateTime? referenceNow,
    String? packetId,
  }) {
    final now = referenceNow ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowDays = consentScope.windowDays.clamp(1, 365);
    final cutoffDay = todayStart.subtract(Duration(days: windowDays - 1));

    final scopedTraces = consentScope.includeMoodMetrics
        ? traces.where((t) {
            final d = DateTime(t.date.year, t.date.month, t.date.day);
            return !d.isBefore(cutoffDay);
          }).map((t) {
            var sanitized = t;
            if (!consentScope.includePersonalNotes) {
              sanitized = sanitized.copyWith(
                clearJournalText: true,
                clearSituation: true,
                clearBehavioralResponse: true,
                clearAiReflection: true,
                clearVoiceNotePath: true,
                dynamicAnswers: const {},
                investigationAnswers: const {},
                clearSymptomsAndExperiences:
                    !consentScope.includeSymptomReports,
              );
            }
            if (!consentScope.includeSleepEnergyAnxiety) {
              sanitized = sanitized.copyWith(
                clearSleepHours: true,
                clearSleepQuality: true,
                clearEnergyLevel: true,
                clearAnxietyLevel: true,
                clearPhysicalTension: true,
              );
            }
            return sanitized;
          }).toList()
        : <MindTraceModel>[];

    scopedTraces.sort(
      (a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp),
    );

    // Hard privacy gate: NEVER include cases marked isPrivate == true.
    final scopedCases = consentScope.includeSharedCases
        ? cases
            .where((c) => !c.isPrivate)
            .where((c) {
              final d = DateTime(
                c.updatedAt.year,
                c.updatedAt.month,
                c.updatedAt.day,
              );
              return !d.isBefore(cutoffDay);
            })
            .toList()
        : <CaseModel>[];

    scopedCases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final scopedSymptoms = consentScope.includeSymptomReports
        ? symptomReports.where((s) {
            final d = DateTime(
              s.createdAt.year,
              s.createdAt.month,
              s.createdAt.day,
            );
            return !d.isBefore(cutoffDay);
          }).toList()
        : <SymptomReport>[];

    scopedSymptoms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    PsychologicalProfileModel? scopedProfile;
    if (consentScope.includePsychologicalProfile && profile != null) {
      scopedProfile = consentScope.includePersonalNotes
          ? profile
          : profile.copyWith(
              personalIntroduction: '',
              additionalContext: '',
              personalContext: '',
              notesForAiCompanion: '',
              symptomNotes: '',
              customAiDirectives: '',
            );
    }

    final scopedAgenda = (consentScope.includePreVisitAgenda &&
            preVisitAgenda != null &&
            !preVisitAgenda.isEmpty)
        ? preVisitAgenda
        : null;

    final draft = ClinicianSyncPacket(
      schemaVersion: 1,
      packetId: packetId ?? 'pkt_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}',
      generatedAt: now,
      patientDisplayName: patientDisplayName.trim().isEmpty
          ? 'Shared Patient'
          : patientDisplayName.trim(),
      patientAnonymousId: patientAnonymousId.trim().isEmpty
          ? 'anon_patient'
          : patientAnonymousId.trim(),
      consentScope: consentScope,
      traces: scopedTraces,
      sharedCases: scopedCases,
      symptomReports: scopedSymptoms,
      profileSnapshot: scopedProfile,
      preVisitAgenda: scopedAgenda,
      integrityHash: '',
    );

    final hash = computeIntegrityHash(draft.toCanonicalBodyJson());
    return draft.copyWith(integrityHash: hash);
  }

  /// Encrypts a [ClinicianSyncPacket] into an offline-transferable `MF-CLINIC-V1:...` code.
  Future<String> encryptPacketToShareCode(
    ClinicianSyncPacket packet,
    String passphrase, {
    int? pbkdf2Iterations,
  }) {
    final packetToEncrypt = packet.integrityHash.isEmpty
        ? packet.copyWith(
            integrityHash: computeIntegrityHash(packet.toCanonicalBodyJson()),
          )
        : packet;
    return _encryptJsonWithPassphrase(
      packetToEncrypt.toJson(),
      prefix: codePrefix,
      passphrase: passphrase,
      pbkdf2Iterations: pbkdf2Iterations,
    );
  }

  /// Decrypts and authenticates an `MF-CLINIC-V1:...` packet share code.
  Future<ClinicianSyncPacket> decryptShareCode(
    String rawCode,
    String passphrase,
  ) async {
    final decodedMap = await _decryptJsonWithPassphrase(
      rawCode: rawCode,
      prefix: codePrefix,
      passphrase: passphrase,
    );

    final rawCases = decodedMap['sharedCases'] as List<dynamic>? ?? const [];
    final containsForgedPrivateCase = rawCases.any(
      (item) => item is Map<String, dynamic> && item['isPrivate'] == true,
    );
    if (containsForgedPrivateCase) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.integrityMismatch,
        'Private case detected inside handoff packet; rejected.',
      );
    }

    final expectedHash = decodedMap['integrityHash'] as String? ?? '';
    final bodyForHash = Map<String, dynamic>.from(decodedMap)
      ..remove('integrityHash');
    final actualHash = computeIntegrityHash(bodyForHash);

    if (expectedHash.isEmpty ||
        !AuthService.constantTimeEquals(
          utf8.encode(expectedHash),
          utf8.encode(actualHash),
        )) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.integrityMismatch,
        'Packet SHA-256 integrity hash mismatch.',
      );
    }

    return ClinicianSyncPacket.fromJson(decodedMap);
  }

  /// Builds a SHA-256 integrity-signed [PostVisitFocusPlan] for `Clinician -> Patient`.
  PostVisitFocusPlan buildPostVisitFocusPlan({
    required String clinicianName,
    String clinicName = '',
    required List<String> focusTitles,
    DateTime? followUpDate,
    String observationCue = '',
    DateTime? referenceNow,
    String? planId,
  }) {
    final rawNow = referenceNow ?? DateTime.now();
    final now = DateTime.parse(rawNow.toIso8601String());
    final cleanFollowUp = followUpDate != null
        ? DateTime.parse(followUpDate.toIso8601String())
        : null;

    final items = <FocusGoalItem>[];
    for (var i = 0; i < focusTitles.length; i++) {
      final title = focusTitles[i].trim();
      if (title.isEmpty) continue;
      items.add(
        FocusGoalItem(
          id: 'fg_${now.millisecondsSinceEpoch}_$i',
          title: title,
          isCompleted: false,
        ),
      );
    }

    final draft = PostVisitFocusPlan(
      schemaVersion: 1,
      planId: planId ?? 'plan_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}',
      clinicianName:
          clinicianName.trim().isEmpty ? 'Clinician' : clinicianName.trim(),
      clinicName: clinicName.trim(),
      createdAt: now,
      followUpDate: cleanFollowUp,
      focusItems: items,
      observationCue: observationCue.trim(),
      isDismissed: false,
      integrityHash: '',
    );

    final hash = computeIntegrityHash(draft.toCanonicalBodyJson());
    return draft.copyWith(integrityHash: hash);
  }

  /// Encrypts a [PostVisitFocusPlan] into an offline-transferable `MF-CAREPLAN-V1:...` code.
  Future<String> encryptCarePlanToCode(
    PostVisitFocusPlan plan,
    String passphrase, {
    int? pbkdf2Iterations,
  }) {
    final signed = plan.integrityHash.isEmpty
        ? plan.copyWith(
            integrityHash: computeIntegrityHash(plan.toCanonicalBodyJson()),
          )
        : plan;
    return _encryptJsonWithPassphrase(
      signed.toJson(),
      prefix: carePlanPrefix,
      passphrase: passphrase,
      pbkdf2Iterations: pbkdf2Iterations,
    );
  }

  /// Decrypts and authenticates an `MF-CAREPLAN-V1:...` post-visit focus code.
  Future<PostVisitFocusPlan> decryptCarePlanCode(
    String rawCode,
    String passphrase,
  ) async {
    final decodedMap = await _decryptJsonWithPassphrase(
      rawCode: rawCode,
      prefix: carePlanPrefix,
      passphrase: passphrase,
    );

    final plan = PostVisitFocusPlan.fromJson(decodedMap);
    final expectedHash = decodedMap['integrityHash'] as String? ?? '';
    final actualHash = computeIntegrityHash(plan.toCanonicalBodyJson());

    if (expectedHash.isEmpty ||
        !AuthService.constantTimeEquals(
          utf8.encode(expectedHash),
          utf8.encode(actualHash),
        )) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.integrityMismatch,
        'Care plan SHA-256 integrity hash mismatch.',
      );
    }

    return plan;
  }

  Future<String> _encryptJsonWithPassphrase(
    Map<String, dynamic> payloadMap, {
    required String prefix,
    required String passphrase,
    int? pbkdf2Iterations,
  }) async {
    final cleanPass = passphrase.trim();
    if (cleanPass.length < 6) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'Passphrase must be at least 6 characters.',
      );
    }

    final iterations = pbkdf2Iterations ?? defaultPbkdf2Iterations;
    if (iterations < 1000) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'PBKDF2 iteration count is below safe minimum.',
      );
    }

    final salt = AuthService.generateSecureSalt(16);
    final hashRecord = AuthService.hashPassword(
      cleanPass,
      explicitSalt: salt,
      iterations: iterations,
    );
    final parts = hashRecord.split('\$');
    final keyBytes = base64Url.decode(parts[3]);

    final cipher = LocalDataCipher(secretKeyBytes: keyBytes);
    final encryptedPayload = await cipher.encryptString(jsonEncode(payloadMap));

    final envelope = {
      'v': 1,
      'kdf': 'pbkdf2_sha256',
      'iter': iterations,
      'salt': base64Url.encode(salt),
      'payload': encryptedPayload,
    };

    final encodedEnvelope = base64Url.encode(
      utf8.encode(jsonEncode(envelope)),
    );
    return '$prefix$encodedEnvelope';
  }

  Future<Map<String, dynamic>> _decryptJsonWithPassphrase({
    required String rawCode,
    required String prefix,
    required String passphrase,
  }) async {
    final cleanedCode = rawCode.replaceAll(RegExp(r'\s+'), '');
    if (!cleanedCode.startsWith(prefix)) {
      throw ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'Code does not match $prefix format.',
      );
    }

    final cleanPass = passphrase.trim();
    if (cleanPass.isEmpty) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.decryptionFailed,
        'Passphrase is required.',
      );
    }

    final Map<String, dynamic> envelope;
    try {
      final b64Part = cleanedCode.substring(prefix.length);
      final envelopeJson = utf8.decode(base64Url.decode(b64Part));
      final decoded = jsonDecode(envelopeJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Envelope must be a JSON object.');
      }
      envelope = decoded;
    } catch (_) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'Malformed sync code envelope.',
      );
    }

    final version = envelope['v'];
    if (version != 1) {
      throw ClinicianSyncException(
        ClinicianSyncErrorCode.unsupportedVersion,
        'Unsupported handoff version: $version',
      );
    }

    final iterations = (envelope['iter'] as num?)?.toInt();
    final saltB64 = envelope['salt'] as String?;
    final encryptedPayload = envelope['payload'] as String?;
    if (iterations == null ||
        iterations < 1000 ||
        iterations > 1000000 ||
        saltB64 == null ||
        encryptedPayload == null ||
        encryptedPayload.isEmpty) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'Missing required cryptographic parameters.',
      );
    }

    final String plaintextJson;
    try {
      final salt = base64Url.decode(saltB64);
      final hashRecord = AuthService.hashPassword(
        cleanPass,
        explicitSalt: salt,
        iterations: iterations,
      );
      final parts = hashRecord.split('\$');
      final keyBytes = base64Url.decode(parts[3]);
      final cipher = LocalDataCipher(secretKeyBytes: keyBytes);
      plaintextJson = await cipher.decryptString(encryptedPayload);
    } on DecryptionSecurityException {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.decryptionFailed,
        'Unable to authenticate or decrypt sync code.',
      );
    } catch (_) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.decryptionFailed,
        'Unable to decrypt sync code.',
      );
    }

    try {
      final parsed = jsonDecode(plaintextJson);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Packet must be JSON object');
      }
      return parsed;
    } catch (_) {
      throw const ClinicianSyncException(
        ClinicianSyncErrorCode.invalidFormat,
        'Decrypted packet payload is malformed JSON.',
      );
    }
  }

  /// Formats a plain-text, non-diagnostic clinical consultation summary ready
  /// to copy into any EHR / consultation record.
  String generateEhrClinicalNote(
    ClinicianPatientRecord record,
    AppStrings strings,
  ) {
    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final baseline = record.baseline;
    final recent = record.recentBaseline;
    final divergences = record.divergences(strings);
    final isAr = strings.isArabic;
    final isFr = strings.isFrench;

    final buf = StringBuffer();
    buf.writeln('============================================================');
    buf.writeln(isAr
        ? 'MIND FORENSICS — ملخص استشارة سريري (EHR BRIEF)'
        : (isFr
            ? 'MIND FORENSICS — SYNTHÈSE CLINIQUE DE CONSULTATION (EHR)'
            : 'MIND FORENSICS — CLINICAL CONSULTATION SUMMARY (EHR)'));
    buf.writeln('Patient: ${record.displayName}${record.isDemoCase ? ' [DEMO]' : ''}');
    buf.writeln(
      'Sync Window: ${scope.windowDays}d | Traces: ${packet.traces.length} | Shared Cases: ${packet.sharedCases.length}',
    );
    buf.writeln('Packet ID: ${packet.packetId}');
    buf.writeln('============================================================');
    buf.writeln();

    // 1. Pre-visit Agenda
    final agenda = packet.preVisitAgenda;
    if (scope.includePreVisitAgenda && agenda != null && !agenda.isEmpty) {
      buf.writeln('[1] PRE-VISIT CONSULTATION AGENDA');
      if (agenda.selectedTopics.isNotEmpty) {
        buf.writeln('Topics: ${agenda.selectedTopics.join(', ')}');
      }
      if (agenda.patientQuestion.trim().isNotEmpty) {
        buf.writeln('Patient question: ${agenda.patientQuestion.trim()}');
      }
      if (agenda.whatHelpedRecently.trim().isNotEmpty) {
        buf.writeln('What helped recently: ${agenda.whatHelpedRecently.trim()}');
      }
      buf.writeln();
    }

    // 2. Baseline Metrics & 7-Day Comparison
    if (baseline.totalRecordedDays > 0) {
      buf.writeln('[2] 7-DAY RECENT VS PERSONAL BASELINE');
      String fmt(double? v, [String suffix = '']) =>
          v == null ? 'N/A' : '${v.toStringAsFixed(1)}$suffix';
      String delta(double? r, double? b, [String suffix = '']) {
        if (r == null || b == null) return '--';
        final d = r - b;
        final sign = d >= 0 ? '+' : '';
        return '$sign${d.toStringAsFixed(1)}$suffix';
      }

      buf.writeln(
        '- Mood Intensity: ${fmt(recent.averageMoodIntensity, '/10')} vs ${fmt(baseline.averageMoodIntensity, '/10')} (${delta(recent.averageMoodIntensity, baseline.averageMoodIntensity)})',
      );
      if (scope.includeSleepEnergyAnxiety) {
        buf.writeln(
          '- Sleep Duration: ${fmt(recent.averageSleepHours, 'h')} vs ${fmt(baseline.averageSleepHours, 'h')} (${delta(recent.averageSleepHours, baseline.averageSleepHours, 'h')})',
        );
        buf.writeln(
          '- Energy Level: ${fmt(recent.averageEnergyLevel, '/10')} vs ${fmt(baseline.averageEnergyLevel, '/10')} (${delta(recent.averageEnergyLevel, baseline.averageEnergyLevel)})',
        );
        buf.writeln(
          '- Anxiety Tension: ${fmt(recent.averageAnxietyLevel, '/10')} vs ${fmt(baseline.averageAnxietyLevel, '/10')} (${delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel)})',
        );
      } else {
        buf.writeln('- Sleep / Energy / Anxiety: Excluded by patient consent.');
      }
      buf.writeln();
    }

    // 3. Affect Spectrum & Diurnal Rhythm
    if (baseline.emotionFrequencyMap.isNotEmpty ||
        baseline.diurnalIntensityAverages.isNotEmpty) {
      buf.writeln('[3] AFFECT SPECTRUM & DIURNAL RHYTHM');
      if (baseline.emotionFrequencyMap.isNotEmpty) {
        final topAffects = baseline.emotionFrequencyMap.entries.take(5).map(
              (e) =>
                  '${AffectTaxonomy.localizedLabel(e.key, strings)} (${e.value}x)',
            );
        buf.writeln('Co-occurring feelings: ${topAffects.join(', ')}');
      }
      final swingAvg = baseline.averageIntraDaySwing;
      if (swingAvg != null && swingAvg > 0) {
        buf.writeln(
          'Intra-day intensity swing avg: +/-${swingAvg.toStringAsFixed(1)} pts (${baseline.multiEntryDaysCount} multi-moment days)',
        );
      }
      if (baseline.diurnalIntensityAverages.isNotEmpty) {
        final parts = DayTimeBucket.values
            .where((b) => baseline.diurnalIntensityAverages.containsKey(b))
            .map(
              (b) =>
                  '${b.name}: ${baseline.diurnalIntensityAverages[b]!.toStringAsFixed(1)}/10',
            );
        buf.writeln('Time-of-day rhythm: ${parts.join(' | ')}');
      }
      buf.writeln();
    }

    // 4. Objective Pattern Observations
    buf.writeln('[4] OBJECTIVE BASELINE SHIFTS');
    if (divergences.isEmpty) {
      buf.writeln('No notable metric divergence detected vs personal baseline.');
    } else {
      for (final d in divergences) {
        buf.writeln('* ${d.title} (${d.timeWindow})');
        buf.writeln('  ${d.baselineComparison}');
      }
    }
    buf.writeln();

    // 5. Shared CBT-Inspired Reflections
    final shareableCases =
        packet.sharedCases.where((c) => !c.isPrivate).toList(growable: false);
    buf.writeln('[5] SHARED COGNITIVE EXPLORATIONS (INSPIRED BY CBT)');
    if (!scope.includeSharedCases) {
      buf.writeln('Excluded by patient consent.');
    } else if (shareableCases.isEmpty) {
      buf.writeln('None shared within this window.');
    } else {
      for (final c in shareableCases) {
        buf.writeln('- ${c.caseNumber}: ${c.title}');
        if (c.chain != null) {
          buf.writeln(
            '  Trigger -> Thought (${c.chain!.thoughtLabel.displayName}) -> Emotion -> Response: '
            '${c.chain!.trigger} | ${c.chain!.thought} | ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10) | ${c.chain!.behavior}',
          );
        }
        if (c.userConclusion != null && c.userConclusion!.trim().isNotEmpty) {
          buf.writeln('  Patient takeaway: ${c.userConclusion!.trim()}');
        }
      }
    }
    buf.writeln();

    // 6. Clinician Private Consultation Notes
    if (record.clinicianNotes.isNotEmpty) {
      buf.writeln('[6] CLINICIAN CONSULTATION NOTES (WORKSPACE LOCAL)');
      for (final note in record.clinicianNotes) {
        final dateStr =
            '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}';
        buf.writeln(
          '- [$dateStr | ${note.category.shortCode}] ${note.content.trim()}',
        );
      }
      buf.writeln();
    }

    buf.writeln(
      'NOTE: Mind Forensics clinical observation summary — non-diagnostic record; excludes private cases.',
    );
    return buf.toString().trimRight();
  }
}
