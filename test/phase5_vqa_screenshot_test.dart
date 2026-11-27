import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/clinical_brief_preview_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/pre_visit_brief_sheet.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const vqaOutDir = String.fromEnvironment('VQA_OUT_DIR');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    final interLoader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/Inter-$weight.ttf');
      if (f.existsSync()) {
        interLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await interLoader.load();

    final arabicLoader = FontLoader('Noto Sans Arabic');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/NotoSansArabic-$weight.ttf');
      if (f.existsSync()) {
        arabicLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await arabicLoader.load();

    final iconFile = File('assets/fonts/MaterialIcons-Regular.otf');
    if (iconFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(
        iconFile
            .readAsBytes()
            .then((b) => ByteData.sublistView(Uint8List.fromList(b))),
      );
      await iconLoader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
  });

  Future<void> capturePng(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename,
    double pixelRatio,
  ) async {
    if (vqaOutDir.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final outFile = File('$vqaOutDir${Platform.pathSeparator}$filename');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(pngBytes);
    });
  }

  List<MindTraceModel> sampleRecoveryTraces(DateTime now) => [
        MindTraceModel(
          id: 'p5_1',
          userId: 'vqa_user',
          date: DateTime(now.year, now.month, now.day - 2, 20, 30),
          overallMood: 'heavy',
          selectedEmotions: const ['heavy', 'overwhelmed'],
          moodIntensity: 8,
          energyLevel: 3,
          anxietyLevel: 7,
          sleepHours: 5.5,
          contextTags: const ['high_workload', 'late_caffeine_screens'],
          behavioralResponse: 'Took a 15 minute evening walk outside',
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'p5_2',
          userId: 'vqa_user',
          date: DateTime(now.year, now.month, now.day - 2, 22, 45),
          overallMood: 'calm',
          selectedEmotions: const ['calm', 'grounded'],
          moodIntensity: 4,
          energyLevel: 5,
          anxietyLevel: 3,
          sleepHours: 7.5,
          contextTags: const ['sleep_consistent', 'physical_movement'],
          behavioralResponse: 'Quiet time and slow breathing',
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'p5_3',
          userId: 'vqa_user',
          date: DateTime(now.year, now.month, now.day - 1, 21, 0),
          overallMood: 'anxious',
          selectedEmotions: const ['anxious', 'overwhelmed'],
          moodIntensity: 7,
          energyLevel: 4,
          anxietyLevel: 7,
          sleepHours: 6.0,
          contextTags: const ['high_workload'],
          behavioralResponse: 'Took a 15 minute evening walk outside',
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'p5_4',
          userId: 'vqa_user',
          date: DateTime(now.year, now.month, now.day - 1, 23, 0),
          overallMood: 'calm',
          selectedEmotions: const ['calm'],
          moodIntensity: 3,
          energyLevel: 6,
          anxietyLevel: 2,
          sleepHours: 8.0,
          contextTags: const ['sleep_consistent', 'physical_movement'],
          behavioralResponse: 'Quiet time and slow breathing',
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'p5_5',
          userId: 'vqa_user',
          date: DateTime(now.year, now.month, now.day, 10, 0),
          overallMood: 'calm',
          selectedEmotions: const ['grounded', 'hopeful'],
          moodIntensity: 3,
          energyLevel: 8,
          anxietyLevel: 2,
          sleepHours: 7.5,
          contextTags: const ['sleep_consistent', 'routine_kept'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

  group('Phase 5 Visual Quality Assurance Suite (5 Clinical Differentiators)', () {
    testWidgets(
      '1. Patient Insights Observed Stabilizers & Forensic Loop Map (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final sampleCase = CaseModel(
          id: 'vqa_p5_case',
          caseNumber: 'CASE-04',
          title: 'Evening workload pressure',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Late message from work after 20:00',
          chain: const ForensicChain(
            trigger: 'Late message after 20:00',
            thought: 'If I pause now, everything will fall behind tomorrow.',
            thoughtLabel: LabelType.assumption,
            emotion: 'Overwhelmed',
            emotionIntensity: 7,
            behavior: 'Checked inbox repeatedly until midnight',
          ),
          isPrivate: false,
        );

        final container = ProviderContainer(
          overrides: [
            savedCasesProvider.overrideWith((ref) async => [sampleCase]),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(mindTraceRepositoryProvider);
        for (final t in sampleRecoveryTraces(now)) {
          await repo.saveTrace(t);
        }
        await container.read(mindTraceControllerProvider.future);
        await container.read(savedCasesProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p5_vqa_1'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const InsightsScreen(),
              ),
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
          find.text(const AppStrings('en').forensicLoopMapTitle),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '01_patient_insights_recovery_loop_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '2. Patient 2-Minute Pre-Visit Brief Sheet (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(mindTraceRepositoryProvider);
        for (final t in sampleRecoveryTraces(now)) {
          await repo.saveTrace(t);
        }
        await container.read(mindTraceControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.notifier).savePlan(
              PostVisitFocusPlan(
                planId: 'plan_p5_brief',
                clinicianName: 'Dr. Amira Ben Salem',
                clinicName: 'Tunis Behavioral Clinic',
                createdAt: now.subtract(const Duration(days: 7)),
                followUpDate: now.add(const Duration(days: 7)),
                focusItems: const [
                  FocusGoalItem(
                    id: 'g1',
                    title: 'Protect a screen-free wind-down buffer after 22:00',
                    isCompleted: true,
                  ),
                  FocusGoalItem(
                    id: 'g2',
                    title: 'Note evening energy shifts when workload rises',
                  ),
                ],
                observationCue:
                    'Observe whether short outdoor walks lower evening intensity',
              ),
            );

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p5_vqa_2'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const Scaffold(body: PreVisitBriefSheet()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        if (find.text(enStrings.preVisitTopicSleep).evaluate().isNotEmpty) {
          await tester.tap(find.text(enStrings.preVisitTopicSleep));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '02_pre_visit_brief_sheet_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '3. Clinician Dossier Visit Diff + Forensic Loop Map (412x915 Light EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(clinicianRosterProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p5_vqa_3'),
              theme: buildMindTheme(Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const ClinicianPatientDetailScreen(
                  patientId: 'demo_nadia_b',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text(const AppStrings('en').forensicLoopMapTitle),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '03_clinician_dossier_diff_loop_light.png',
          2.0,
        );
      },
    );

    testWidgets(
      '4. Printable A4 Consultation Brief + Embedded QR (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(syncService),
          ],
        );
        addTearDown(container.dispose);

        final now = DateTime(2026, 11, 22, 11, 0);
        final nadia = DemoClinicalCohort.buildRecords(referenceNow: now).first;
        final carePlan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Amira Ben Salem',
          focusTitles: const [
            'Protect 22:00 wind-down buffer',
            'Log evening intensity & context tags',
          ],
          referenceNow: now,
        );
        final encryptedCode = await syncService.encryptCarePlanToCode(
          carePlan,
          'room-pin-26',
          pbkdf2Iterations: 2000,
        );

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p5_vqa_4'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: Scaffold(
                  body: ClinicalBriefPreviewSheet(
                    record: nadia,
                    encryptedCode: encryptedCode,
                  ),
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < 40; i++) {
          final rawImages = find.byType(RawImage).evaluate();
          if (rawImages.isNotEmpty &&
              (rawImages.first.widget as RawImage).image != null) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '04_clinical_a4_brief_preview_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '5. Forensic Loop Map Narrow 320px + 1.35x Text + Arabic RTL (Dark)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(clinicianRosterProvider.future);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p5_vqa_5'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: const ClinicianPatientDetailScreen(
                        patientId: 'demo_nadia_b',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const arStrings = AppStrings('ar');
        await tester.scrollUntilVisible(
          find.text(arStrings.forensicLoopMapTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '05_forensic_loop_320_ar_rtl_dark.png',
          2.0,
        );
      },
    );
  });
}
