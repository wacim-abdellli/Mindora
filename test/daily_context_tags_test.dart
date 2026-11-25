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
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 4.3: Daily Context & Routine Tags', () {
    test(
      '1. MindTraceModel contextTags JSON roundtrip and legacy JSON fallback',
      () {
        final now = DateTime(2026, 11, 22, 10, 0);
        final trace = MindTraceModel(
          id: 't_ctx_1',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          contextTags: const ['routine_kept', 'physical_movement'],
          createdAt: now,
          updatedAt: now,
        );

        final roundtrip = MindTraceModel.fromJson(trace.toJson());
        expect(
          roundtrip.contextTags,
          equals(['routine_kept', 'physical_movement']),
        );

        final legacyJson = trace.toJson()..remove('contextTags');
        final legacyParsed = MindTraceModel.fromJson(legacyJson);
        expect(legacyParsed.contextTags, isEmpty);
      },
    );

    test(
      '2. PersonalBaseline.fromTraces aggregates descriptive contextTagCorrelations',
      () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 12, 0);
        final traces = [
          MindTraceModel(
            id: 'c1',
            date: today.subtract(const Duration(days: 2)),
            overallMood: 'anxious',
            moodIntensity: 8,
            anxietyLevel: 8,
            sleepHours: 5.0,
            contextTags: const ['late_caffeine_screens', 'high_workload'],
            createdAt: today.subtract(const Duration(days: 2)),
            updatedAt: today.subtract(const Duration(days: 2)),
          ),
          MindTraceModel(
            id: 'c2',
            date: today.subtract(const Duration(days: 1)),
            overallMood: 'restless',
            moodIntensity: 6,
            anxietyLevel: 6,
            sleepHours: 6.0,
            contextTags: const ['late_caffeine_screens'],
            createdAt: today.subtract(const Duration(days: 1)),
            updatedAt: today.subtract(const Duration(days: 1)),
          ),
          MindTraceModel(
            id: 'c3',
            date: today,
            overallMood: 'calm',
            moodIntensity: 4,
            anxietyLevel: 2,
            sleepHours: 8.0,
            contextTags: const ['physical_movement'],
            createdAt: today,
            updatedAt: today,
          ),
        ];

        final baseline = PersonalBaseline.fromTraces(traces);
        expect(baseline.contextTagCorrelations.length, equals(3));

        final top = baseline.contextTagCorrelations.first;
        expect(top.tagKey, equals('late_caffeine_screens'));
        expect(top.occurrences, equals(2));
        expect(top.avgMoodIntensity, equals(7.0));
        expect(top.avgAnxietyLevel, equals(7.0));
        expect(top.avgSleepHours, equals(5.5));
      },
    );

    test(
      '3. Care handoff strips contextTags when somatic consent is off and EHR summary includes them when shared',
      () {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final nadia = DemoClinicalCohort.buildRecords().first;

        final ehrSummary = syncService.generateEhrClinicalNote(
          nadia,
          const AppStrings('en'),
        );
        expect(ehrSummary, contains('Daily context & routine links:'));
        expect(ehrSummary, contains('Routine kept'));
        expect(ehrSummary.toLowerCase(), isNot(contains('cbt treatment')));
        expect(ehrSummary.toLowerCase(), isNot(contains('relapse')));
        expect(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true)
              .hasMatch(ehrSummary),
          isFalse,
        );

        final restricted = syncService.buildPatientPacket(
          patientDisplayName: 'Test User',
          patientAnonymousId: 'u_test',
          consentScope: const ClinicalConsentScope(
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: false,
          ),
          traces: nadia.latestPacket.traces,
          cases: const [],
          symptomReports: const [],
        );

        expect(
          restricted.traces.every((t) => t.contextTags.isEmpty),
          isTrue,
        );

        final parsedRestricted = ClinicianSyncPacket.fromJson(
          restricted.toJson(),
        );
        expect(
          parsedRestricted.traces.every((t) => t.contextTags.isEmpty),
          isTrue,
        );
      },
    );

    testWidgets(
      '4. ProgressiveDetailsSheet saves contextTags -> InsightsScreen & ClinicianPatientDetailScreen render links cleanly (incl. 320px AR RTL)',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        final baseTrace = MindTraceModel(
          id: 'ctx_trace_1',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          createdAt: now,
          updatedAt: now,
        );
        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(baseTrace, generateAi: false);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ProgressiveDetailsSheet(trace: baseTrace),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        // Card 1 (Nuance) -> Skip, Card 2 (Sleep/Energy) -> Skip -> Card 3 (Context)
        await tester.tap(find.text(enStrings.skipBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.text(enStrings.skipBtn));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Regular sleep'));
        await tester.tap(find.text('Regular sleep'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Physical movement'));
        await tester.tap(find.text('Physical movement'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(enStrings.doneBtn));
        await tester.tap(find.text(enStrings.doneBtn));
        await tester.pumpAndSettle();

        final saved = container.read(todayTraceProvider);
        expect(saved, isNotNull);
        expect(
          saved!.contextTags,
          containsAll(['sleep_consistent', 'physical_movement']),
        );

        // Render InsightsScreen and expand See more details to verify Daily Context & Routine Links card
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const InsightsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final moreBtn = find.byKey(
          const ValueKey<String>('patterns-more-details-btn'),
        );
        await tester.ensureVisible(moreBtn);
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('DAILY CONTEXT & ROUTINE LINKS'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('DAILY CONTEXT & ROUTINE LINKS'), findsOneWidget);
        expect(find.text('Regular sleep'), findsWidgets);

        // Render ClinicianPatientDetailScreen for Nadia B. and verify Overview + Timeline
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianPatientDetailScreen(patientId: 'demo_nadia_b'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('DAILY CONTEXT & ROUTINE LINKS'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('DAILY CONTEXT & ROUTINE LINKS'), findsOneWidget);

        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
        expect(find.text('Heavy workload'), findsWidgets);

        // Narrow 320px + 1.35x text scaling + Arabic RTL check
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
              key: const ValueKey('clinician_320_rtl'),
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
          find.text(arStrings.dailyContextSectionTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(arStrings.dailyContextSectionTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
