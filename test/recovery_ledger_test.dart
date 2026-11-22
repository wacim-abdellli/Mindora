import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/domain/recovery_ledger_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 5.1: Empirical Recovery Ledger (Observed Stabilizers)', () {
    test(
      '1. RecoveryLedger computes intra-day calming shifts, canonicalizes multilingual actions, and excludes stressor tags',
      () {
        final baseDay = DateTime(2026, 11, 20);
        final traces = <MindTraceModel>[
          // Day 1: morning peak 8 -> evening 5 (-3 shift) with EN 'Breathing'
          MindTraceModel(
            id: 'r1_m',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day, 9, 0),
            overallMood: 'anxious',
            moodIntensity: 8,
            behavioralResponse: 'Breathing',
            contextTags: const ['high_workload', 'physical_movement'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'r1_e',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day, 20, 0),
            overallMood: 'calm',
            moodIntensity: 5,
            behavioralResponse: 'Respiration, Quiet evening walk',
            contextTags: const ['physical_movement', 'late_caffeine_screens'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          // Day 2: morning peak 7 -> evening 4 (-3 shift) with AR 'تنفّس'
          MindTraceModel(
            id: 'r2_m',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 1, 8, 30),
            overallMood: 'heavy',
            moodIntensity: 7,
            behavioralResponse: 'تنفّس',
            contextTags: const ['sleep_consistent'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'r2_e',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 1, 21, 0),
            overallMood: 'calm',
            moodIntensity: 4,
            behavioralResponse: 'Walk',
            contextTags: const ['sleep_consistent'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
        ];

        final ledger = RecoveryLedger.fromTraces(traces);
        expect(ledger.hasEvidence, isTrue);
        expect(ledger.multiMomentShiftDays, equals(2));
        expect(ledger.averageRecoveryDrop, equals(-3.0));

        // Stressor tags must NEVER appear as stabilizers
        expect(
          ledger.stabilizers.any((s) => s.key == 'high_workload'),
          isFalse,
        );
        expect(
          ledger.stabilizers.any((s) => s.key == 'late_caffeine_screens'),
          isFalse,
        );

        // Breathing canonicalizes EN + FR + AR into a single stabilizer
        final breathing = ledger.stabilizers.firstWhere(
          (s) => s.sourceType == 'action' && s.key == 'breathing',
        );
        expect(breathing.totalOccurrences, equals(3));
        expect(breathing.sameDayRecoveryDays, equals(2));
        expect(breathing.avgSameDayShift, equals(-3.0));
        expect(breathing.localizedLabel(const AppStrings('en')), equals('Breathing'));
        expect(breathing.localizedLabel(const AppStrings('fr')), equals('Respiration'));

        final movement = ledger.stabilizers.firstWhere(
          (s) => s.sourceType == 'context' && s.key == 'physical_movement',
        );
        expect(movement.totalOccurrences, equals(2));
        expect(movement.avgSameDayShift, equals(-3.0));

        final baseline = PersonalBaseline.fromTraces(traces);
        expect(baseline.recoveryLedger.hasEvidence, isTrue);
      },
    );

    test(
      '2. EHR summary includes Observed stabilizers with zero emojis and zero forbidden phrases',
      () {
        const syncService = ClinicianSyncService();
        final nadia = DemoClinicalCohort.buildRecords().first;
        final ehr = syncService.generateEhrClinicalNote(
          nadia,
          const AppStrings('en'),
        );

        expect(ehr, contains('Observed stabilizers (self-reported):'));
        expect(ehr, contains('Walk'));
        expect(ehr.toLowerCase(), isNot(contains('cbt treatment')));
        expect(ehr.toLowerCase(), isNot(contains('relapse')));
        expect(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true)
              .hasMatch(ehr),
          isFalse,
        );
      },
    );

    testWidgets(
      '3. InsightsScreen and ClinicianPatientDetailScreen render Observed Stabilizers cleanly including 320px Arabic RTL',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        final repo = container.read(mindTraceRepositoryProvider);
        await repo.saveTrace(
          MindTraceModel(
            id: 'rl_ui_am',
            date: DateTime(now.year, now.month, now.day, 9, 0),
            overallMood: 'anxious',
            moodIntensity: 8,
            sleepHours: 6.0,
            behavioralResponse: 'Breathing',
            contextTags: const ['physical_movement'],
            createdAt: now,
            updatedAt: now,
          ),
        );
        await repo.saveTrace(
          MindTraceModel(
            id: 'rl_ui_pm',
            date: DateTime(now.year, now.month, now.day, 20, 0),
            overallMood: 'calm',
            moodIntensity: 4,
            sleepHours: 6.0,
            behavioralResponse: 'Walk',
            contextTags: const ['physical_movement', 'routine_kept'],
            createdAt: now,
            updatedAt: now,
          ),
        );
        await container.read(mindTraceControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('insights_rl'),
              theme: buildMindTheme(Brightness.dark),
              home: const InsightsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('OBSERVED STABILIZERS'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('OBSERVED STABILIZERS'), findsOneWidget);
        expect(find.textContaining('same-day shift'), findsWidgets);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('dossier_rl_en'),
              theme: buildMindTheme(Brightness.light),
              home: const ClinicianPatientDetailScreen(patientId: 'demo_nadia_b'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('OBSERVED STABILIZERS'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('OBSERVED STABILIZERS'), findsOneWidget);

        // 320px + 1.35x text scaling + Arabic RTL check
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        const arStrings = AppStrings('ar');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('dossier_rl_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: ClinicianPatientDetailScreen(
                      patientId: 'demo_nadia_b',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text(arStrings.observedStabilizersTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(arStrings.observedStabilizersTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
