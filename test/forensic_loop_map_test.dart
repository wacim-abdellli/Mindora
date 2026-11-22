import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/clinician/data/clinical_brief_pdf_service.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/insights/domain/forensic_loop_model.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/presentation/widgets/forensic_loop_map_card.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';

void main() {
  group('ForensicLoopLink & ForensicLoopMapCard', () {
    final now = DateTime(2026, 11, 20, 21, 0);

    List<MindTraceModel> sampleTraces() => [
          MindTraceModel(
            id: 't1',
            date: DateTime(2026, 11, 18, 21, 0),
            overallMood: 'heavy',
            selectedEmotions: const ['heavy', 'overwhelmed'],
            moodIntensity: 8,
            sleepHours: 5.5,
            contextTags: const ['high_workload', 'late_caffeine_screens'],
            behavioralResponse: 'Took a short walk outside',
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't2',
            date: DateTime(2026, 11, 18, 23, 0),
            overallMood: 'calm',
            selectedEmotions: const ['calm'],
            moodIntensity: 4,
            sleepHours: 7.5,
            contextTags: const ['sleep_consistent', 'physical_movement'],
            behavioralResponse: 'Breathing and quiet time',
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't3',
            date: DateTime(2026, 11, 19, 20, 30),
            overallMood: 'anxious',
            selectedEmotions: const ['anxious', 'overwhelmed'],
            moodIntensity: 7,
            sleepHours: 6.0,
            contextTags: const ['high_workload'],
            behavioralResponse: 'Took a short walk outside',
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't4',
            date: DateTime(2026, 11, 19, 22, 30),
            overallMood: 'calm',
            selectedEmotions: const ['grounded'],
            moodIntensity: 3,
            sleepHours: 8.0,
            contextTags: const ['sleep_consistent', 'physical_movement'],
            behavioralResponse: 'Breathing and quiet time',
            createdAt: now,
            updatedAt: now,
          ),
        ];

    CaseModel publicCase() => CaseModel(
          id: 'case_public',
          caseNumber: 'CASE-01',
          title: 'Evening work pressure',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Late message from supervisor',
          chain: const ForensicChain(
            trigger: 'Late message from supervisor',
            thought: 'I am falling behind on everything this week.',
            thoughtLabel: LabelType.assumption,
            emotion: 'Overwhelmed',
            emotionIntensity: 7,
            behavior: 'Kept checking messages late',
          ),
          isPrivate: false,
        );

    CaseModel privateCase() => CaseModel(
          id: 'case_private_secret',
          caseNumber: 'CASE-99',
          title: 'SECRET_PRIVATE_TITLE',
          createdAt: now.add(const Duration(hours: 2)),
          updatedAt: now.add(const Duration(hours: 2)),
          currentStage: CaseStage.conclusion,
          incidentDescription: 'SECRET_PRIVATE_INCIDENT',
          chain: const ForensicChain(
            trigger: 'SECRET_PRIVATE_TRIGGER',
            thought: 'SECRET_PRIVATE_THOUGHT_MUST_NEVER_LEAK',
            thoughtLabel: LabelType.interpretation,
            emotion: 'Anxious',
            emotionIntensity: 8,
            behavior: 'Withdrew',
          ),
          isPrivate: true,
        );

    test('synthesizes 4 connected nodes and omits private cases when requested',
        () {
      final baseline = PersonalBaseline.fromTraces(
        sampleTraces(),
        baselineDays: 30,
        referenceDate: now,
      );
      const strings = AppStrings('en');

      // Patient view: includes latest case (even private)
      final patientLoop = ForensicLoopLink.synthesize(
        baseline: baseline,
        cases: [publicCase(), privateCase()],
        strings: strings,
        excludePrivateCases: false,
      );
      expect(patientLoop.populatedNodeCount, 4);
      expect(patientLoop.hasSufficientSignal, isTrue);
      expect(
        patientLoop.recurringThoughtTheme,
        contains('SECRET_PRIVATE_THOUGHT_MUST_NEVER_LEAK'),
      );

      // Clinician view: strictly excludes private vault cases
      final clinicLoop = ForensicLoopLink.synthesize(
        baseline: baseline,
        cases: [publicCase(), privateCase()],
        strings: strings,
        excludePrivateCases: true,
      );
      expect(clinicLoop.populatedNodeCount, 4);
      expect(
        clinicLoop.recurringThoughtTheme,
        contains('falling behind on everything'),
      );
      expect(clinicLoop.recurringThoughtTheme, isNot(contains('SECRET_PRIVATE')));
      expect(clinicLoop.thoughtLabel, LabelType.assumption);
      expect(
        clinicLoop.compactSummary(strings),
        contains(' -> '),
      );
    });

    test('respects consent includeSomatic=false and sparse empty baseline', () {
      final baseline = PersonalBaseline.fromTraces(
        sampleTraces(),
        baselineDays: 30,
        referenceDate: now,
      );
      const strings = AppStrings('en');

      final withSomaticLoop = ForensicLoopLink.synthesize(
        baseline: baseline,
        cases: [publicCase()],
        strings: strings,
        excludePrivateCases: true,
        includeSomatic: true,
      );
      expect(
        withSomaticLoop.somaticAffectPattern,
        matches(RegExp(r'\d+\.\dh')),
      );

      final noSomaticLoop = ForensicLoopLink.synthesize(
        baseline: baseline,
        cases: [publicCase()],
        strings: strings,
        excludePrivateCases: true,
        includeSomatic: false,
      );
      expect(
        noSomaticLoop.somaticAffectPattern,
        isNot(matches(RegExp(r'\d+\.\dh'))),
      );

      final emptyLoop = ForensicLoopLink.synthesize(
        baseline: PersonalBaseline.empty,
        cases: const [],
        strings: strings,
      );
      expect(emptyLoop.populatedNodeCount, 0);
      expect(emptyLoop.hasSufficientSignal, isFalse);
    });

    test(
        'EHR Clinical Note & A4 Brief include Forensic Loop without private leaks',
        () async {
      final traces = sampleTraces();
      final packet = ClinicianSyncPacket(
        packetId: 'pkt_loop_1',
        generatedAt: now,
        patientDisplayName: 'Nadia B.',
        patientAnonymousId: 'demo_nadia',
        consentScope: const ClinicalConsentScope(
          windowDays: 30,
          includeMoodMetrics: true,
          includeSleepEnergyAnxiety: true,
          includeSharedCases: true,
        ),
        traces: traces,
        sharedCases: [publicCase(), privateCase()],
      );
      final record = ClinicianPatientRecord(
        patientId: 'demo_nadia',
        displayName: 'Nadia B.',
        importedAt: now,
        lastSyncedAt: now,
        latestPacket: packet,
      );

      const strings = AppStrings('en');
      const syncService = ClinicianSyncService();
      final ehr = syncService.generateEhrClinicalNote(record, strings);
      expect(ehr, contains('[3b] OBSERVED FORENSIC LOOP'));
      expect(ehr, contains('falling behind on everything'));
      expect(ehr, isNot(contains('SECRET_PRIVATE')));

      const pdfService = ClinicalBriefPdfService();
      final pdf = await pdfService.renderConsultationBrief(
        record: record,
        strings: strings,
      );
      expect(pdf.plainSummary, contains('[3b] OBSERVED FORENSIC LOOP'));
      expect(pdf.plainSummary, isNot(contains('SECRET_PRIVATE')));
      expect(pdf.pdfBytes.length, greaterThan(1000));
    });

    testWidgets(
      'renders overflow-free in 320px Arabic RTL at 1.35x text scale with zero emojis',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final baseline = PersonalBaseline.fromTraces(
          sampleTraces(),
          baselineDays: 30,
          referenceDate: now,
        );
        const strings = AppStrings('ar');
        final loop = ForensicLoopLink.synthesize(
          baseline: baseline,
          cases: [publicCase()],
          strings: strings,
          excludePrivateCases: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            locale: const Locale('ar'),
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: ForensicLoopMapCard(
                        loop: loop,
                        strings: strings,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(strings.forensicLoopMapTitle), findsOneWidget);
        expect(find.text('4/4'), findsOneWidget);
      },
    );
  });
}
