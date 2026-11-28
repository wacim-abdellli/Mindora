import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/share_with_psychiatrist_sheet.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 3: Encrypted Care Handoff Protocol & Psychiatrist Workspace', () {
    test(
      '1. Hard privacy gate & consent scoping strip private cases, personal notes, and somatic fields',
      () {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 20, 14, 0);

        final traces = [
          MindTraceModel(
            id: 't1',
            userId: 'u1',
            date: now,
            overallMood: 'anxious',
            selectedEmotions: const ['anxious', 'overwhelmed'],
            moodIntensity: 7,
            energyLevel: 4,
            anxietyLevel: 8,
            sleepHours: 5.5,
            situation: 'Private workplace conflict note',
            behavioralResponse: 'Withdrew for an hour',
            journalText: 'Sensitive private diary line never to share',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final publicCase = CaseModel(
          id: 'c_public',
          caseNumber: 'SESSION 01',
          title: 'Work deadline interpretation',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Deadline stress',
          isPrivate: false,
        );

        final privateCase = CaseModel(
          id: 'c_private',
          caseNumber: 'SESSION 02',
          title: 'Strictly Private Secret Entry',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.findings,
          incidentDescription: 'Private family secret',
          userConclusion: 'Should never exit private gate',
          isPrivate: true,
        );

        final packet = syncService.buildPatientPacket(
          patientDisplayName: 'Amira K.',
          patientAnonymousId: 'u1',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: false,
            includePersonalNotes: false,
            includeSharedCases: true,
            includeSymptomReports: true,
            includePsychologicalProfile: false,
            includePreVisitAgenda: false,
          ),
          traces: traces,
          cases: [publicCase, privateCase],
          symptomReports: const [],
          referenceNow: now,
        );

        // Private case must NEVER enter packet
        expect(packet.sharedCases.length, equals(1));
        expect(packet.sharedCases.first.id, equals('c_public'));

        // Excluded notes & somatic metrics must be null/cleared
        expect(packet.traces.length, equals(1));
        expect(packet.traces.first.journalText, isNull);
        expect(packet.traces.first.situation, isNull);
        expect(packet.traces.first.behavioralResponse, isNull);
        expect(packet.traces.first.sleepHours, isNull);
        expect(packet.traces.first.energyLevel, isNull);
        expect(packet.traces.first.anxietyLevel, isNull);

        // Defensive check: forged JSON containing a private case must be stripped by fromJson
        final forgedJson = packet.toJson();
        forgedJson['sharedCases'] = [
          ...(forgedJson['sharedCases'] as List<dynamic>),
          privateCase.toJson(),
        ];
        final sanitizedFromJson = ClinicianSyncPacket.fromJson(forgedJson);
        expect(
          sanitizedFromJson.sharedCases.any((c) => c.id == 'c_private'),
          isFalse,
        );
      },
    );

    test(
      '2. Encrypted MF-CLINIC-V1 share code roundtrip, wrong passphrase failure, and tamper rejection',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final demoRecords = DemoClinicalCohort.buildRecords();
        final nadiaPacket = demoRecords.first.latestPacket;

        final code = await syncService.encryptPacketToShareCode(
          nadiaPacket,
          'tunis-care-2026',
          pbkdf2Iterations: 2000,
        );
        expect(code.startsWith(ClinicianSyncService.codePrefix), isTrue);

        final decrypted = await syncService.decryptShareCode(
          code,
          'tunis-care-2026',
        );
        expect(decrypted.patientDisplayName, equals('Nadia B.'));
        expect(decrypted.traces.length, equals(nadiaPacket.traces.length));
        expect(decrypted.sharedCases.length, equals(1));
        expect(
          decrypted.preVisitAgenda?.patientQuestion,
          contains('19:00'),
        );

        await expectLater(
          syncService.decryptShareCode(code, 'wrong-passphrase'),
          throwsA(
            isA<ClinicianSyncException>().having(
              (e) => e.code,
              'code',
              ClinicianSyncErrorCode.decryptionFailed,
            ),
          ),
        );

        final mid = code.length ~/ 2;
        final replacement = code[mid] == 'A' ? 'B' : 'A';
        final tampered =
            '${code.substring(0, mid)}$replacement${code.substring(mid + 1)}';
        await expectLater(
          syncService.decryptShareCode(tampered, 'tunis-care-2026'),
          throwsA(isA<ClinicianSyncException>()),
        );
      },
    );

    test(
      '3. EHR clinical summary includes baseline deltas & agenda, zero emojis, zero forbidden terms',
      () {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final nadia = DemoClinicalCohort.buildRecords().first;
        final summary = syncService.generateEhrClinicalNote(
          nadia,
          const AppStrings('en'),
        );

        expect(summary, contains('Nadia B.'));
        expect(summary, contains('PRE-VISIT CONSULTATION AGENDA'));
        expect(summary, contains('7-DAY RECENT VS PERSONAL BASELINE'));
        expect(summary, contains('Sleep Duration'));
        expect(summary, contains('Sleep shifts'));
        expect(summary.toLowerCase(), isNot(contains('cbt treatment')));
        expect(summary.toLowerCase(), isNot(contains('relapse')));
        expect(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true)
              .hasMatch(summary),
          isFalse,
        );
      },
    );

    testWidgets(
      '4. ShareWithPsychiatristSheet enforces private exclusion, generates code, and delivers to workspace',
      (tester) async {
        final now = DateTime.now();
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(
              const ClinicianSyncService(defaultPbkdf2Iterations: 2000),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(caseRepositoryProvider).saveCase(
              CaseModel(
                id: 'priv_case_1',
                caseNumber: 'SESSION 01',
                title: 'Confidential entry',
                createdAt: now,
                updatedAt: now,
                currentStage: CaseStage.incident,
                incidentDescription: 'Hidden',
                isPrivate: true,
              ),
            );
        await container.read(caseRepositoryProvider).saveCase(
              CaseModel(
                id: 'pub_case_1',
                caseNumber: 'SESSION 02',
                title: 'Shareable entry',
                createdAt: now,
                updatedAt: now,
                currentStage: CaseStage.findings,
                incidentDescription: 'Shareable thought pattern',
                isPrivate: false,
              ),
            );
        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'patient_trace_1',
                date: now,
                overallMood: 'heavy',
                selectedEmotions: const ['heavy', 'numb'],
                moodIntensity: 7,
                sleepHours: 6.0,
                energyLevel: 4,
                anxietyLevel: 6,
                createdAt: now,
                updatedAt: now,
              ),
            );

        await container.read(savedCasesProvider.future);
        await container.read(mindTraceControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => ShareWithPsychiatristSheet.show(ctx),
                      child: const Text('Open Share'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Share'));
        await tester.pumpAndSettle();

        expect(find.textContaining('1 private talk(s) left out'), findsOneWidget);

        await tester.ensureVisible(find.text('Sleep shifts'));
        await tester.tap(find.text('Sleep shifts'));
        await tester.pumpAndSettle();

        // Enter passphrase & generate encrypted code
        final fields = find.byType(TextField);
        await tester.ensureVisible(fields.last);
        await tester.enterText(fields.last, 'clinic-pass-99');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Generate Encrypted Sync Code'));
        await tester.tap(find.text('Generate Encrypted Sync Code'));
        await tester.pumpAndSettle();

        expect(find.textContaining('MF-CLINIC-V1:'), findsOneWidget);

        // Send directly to on-device Psychiatrist Workspace
        await tester.ensureVisible(
          find.text('Send to Psychiatrist Workspace on This Device'),
        );
        await tester.tap(
          find.text('Send to Psychiatrist Workspace on This Device'),
        );
        await tester.pumpAndSettle();

        final roster = await container.read(clinicianRosterProvider.future);
        final imported = roster.where((r) => !r.isDemoCase).toList();
        expect(imported.length, equals(1));
        expect(imported.first.latestPacket.sharedCases.length, equals(1));
        expect(
          imported.first.latestPacket.sharedCases.first.id,
          equals('pub_case_1'),
        );
        expect(
          imported.first.latestPacket.preVisitAgenda?.selectedTopics,
          contains('Sleep shifts'),
        );
      },
    );

    testWidgets(
      '5. ClinicianShellScreen renders 3-tab dock, cohort triage filters, and Practice controls',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 3 bottom dock tabs + 3 demo patients visible
        expect(find.text('Patients'), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);

        expect(find.text('Nadia B.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Karim M.'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Karim M.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Lina S.'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Lina S.'), findsOneWidget);

        // Filter to Shifts Noted: Lina S. (steady baseline) is filtered out
        await tester.scrollUntilVisible(
          find.text('Shifts Noted'),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Shifts Noted'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Shifts Noted'));
        await tester.pumpAndSettle();
        expect(find.text('Nadia B.'), findsOneWidget);
        expect(find.text('Lina S.'), findsNothing);

        await tester.scrollUntilVisible(
          find.text('All'),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('All'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Lina S.'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Lina S.'), findsOneWidget);

        // Overview tab
        await tester.tap(find.text('Overview'));
        await tester.pumpAndSettle();
        final obsFinder = find.text(const AppStrings('en').cohortObservationsTitle);
        await tester.scrollUntilVisible(
          obsFinder,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(obsFinder, findsOneWidget);

        // Practice tab & toggle Demo Cohort off/on
        await tester.tap(find.text('Practice'));
        await tester.pumpAndSettle();
        expect(find.text('Demo Clinical Dataset'), findsOneWidget);

        final demoSwitch = find.byKey(
          const ValueKey<String>('clinician-demo-cohort-switch'),
        );
        await tester.ensureVisible(demoSwitch);
        await tester.tap(demoSwitch);
        await tester.pumpAndSettle();
        expect(await container.read(clinicianDemoEnabledProvider.future), isFalse);

        await tester.tap(demoSwitch);
        await tester.pumpAndSettle();
        expect(await container.read(clinicianDemoEnabledProvider.future), isTrue);
      },
    );

    testWidgets(
      '6. ClinicianPatientDetailScreen navigates 4 MindSegmented views and persists private notes',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

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

        expect(find.text('Nadia B.'), findsOneWidget);
        expect(find.byType(MindSegmented), findsOneWidget);
        expect(find.text('Sleep shifts'), findsOneWidget);

        // Switch to Timeline
        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
        expect(find.textContaining('20:15'), findsWidgets);

        // Switch to Cases
        await tester.tap(find.text('Cases'));
        await tester.pumpAndSettle();
        expect(find.textContaining('SESSION 01'), findsOneWidget);
        expect(
          find.textContaining('Sessions marked Private'),
          findsOneWidget,
        );

        // Switch to Notes & add a new consultation note
        await tester.tap(find.text('Notes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('+ Add Clinical Note'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Evening pacing experiment discussed.',
        );
        await tester.tap(find.text('Save Note'));
        await tester.pumpAndSettle();

        expect(
          find.text('Evening pacing experiment discussed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Psychiatrist UI passes accessibility guidelines & 320px Arabic RTL zero-overflow',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Verify a11y guidelines on ClinicianShellScreen
        final shellHandle = tester.ensureSemantics();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        shellHandle.dispose();

        // Verify zero-overflow on 320px + 1.35x text scale + Arabic RTL
        tester.view.physicalSize = const Size(320, 640);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.35),
                ),
                child: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ClinicianShellScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.35),
                ),
                child: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ClinicianPatientDetailScreen(
                    patientId: 'demo_karim_m',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. Minimal Settings & Insights screens preserve MindSegmented invariants without manual export or clinician clutter',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MindSegmented), findsNWidgets(2));
        expect(find.byKey(const ValueKey('me-advanced-accordion')), findsNothing);
        expect(find.text('Psychiatrist Workspace'), findsNothing);
        expect(find.text('Share with Psychiatrist'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Log out'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Log out'), findsOneWidget);

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

        final moreDetailsBtn = find.text('See more details');
        await tester.ensureVisible(moreDetailsBtn);
        await tester.tap(moreDetailsBtn);
        await tester.pumpAndSettle();
        expect(find.byType(MindSegmented), findsOneWidget);
        expect(find.text('Share with Psychiatrist'), findsNothing);
      },
    );
  });
}
