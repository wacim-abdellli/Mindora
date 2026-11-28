import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../auth/data/auth_service.dart';
import '../../insights/domain/forensic_loop_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/adaptive_tracking_engine.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
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
  const ClinicianSyncService({this.defaultPbkdf2Iterations = 100000});

  final int defaultPbkdf2Iterations;

  static const String codePrefix = 'MF-CLINIC-V1:';
  static const String carePlanPrefix = 'MF-CAREPLAN-V1:';
  static const Uuid _uuid = Uuid();

  /// Recursively canonicalizes JSON maps (sorted keys) so integrity hashes
  /// remain deterministic regardless of map construction order.
  static dynamic _canonicalizeValue(dynamic value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in sortedKeys) k: _canonicalizeValue(value[k])};
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

    // Hard privacy gate: NEVER include traces or cases marked isPrivate == true.
    final scopedTraces = consentScope.includeMoodMetrics
        ? traces
              .where((t) {
                if (t.isPrivate) return false;
                final d = DateTime(t.date.year, t.date.month, t.date.day);
                return !d.isBefore(cutoffDay);
              })
              .map(consentScope.sanitizeTrace)
              .toList()
        : <MindTraceModel>[];

    scopedTraces.sort(
      (a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp),
    );

    // Hard privacy gate: NEVER include cases marked isPrivate == true.
    final scopedCases = consentScope.includeSharedCases
        ? cases.where((c) => !c.isPrivate).where((c) {
            final d = DateTime(
              c.updatedAt.year,
              c.updatedAt.month,
              c.updatedAt.day,
            );
            return !d.isBefore(cutoffDay);
          }).toList()
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

    final scopedAgenda =
        (consentScope.includePreVisitAgenda &&
            preVisitAgenda != null &&
            !preVisitAgenda.isEmpty)
        ? preVisitAgenda
        : null;

    final draft = ClinicianSyncPacket(
      schemaVersion: 1,
      packetId:
          packetId ??
          'pkt_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}',
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
      planId:
          planId ??
          'plan_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}',
      clinicianName: clinicianName.trim().isEmpty
          ? 'Clinician'
          : clinicianName.trim(),
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
    final rawJson = jsonEncode(payloadMap);
    final rawBytes = utf8.encode(rawJson);
    final compressedB64 = base64Url.encode(gzip.encode(rawBytes));
    final useGzip = compressedB64.length < rawJson.length;
    final encryptedPayload = await cipher.encryptString(
      useGzip ? compressedB64 : rawJson,
    );

    final envelope = {
      'v': 1,
      'kdf': 'pbkdf2_sha256',
      'iter': iterations,
      'salt': base64Url.encode(salt),
      if (useGzip) 'enc': 'gz',
      'payload': encryptedPayload,
    };

    final encodedEnvelope = base64Url.encode(utf8.encode(jsonEncode(envelope)));
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
      final jsonText = envelope['enc'] == 'gz'
          ? utf8.decode(gzip.decode(base64Url.decode(plaintextJson)))
          : plaintextJson;
      final parsed = jsonDecode(jsonText);
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
    buf.writeln(
      isAr
          ? 'Mindora — ملخص استشارة سريري (EHR BRIEF)'
          : (isFr
                ? 'Mindora — SYNTHÈSE CLINIQUE DE CONSULTATION (EHR)'
                : 'Mindora — CLINICAL CONSULTATION SUMMARY (EHR)'),
    );
    final demoTag = record.isDemoCase
        ? (isAr ? ' [نموذج تجريبي]' : (isFr ? ' [DÉMO]' : ' [DEMO]'))
        : '';
    buf.writeln(
      isAr
          ? 'المريض: ${record.displayName}$demoTag'
          : (isFr
                ? 'Patient : ${record.displayName}$demoTag'
                : 'Patient: ${record.displayName}$demoTag'),
    );
    buf.writeln(
      isAr
          ? 'فترة المتابعة: ${MindFormatters.daysShort(scope.windowDays, strings)} | التسجيلات: ${packet.traces.length} | الجلسات المشتركة: ${packet.sharedCases.length}'
          : (isFr
                ? 'Période : ${MindFormatters.daysShort(scope.windowDays, strings)} | Suivis : ${packet.traces.length} | Explorations partagées : ${packet.sharedCases.length}'
                : 'Sync Window: ${scope.windowDays}d | Traces: ${packet.traces.length} | Shared Cases: ${packet.sharedCases.length}'),
    );
    buf.writeln(
      isAr
          ? 'معرّف الملف: ${MindFormatters.ltrIsolate(packet.packetId)}'
          : (isFr
                ? 'Réf. dossier : ${packet.packetId}'
                : 'Packet ID: ${packet.packetId}'),
    );
    buf.writeln('============================================================');
    buf.writeln();

    // 0. Clinician-Documented Clinical Summary (strictly clinician-authored)
    final cr = record.clinicalRecord;
    if (cr.diagnoses.isNotEmpty ||
        cr.medications.isNotEmpty ||
        cr.allergies.isNotEmpty ||
        cr.noKnownAllergies) {
      buf.writeln('[0] ${strings.clinicalSummaryTitle}');
      if (cr.diagnoses.isNotEmpty) {
        buf.writeln(
          '${strings.documentedDiagnosesTitle}: '
          '${cr.diagnoses.map((d) => '${d.displayTitle} (${d.certainty.localizedLabel(strings)}, ${d.status.localizedLabel(strings)})').join('; ')}',
        );
      }
      if (cr.medications.isNotEmpty) {
        buf.writeln(
          '${strings.currentMedicationsTitle}: '
          '${cr.medications.map((m) => '${m.name}${m.regimenSummary.isNotEmpty ? ' (${m.regimenSummary})' : ''} [${m.status.localizedLabel(strings)}]').join('; ')}',
        );
      }
      if (cr.allergies.isNotEmpty) {
        buf.writeln(
          '${strings.allergiesTitle}: '
          '${cr.allergies.map((a) => '${a.substance}${a.reaction.trim().isNotEmpty ? ' - ${a.reaction.trim()}' : ''} (${a.severity.localizedLabel(strings)})').join('; ')}',
        );
      } else if (cr.noKnownAllergies) {
        buf.writeln('${strings.allergiesTitle}: ${strings.noKnownAllergiesLabel}');
      }
      buf.writeln();
    }

    // 1. Pre-visit Agenda
    final agenda = packet.preVisitAgenda;
    if (scope.includePreVisitAgenda && agenda != null && !agenda.isEmpty) {
      buf.writeln(
        isAr
            ? '[1] نقاط ما قبل الاستشارة'
            : (isFr
                  ? '[1] ORDRE DU JOUR PRÉ-CONSULTATION'
                  : '[1] PRE-VISIT CONSULTATION AGENDA'),
      );
      if (agenda.selectedTopics.isNotEmpty) {
        buf.writeln(
          isAr
              ? 'المواضيع المختارة: ${agenda.selectedTopics.join('، ')}'
              : (isFr
                    ? 'Sujets : ${agenda.selectedTopics.join(', ')}'
                    : 'Topics: ${agenda.selectedTopics.join(', ')}'),
        );
      }
      if (agenda.patientQuestion.trim().isNotEmpty) {
        buf.writeln(
          isAr
              ? 'سؤال المريض: ${agenda.patientQuestion.trim()}'
              : (isFr
                    ? 'Question du patient : ${agenda.patientQuestion.trim()}'
                    : 'Patient question: ${agenda.patientQuestion.trim()}'),
        );
      }
      if (agenda.whatHelpedRecently.trim().isNotEmpty) {
        buf.writeln(
          isAr
              ? 'ما ساعد مؤخراً: ${agenda.whatHelpedRecently.trim()}'
              : (isFr
                    ? 'Ce qui a aidé récemment : ${agenda.whatHelpedRecently.trim()}'
                    : 'What helped recently: ${agenda.whatHelpedRecently.trim()}'),
        );
      }
      if (agenda.focusPlanFeedback.trim().isNotEmpty) {
        buf.writeln(
          isAr
              ? 'ملاحظات المريض حول خطة التركيز: ${agenda.focusPlanFeedback.trim()}'
              : (isFr
                    ? 'Retour sur le plan de suivi : ${agenda.focusPlanFeedback.trim()}'
                    : 'Between-session focus feedback: ${agenda.focusPlanFeedback.trim()}'),
        );
      }
      buf.writeln();
    }

    // 2. Baseline Metrics & 7-Day Comparison
    if (baseline.totalRecordedDays > 0) {
      buf.writeln(
        isAr
            ? '[2] مقارنة آخر 7 أيام بالمرجع الشخصي'
            : (isFr
                  ? '[2] 7 DERNIERS JOURS VS REPÈRE PERSONNEL'
                  : '[2] 7-DAY RECENT VS PERSONAL BASELINE'),
      );
      final naLabel = isAr ? 'غ/م' : (isFr ? 'N/D' : 'N/A');
      String fmt(double? v, [String suffix = '']) {
        if (v == null) return naLabel;
        if (suffix == 'h') return MindFormatters.hours(v, strings);
        return '${MindFormatters.decimal(v, strings)}$suffix';
      }

      String delta(double? r, double? b, [String suffix = '']) {
        if (r == null || b == null) return '--';
        return MindFormatters.signedDelta(r - b, strings, unit: suffix);
      }

      final vsWord = isAr ? 'مقابل' : 'vs';
      buf.writeln(
        isAr
            ? '- شدّة المزاج: ${fmt(recent.averageMoodIntensity, '/10')} $vsWord ${fmt(baseline.averageMoodIntensity, '/10')} (${delta(recent.averageMoodIntensity, baseline.averageMoodIntensity)})'
            : (isFr
                  ? '- Intensité de l’humeur : ${fmt(recent.averageMoodIntensity, '/10')} $vsWord ${fmt(baseline.averageMoodIntensity, '/10')} (${delta(recent.averageMoodIntensity, baseline.averageMoodIntensity)})'
                  : '- Mood Intensity: ${fmt(recent.averageMoodIntensity, '/10')} vs ${fmt(baseline.averageMoodIntensity, '/10')} (${delta(recent.averageMoodIntensity, baseline.averageMoodIntensity)})'),
      );
      if (scope.includeSleepEnergyAnxiety) {
        buf.writeln(
          isAr
              ? '- مدّة النوم: ${fmt(recent.averageSleepHours, 'h')} $vsWord ${fmt(baseline.averageSleepHours, 'h')} (${delta(recent.averageSleepHours, baseline.averageSleepHours, 'h')})'
              : (isFr
                    ? '- Durée du sommeil : ${fmt(recent.averageSleepHours, 'h')} $vsWord ${fmt(baseline.averageSleepHours, 'h')} (${delta(recent.averageSleepHours, baseline.averageSleepHours, 'h')})'
                    : '- Sleep Duration: ${fmt(recent.averageSleepHours, 'h')} vs ${fmt(baseline.averageSleepHours, 'h')} (${delta(recent.averageSleepHours, baseline.averageSleepHours, 'h')})'),
        );
        buf.writeln(
          isAr
              ? '- مستوى الطاقة: ${fmt(recent.averageEnergyLevel, '/10')} $vsWord ${fmt(baseline.averageEnergyLevel, '/10')} (${delta(recent.averageEnergyLevel, baseline.averageEnergyLevel)})'
              : (isFr
                    ? '- Niveau d’énergie : ${fmt(recent.averageEnergyLevel, '/10')} $vsWord ${fmt(baseline.averageEnergyLevel, '/10')} (${delta(recent.averageEnergyLevel, baseline.averageEnergyLevel)})'
                    : '- Energy Level: ${fmt(recent.averageEnergyLevel, '/10')} vs ${fmt(baseline.averageEnergyLevel, '/10')} (${delta(recent.averageEnergyLevel, baseline.averageEnergyLevel)})'),
        );
        buf.writeln(
          isAr
              ? '- توتّر القلق: ${fmt(recent.averageAnxietyLevel, '/10')} $vsWord ${fmt(baseline.averageAnxietyLevel, '/10')} (${delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel)})'
              : (isFr
                    ? '- Tension anxieuse : ${fmt(recent.averageAnxietyLevel, '/10')} $vsWord ${fmt(baseline.averageAnxietyLevel, '/10')} (${delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel)})'
                    : '- Anxiety Tension: ${fmt(recent.averageAnxietyLevel, '/10')} vs ${fmt(baseline.averageAnxietyLevel, '/10')} (${delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel)})'),
        );
      } else {
        buf.writeln(
          isAr
              ? '- النوم / الطاقة / القلق: مستثناة بموافقة المريض.'
              : (isFr
                    ? '- Sommeil / Énergie / Anxiété : exclus par consentement du patient.'
                    : '- Sleep / Energy / Anxiety: Excluded by patient consent.'),
        );
      }
      buf.writeln();
    }

    // 2b. Visit-to-Visit Comparison
    final visitDiff = record.visitDiff;
    if (visitDiff != null &&
        (visitDiff.hasMetricDelta || visitDiff.focusPlanFeedback.isNotEmpty)) {
      buf.writeln(
        isAr
            ? '[2b] المقارنة منذ آخر زيارة (${MindFormatters.daysShort(visitDiff.daysBetween, strings)})'
            : (isFr
                  ? '[2b] ÉVOLUTION DEPUIS LA DERNIÈRE VISITE (${MindFormatters.daysShort(visitDiff.daysBetween, strings)})'
                  : '[2b] SINCE LAST VISIT COMPARISON (${visitDiff.daysBetween}d apart)'),
      );
      String signed(double v, [String suffix = '']) =>
          MindFormatters.signedDelta(v, strings, unit: suffix);

      if (visitDiff.moodDelta != null) {
        buf.writeln(
          isAr
              ? '- تغيّر المزاج منذ آخر زيارة: ${signed(visitDiff.moodDelta!, '/10')}'
              : (isFr
                    ? '- Écart d’humeur depuis la dernière visite : ${signed(visitDiff.moodDelta!, '/10')}'
                    : '- Mood delta vs last visit: ${signed(visitDiff.moodDelta!, '/10')}'),
        );
      }
      if (scope.includeSleepEnergyAnxiety) {
        if (visitDiff.sleepDelta != null) {
          buf.writeln(
            isAr
                ? '- تغيّر النوم منذ آخر زيارة: ${signed(visitDiff.sleepDelta!, 'h')}'
                : (isFr
                      ? '- Écart de sommeil depuis la dernière visite : ${signed(visitDiff.sleepDelta!, 'h')}'
                      : '- Sleep delta vs last visit: ${signed(visitDiff.sleepDelta!, 'h')}'),
          );
        }
        if (visitDiff.energyDelta != null) {
          buf.writeln(
            isAr
                ? '- تغيّر الطاقة منذ آخر زيارة: ${signed(visitDiff.energyDelta!, '/10')}'
                : (isFr
                      ? '- Écart d’énergie depuis la dernière visite : ${signed(visitDiff.energyDelta!, '/10')}'
                      : '- Energy delta vs last visit: ${signed(visitDiff.energyDelta!, '/10')}'),
          );
        }
        if (visitDiff.anxietyDelta != null) {
          buf.writeln(
            isAr
                ? '- تغيّر القلق منذ آخر زيارة: ${signed(visitDiff.anxietyDelta!, '/10')}'
                : (isFr
                      ? '- Écart d’anxiété depuis la dernière visite : ${signed(visitDiff.anxietyDelta!, '/10')}'
                      : '- Anxiety delta vs last visit: ${signed(visitDiff.anxietyDelta!, '/10')}'),
          );
        }
      }
      if (visitDiff.eveningIntensityDelta != null) {
        buf.writeln(
          isAr
              ? '- تغيّر شدّة المساء منذ آخر زيارة: ${signed(visitDiff.eveningIntensityDelta!, '/10')}'
              : (isFr
                    ? '- Écart d’intensité en soirée : ${signed(visitDiff.eveningIntensityDelta!, '/10')}'
                    : '- Evening intensity delta vs last visit: ${signed(visitDiff.eveningIntensityDelta!, '/10')}'),
        );
      }
      if (visitDiff.focusPlanFeedback.isNotEmpty) {
        buf.writeln(
          isAr
              ? '- تعليق المريض على خطة التركيز: ${visitDiff.focusPlanFeedback}'
              : (isFr
                    ? '- Retour patient sur le plan de suivi : ${visitDiff.focusPlanFeedback}'
                    : '- Patient focus plan feedback: ${visitDiff.focusPlanFeedback}'),
        );
      }
      buf.writeln();
    }

    // 3. Affect Spectrum & Diurnal Rhythm
    if (baseline.emotionFrequencyMap.isNotEmpty ||
        baseline.diurnalIntensityAverages.isNotEmpty ||
        baseline.recoveryLedger.hasEvidence) {
      buf.writeln(
        isAr
            ? '[3] طيف المشاعر والإيقاع اليومي'
            : (isFr
                  ? '[3] SPECTRE AFFECTIF ET RYTHME DIURNE'
                  : '[3] AFFECT SPECTRUM & DIURNAL RHYTHM'),
      );
      if (baseline.emotionFrequencyMap.isNotEmpty) {
        final topAffects = baseline.emotionFrequencyMap.entries
            .take(5)
            .map(
              (e) =>
                  '${AffectTaxonomy.localizedLabel(e.key, strings)} (${MindFormatters.times(e.value, strings)})',
            );
        buf.writeln(
          isAr
              ? 'المشاعر المتكررة: ${topAffects.join('، ')}'
              : (isFr
                    ? 'Émotions co-occurrentes : ${topAffects.join(', ')}'
                    : 'Co-occurring feelings: ${topAffects.join(', ')}'),
        );
      }
      final swingAvg = baseline.averageIntraDaySwing;
      if (swingAvg != null && swingAvg > 0) {
        final swingFormatted = MindFormatters.decimal(swingAvg, strings);
        buf.writeln(
          isAr
              ? 'متوسط التذبذب اليومي: +/-$swingFormatted نقطة (${baseline.multiEntryDaysCount} أيام متعددة التسجيل)'
              : (isFr
                    ? 'Amplitude intra-journalière moyenne : +/-$swingFormatted pts (${baseline.multiEntryDaysCount} jours multi-entrées)'
                    : 'Intra-day intensity swing avg: +/-$swingFormatted pts (${baseline.multiEntryDaysCount} multi-moment days)'),
        );
      }
      if (baseline.diurnalIntensityAverages.isNotEmpty) {
        String bucketLabel(DayTimeBucket b) => switch (b) {
          DayTimeBucket.morning => strings.morningBucketLabel,
          DayTimeBucket.afternoon => strings.afternoonBucketLabel,
          DayTimeBucket.evening => strings.eveningBucketLabel,
          DayTimeBucket.night => strings.nightBucketLabel,
        };
        final parts = DayTimeBucket.values
            .where((b) => baseline.diurnalIntensityAverages.containsKey(b))
            .map(
              (b) =>
                  '${isAr || isFr ? bucketLabel(b) : b.name}: ${MindFormatters.decimal(baseline.diurnalIntensityAverages[b]!, strings)}/10',
            );
        buf.writeln(
          isAr
              ? 'إيقاع أوقات اليوم: ${parts.join(' | ')}'
              : (isFr
                    ? 'Rythme selon le moment de la journée : ${parts.join(' | ')}'
                    : 'Time-of-day rhythm: ${parts.join(' | ')}'),
        );
      }
      if (scope.includeSleepEnergyAnxiety &&
          baseline.contextTagCorrelations.isNotEmpty) {
        final tagSummaries = baseline.contextTagCorrelations.take(4).map((c) {
          final label = DailyContextTags.localizedLabel(c.tagKey, strings);
          final sleepPart = c.avgSleepHours != null
              ? (isAr
                    ? '، نوم ${MindFormatters.hours(c.avgSleepHours!, strings)}'
                    : (isFr
                          ? ', sommeil ${MindFormatters.hours(c.avgSleepHours!, strings)}'
                          : ', sleep ${c.avgSleepHours!.toStringAsFixed(1)}h'))
              : '';
          final moodPart = c.avgMoodIntensity != null
              ? (isAr
                    ? '، مزاج ${MindFormatters.decimal(c.avgMoodIntensity!, strings)}/10'
                    : (isFr
                          ? ', humeur ${MindFormatters.decimal(c.avgMoodIntensity!, strings)}/10'
                          : ', mood ${c.avgMoodIntensity!.toStringAsFixed(1)}/10'))
              : '';
          return '$label (${MindFormatters.times(c.occurrences, strings)}$moodPart$sleepPart)';
        });
        buf.writeln(
          isAr
              ? 'روابط السياق اليومي والروتين: ${tagSummaries.join(' | ')}'
              : (isFr
                    ? 'Liens contexte quotidien & routine : ${tagSummaries.join(' | ')}'
                    : 'Daily context & routine links: ${tagSummaries.join(' | ')}'),
        );
      }
      if (scope.includeMoodMetrics && baseline.recoveryLedger.hasEvidence) {
        final stabParts = baseline.recoveryLedger.stabilizers.take(4).map((s) {
          final label = s.localizedLabel(strings);
          final shiftStr = s.avgSameDayShift != null && s.avgSameDayShift! < 0
              ? (isAr
                    ? '، تغيّر ${MindFormatters.signedDelta(s.avgSameDayShift!, strings, unit: '/10')}'
                    : (isFr
                          ? ', variation ${MindFormatters.signedDelta(s.avgSameDayShift!, strings, unit: '/10')}'
                          : ', ${s.avgSameDayShift!.toStringAsFixed(1)}/10 shift'))
              : (s.avgCoOccurringIntensity != null
                    ? (isAr
                          ? '، متوسط ${MindFormatters.decimal(s.avgCoOccurringIntensity!, strings)}/10'
                          : (isFr
                                ? ', moy. ${MindFormatters.decimal(s.avgCoOccurringIntensity!, strings)}/10'
                                : ', avg ${s.avgCoOccurringIntensity!.toStringAsFixed(1)}/10'))
                    : '');
          return '$label (${MindFormatters.times(s.totalOccurrences, strings)}$shiftStr)';
        });
        buf.writeln(
          isAr
              ? 'عوامل الاستقرار الملاحظة (ذاتية التبليغ): ${stabParts.join(' | ')}'
              : (isFr
                    ? 'Facteurs stabilisants observés (auto-déclarés) : ${stabParts.join(' | ')}'
                    : 'Observed stabilizers (self-reported): ${stabParts.join(' | ')}'),
        );
      }
      final conditionTracks = ClinicalConditionCatalog.resolveTracks(
        packet.profileSnapshot,
      );
      final conditionMarkers = AdaptiveTrackingEngine.summarizeConditionMarkers(
        packet.traces,
        conditionTracks,
        strings,
      );
      if (scope.includeMoodMetrics && conditionMarkers.isNotEmpty) {
        buf.writeln(
          isAr
              ? 'مؤشرات مسارات المتابعة (${conditionTracks.map((t) => t.localizedTitle(strings)).join('، ')}): ${conditionMarkers.join(' | ')}'
              : (isFr
                    ? 'Indicateurs de suivi spécifiques (${conditionTracks.map((t) => t.localizedTitle(strings)).join(', ')}) : ${conditionMarkers.join(' | ')}'
                    : 'Condition-specific markers (${conditionTracks.map((t) => t.localizedTitle(strings)).join(', ')}): ${conditionMarkers.join(' | ')}'),
        );
      }
      buf.writeln();
    }

    // 3b. Observed Forensic Loop (privacy-respecting synthesis)
    if (scope.includeMoodMetrics) {
      final loop = ForensicLoopLink.synthesize(
        baseline: baseline,
        cases: scope.includeSharedCases ? packet.sharedCases : const [],
        strings: strings,
        excludePrivateCases: true,
        includeSomatic: scope.includeSleepEnergyAnxiety,
      );
      if (loop.hasSufficientSignal) {
        buf.writeln(
          isAr
              ? '[3b] الحلقة السلوكية والفكرية الملاحظة'
              : (isFr
                    ? '[3b] BOUCLE D’OBSERVATION COGNITIVE'
                    : '[3b] OBSERVED FORENSIC LOOP'),
        );
        buf.writeln(loop.compactSummary(strings));
        buf.writeln();
      }
    }

    // 4. Objective Pattern Observations
    buf.writeln(
      isAr
          ? '[4] التغيّرات الموضوعية مقارنة بالمرجع'
          : (isFr
                ? '[4] ÉCARTS OBJECTIFS PAR RAPPORT AU REPÈRE'
                : '[4] OBJECTIVE BASELINE SHIFTS'),
    );
    if (divergences.isEmpty) {
      buf.writeln(
        isAr
            ? 'لا توجد فوارق ملحوظة مقارنة بالمرجع الشخصي.'
            : (isFr
                  ? 'Aucun écart notable détecté par rapport au repère personnel.'
                  : 'No notable metric divergence detected vs personal baseline.'),
      );
    } else {
      for (final d in divergences) {
        buf.writeln('* ${d.title} (${d.timeWindow})');
        buf.writeln('  ${d.baselineComparison}');
      }
    }
    buf.writeln();

    // 5. Shared CBT-Inspired Reflections
    final shareableCases = packet.sharedCases
        .where((c) => !c.isPrivate)
        .toList(growable: false);
    buf.writeln(
      isAr
          ? '[5] التأملات الفكرية المشتركة (مستوحاة من العلاج المعرفي السلوكي)'
          : (isFr
                ? '[5] EXPLORATIONS COGNITIVES PARTAGÉES (INSPIRÉES DES TCC)'
                : '[5] SHARED COGNITIVE EXPLORATIONS (INSPIRED BY CBT)'),
    );
    if (!scope.includeSharedCases) {
      buf.writeln(
        isAr
            ? 'مستثناة بموافقة المريض.'
            : (isFr
                  ? 'Exclues par consentement du patient.'
                  : 'Excluded by patient consent.'),
      );
    } else if (shareableCases.isEmpty) {
      buf.writeln(
        isAr
            ? 'لم تتم مشاركة أي جلسة خلال هذه الفترة.'
            : (isFr
                  ? 'Aucune exploration partagée sur cette période.'
                  : 'None shared within this window.'),
      );
    } else {
      final arrow = MindFormatters.rangeArrow(strings);
      for (final c in shareableCases) {
        buf.writeln('- ${c.caseNumber}: ${c.title}');
        if (c.chain != null) {
          final thoughtLabel = strings.localizedLabelName(c.chain!.thoughtLabel);
          buf.writeln(
            isAr
                ? '  المحفّز $arrow الفكرة ($thoughtLabel) $arrow الشعور $arrow الاستجابة: '
                  '${c.chain!.trigger} | ${c.chain!.thought} | ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10) | ${c.chain!.behavior}'
                : (isFr
                      ? '  Déclencheur $arrow Pensée ($thoughtLabel) $arrow Émotion $arrow Réponse : '
                        '${c.chain!.trigger} | ${c.chain!.thought} | ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10) | ${c.chain!.behavior}'
                      : '  Trigger -> Thought (${c.chain!.thoughtLabel.displayName}) -> Emotion -> Response: '
                        '${c.chain!.trigger} | ${c.chain!.thought} | ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10) | ${c.chain!.behavior}'),
          );
        }
        if (c.findingsSummary != null &&
            c.findingsSummary!.trim().isNotEmpty &&
            c.findingsSummary!.trim() != (c.userConclusion ?? '').trim()) {
          buf.writeln(
            isAr
                ? '  ملخص مساعد Mindora الذكي: ${c.findingsSummary!.trim()}'
                : (isFr
                      ? '  Synthèse IA (assistant) : ${c.findingsSummary!.trim()}'
                      : '  Clinical intake note: ${c.findingsSummary!.trim()}'),
          );
        }
        if (c.userConclusion != null && c.userConclusion!.trim().isNotEmpty) {
          buf.writeln(
            isAr
                ? '  خلاصة المريض بنفسه: ${c.userConclusion!.trim()}'
                : (isFr
                      ? '  Conclusion rédigée par le patient : ${c.userConclusion!.trim()}'
                      : '  Patient takeaway: ${c.userConclusion!.trim()}'),
          );
        }
      }
    }
    buf.writeln();

    // 6. Clinician Private Consultation Notes
    if (record.clinicianNotes.isNotEmpty) {
      buf.writeln(
        isAr
            ? '[6] ملاحظات الطبيب الخاصة بالاستشارة (محلية)'
            : (isFr
                  ? '[6] NOTES CLINIQUES DU MÉDECIN (ESPACE LOCAL)'
                  : '[6] CLINICIAN CONSULTATION NOTES (WORKSPACE LOCAL)'),
      );
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
      isAr
          ? 'ملاحظة: ملخص ملاحظة سريرية من Mindora — وثيقة غير تشخيصية وتستثني تلقائياً الملفات الخاصة.'
          : (isFr
                ? 'NOTE : Synthèse d’observation clinique Mindora — document non diagnostique excluant strictement les dossiers privés.'
                : 'NOTE: Mindora clinical observation summary — non-diagnostic record; excludes private cases.'),
    );
    return buf.toString().trimRight();
  }
}
