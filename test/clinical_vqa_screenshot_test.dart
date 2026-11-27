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
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
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

  group('Phase 4 Visual Quality Assurance Suite (7 Clinical Matrix Views)', () {
    testWidgets(
      '1. Patient Home + Post-Visit Focus Plan (Mobile 412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        final repo = container.read(mindTraceRepositoryProvider);
        await repo.saveTrace(
          MindTraceModel(
            id: 'vqa_home_today',
            userId: 'vqa_user',
            date: now,
            overallMood: 'heavy',
            selectedEmotions: const ['heavy', 'exhausted', 'overwhelmed'],
            moodIntensity: 7,
            energyLevel: 4,
            anxietyLevel: 6,
            sleepHours: 5.5,
            contextTags: const ['high_workload', 'late_caffeine_screens'],
            createdAt: now,
            updatedAt: now,
          ),
        );
        await container.read(mindTraceControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.notifier).savePlan(
              PostVisitFocusPlan(
                planId: 'plan_vqa_1',
                clinicianName: 'Dr. Amira Ben Salem',
                clinicName: 'Tunis Behavioral Clinic',
                createdAt: now.subtract(const Duration(days: 2)),
                followUpDate: now.add(const Duration(days: 10)),
                focusItems: const [
                  FocusGoalItem(
                    id: 'g1',
                    title: 'Keep sleep & wake window consistent before midnight',
                    isCompleted: true,
                  ),
                  FocusGoalItem(
                    id: 'g2',
                    title: 'Log evening energy & context tags twice before follow-up',
                  ),
                ],
                observationCue:
                    'Notice evening tension triggers before 22:00',
              ),
            );

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const HomeScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '01_patient_home_post_visit_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '2. Patient Track Nuanced Affect + Context Tags (Mobile 412x915 Light EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        final todayTrace = MindTraceModel(
          id: 'vqa_track_today',
          userId: 'vqa_user',
          date: now,
          overallMood: 'heavy',
          selectedEmotions: const ['heavy', 'exhausted'],
          moodIntensity: 6,
          energyLevel: 5,
          anxietyLevel: 5,
          sleepHours: 7.0,
          contextTags: const ['sleep_consistent', 'physical_movement'],
          createdAt: now,
          updatedAt: now,
        );
        final repo = container.read(mindTraceRepositoryProvider);
        await repo.saveTrace(todayTrace);
        await container.read(mindTraceControllerProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const TrackScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        // Open today's entry detail -> Edit -> Card 3 Context Tags
        await tester.ensureVisible(find.text(enStrings.plainMoodLabel('heavy')));
        await tester.tap(find.text(enStrings.plainMoodLabel('heavy')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(enStrings.editEntryBtn));
        await tester.tap(find.text(enStrings.editEntryBtn));
        await tester.pumpAndSettle();

        await tester.tap(find.text(enStrings.skipBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.text(enStrings.skipBtn));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Physical movement'));
        await tester.pumpAndSettle();

        expect(find.byType(ProgressiveDetailsSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '02_patient_track_nuanced_context_light.png',
          2.0,
        );
      },
    );

    testWidgets(
      '3. Patient Insights Affect Spectrum & Context Correlations (Mobile 412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final baseDay = DateTime.now();
        final repo = container.read(mindTraceRepositoryProvider);
        final samples = <MindTraceModel>[
          MindTraceModel(
            id: 'vqa_i1',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day, 9, 0),
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'grounded'],
            moodIntensity: 4,
            energyLevel: 7,
            anxietyLevel: 2,
            sleepHours: 7.5,
            contextTags: const ['sleep_consistent', 'physical_movement'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'vqa_i2',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day, 20, 30),
            overallMood: 'anxious',
            selectedEmotions: const ['anxious', 'overwhelmed'],
            moodIntensity: 7,
            energyLevel: 4,
            anxietyLevel: 7,
            sleepHours: 6.0,
            contextTags: const ['high_workload', 'late_caffeine_screens'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'vqa_i3',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 1, 9, 15),
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'hopeful'],
            moodIntensity: 4,
            energyLevel: 8,
            anxietyLevel: 3,
            sleepHours: 8.0,
            contextTags: const ['sleep_consistent', 'physical_movement'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'vqa_i4',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 1, 21, 0),
            overallMood: 'heavy',
            selectedEmotions: const ['heavy', 'drained'],
            moodIntensity: 8,
            energyLevel: 3,
            anxietyLevel: 6,
            sleepHours: 5.5,
            contextTags: const ['high_workload'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'vqa_i5',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 2, 10, 0),
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'content'],
            moodIntensity: 3,
            energyLevel: 8,
            anxietyLevel: 2,
            sleepHours: 7.5,
            contextTags: const ['sleep_consistent', 'routine_kept'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
          MindTraceModel(
            id: 'vqa_i6',
            userId: 'vqa_user',
            date: DateTime(baseDay.year, baseDay.month, baseDay.day - 2, 19, 45),
            overallMood: 'restless',
            selectedEmotions: const ['restless', 'agitated'],
            moodIntensity: 6,
            energyLevel: 5,
            anxietyLevel: 6,
            sleepHours: 6.5,
            contextTags: const ['late_caffeine_screens'],
            createdAt: baseDay,
            updatedAt: baseDay,
          ),
        ];
        for (final trace in samples) {
          await repo.saveTrace(trace);
        }
        await container.read(mindTraceControllerProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
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
          find.text('DAILY CONTEXT & ROUTINE LINKS'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '03_patient_insights_correlations_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '4. Clinician Patient Roster Mobile (412x915 Dark EN)',
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
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const ClinicianShellScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '04_clinician_roster_mobile_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '5. Clinician Dossier Mobile Overview & Correlations (412x915 Light EN)',
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
          find.text('DAILY CONTEXT & ROUTINE LINKS'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '05_clinician_dossier_mobile_light.png',
          2.0,
        );
      },
    );

    testWidgets(
      '6. Clinician Adaptive Tablet Split-Pane (1180x820 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(1770, 1230);
        tester.view.devicePixelRatio = 1.5;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(clinicianRosterProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const ClinicianShellScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '06_clinician_tablet_split_dark.png',
          1.5,
        );
      },
    );

    testWidgets(
      '7. Clinician Dossier Narrow 320px + 1.35x Text + Arabic RTL (Dark)',
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
          find.text(arStrings.dailyContextSectionTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '07_clinician_dossier_320_ar_rtl_dark.png',
          2.0,
        );
      },
    );
  });
}
