import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_switch.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/domain/discovery_milestones_model.dart';
import 'package:mind_forensics/features/insights/domain/recovery_ledger_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/insights/presentation/widgets/mood_aura_poster_sheet.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrastRatio(Color a, Color b) {
  final lumA = a.computeLuminance();
  final lumB = b.computeLuminance();
  final lighter = lumA > lumB ? lumA : lumB;
  final darker = lumA > lumB ? lumB : lumA;
  return (lighter + 0.05) / (darker + 0.05);
}

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
          f.readAsBytes().then(
                (b) => ByteData.sublistView(Uint8List.fromList(b)),
              ),
        );
      }
    }
    await interLoader.load();

    final arabicLoader = FontLoader('Noto Sans Arabic');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/NotoSansArabic-$weight.ttf');
      if (f.existsSync()) {
        arabicLoader.addFont(
          f.readAsBytes().then(
                (b) => ByteData.sublistView(Uint8List.fromList(b)),
              ),
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
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
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

  List<MindTraceModel> sampleRichTraces(DateTime now) {
    final baseDay = DateTime(now.year, now.month, now.day);
    return [
      MindTraceModel(
        id: 'p7_1',
        userId: 'vqa_user',
        date: baseDay.subtract(const Duration(days: 6)).add(const Duration(hours: 9)),
        overallMood: 'heavy',
        selectedEmotions: const ['heavy', 'overwhelmed'],
        moodIntensity: 8,
        energyLevel: 4,
        anxietyLevel: 7,
        sleepHours: 5.5,
        contextTags: const ['high_workload'],
        behavioralResponse: 'Took a 15 minute quiet walk outside',
        createdAt: now,
        updatedAt: now,
      ),
      MindTraceModel(
        id: 'p7_2',
        userId: 'vqa_user',
        date: baseDay.subtract(const Duration(days: 6)).add(const Duration(hours: 20)),
        overallMood: 'calm',
        selectedEmotions: const ['calm', 'grounded'],
        moodIntensity: 3,
        energyLevel: 6,
        anxietyLevel: 2,
        sleepHours: 7.5,
        contextTags: const ['physical_movement', 'sleep_consistent'],
        behavioralResponse: 'Took a 15 minute quiet walk outside',
        createdAt: now,
        updatedAt: now,
      ),
      for (final dayOffset in [5, 4, 3, 2, 1])
        MindTraceModel(
          id: 'p7_d$dayOffset',
          userId: 'vqa_user',
          date: baseDay.subtract(Duration(days: dayOffset)).add(const Duration(hours: 11)),
          overallMood: dayOffset.isEven ? 'calm' : 'anxious',
          selectedEmotions: dayOffset.isEven
              ? const ['calm', 'hopeful']
              : const ['anxious', 'grounded'],
          moodIntensity: dayOffset.isEven ? 3 : 6,
          energyLevel: 6,
          anxietyLevel: dayOffset.isEven ? 3 : 5,
          sleepHours: 7.5,
          contextTags: const ['routine_kept'],
          createdAt: now,
          updatedAt: now,
        ),
      MindTraceModel(
        id: 'p7_today',
        userId: 'vqa_user',
        date: baseDay.add(const Duration(hours: 10)),
        overallMood: 'calm',
        selectedEmotions: const ['calm', 'content', 'hopeful'],
        moodIntensity: 3,
        energyLevel: 8,
        anxietyLevel: 2,
        sleepHours: 8.0,
        contextTags: const ['sleep_consistent', 'physical_movement'],
        journalText: 'Steady rhythm after evening stretch',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  group('Milestone 7.4: Comfort & Clarity Mode Unit & Widget Checks', () {
    test('MindTokens.withComfortBoost maintains >= 4.5:1 WCAG AA contrast and preserves grounds', () {
      final lightComfort = MindTokens.light.withComfortBoost(true);
      final darkComfort = MindTokens.dark.withComfortBoost(true);

      expect(darkComfort.bg, equals(const Color(0xFF09090B)));
      expect(darkComfort.surface, equals(const Color(0xFF111114)));
      expect(lightComfort.bg, equals(const Color(0xFFFAF9F6)));

      for (final tokens in [lightComfort, darkComfort]) {
        for (final surface in [tokens.bg, tokens.surface, tokens.surface2]) {
          expect(_contrastRatio(tokens.ink, surface), greaterThanOrEqualTo(4.5));
          expect(_contrastRatio(tokens.ink2, surface), greaterThanOrEqualTo(4.5));
          expect(_contrastRatio(tokens.ink3, surface), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('DisplayComfortController persists preference and reloads reliably', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(displayComfortProvider), isFalse);
      await container.read(displayComfortProvider.notifier).setComfortMode(true);
      expect(container.read(displayComfortProvider), isTrue);

      final reloaded = await DisplayComfortController.loadInitial();
      expect(reloaded, isTrue);

      final secondContainer = ProviderContainer(
        overrides: [initialComfortModeProvider.overrideWithValue(reloaded)],
      );
      addTearDown(secondContainer.dispose);
      expect(secondContainer.read(displayComfortProvider), isTrue);
    });

    testWidgets(
      'MindForensicsApp scales +15% in Comfort Mode while remaining inside [8.5, 13.5] bounds',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MindForensicsApp(),
          ),
        );
        await tester.pumpAndSettle();

        final ctxOff = tester.element(find.text('Today'));
        expect(MediaQuery.textScalerOf(ctxOff).scale(10.0), closeTo(10.0, 0.05));

        await container.read(displayComfortProvider.notifier).setComfortMode(true);
        await tester.pumpAndSettle();

        final ctxOn = tester.element(find.text('Today'));
        final scaled = MediaQuery.textScalerOf(ctxOn).scale(10.0);
        expect(scaled, closeTo(11.5, 0.05));
        expect(scaled, inInclusiveRange(8.5, 13.5));

        // Even with extreme OS scale 3.0x, app clamp caps safely at 1.35x (13.5)
        tester.platformDispatcher.textScaleFactorTestValue = 3.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        final ctxClamped = tester.element(find.text('Today'));
        expect(
          MediaQuery.textScalerOf(ctxClamped).scale(10.0),
          inInclusiveRange(8.5, 13.5),
        );
      },
    );

    testWidgets(
      'Onboarding Step 0 & Settings Group 2 toggle Comfort Mode in 1 tap without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final onboardingToggle = find.byKey(
          const ValueKey('onboarding-comfort-mode-toggle'),
        );
        expect(onboardingToggle, findsOneWidget);
        await tester.tap(onboardingToggle);
        await tester.pumpAndSettle();
        expect(container.read(displayComfortProvider), isTrue);
        expect(tester.takeException(), isNull);

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

        const enStrings = AppStrings('en');
        expect(find.text(enStrings.comfortModeTitle), findsOneWidget);
        await tester.ensureVisible(find.text(enStrings.comfortModeTitle));
        await tester.tap(find.byType(MindSwitch).first);
        await tester.pumpAndSettle();
        expect(container.read(displayComfortProvider), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Phase 7 Visual Quality Assurance Showcase (5 Real-Font Captures)', () {
    testWidgets(
      '1. Home Check-In & Clinical Daily Pulse (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p7_vqa_1'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const HomeScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MoodFace), findsWidgets);

        await capturePng(
          tester,
          repaintKey,
          '01_home_orb_sparks_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '2. TrackScreen Vivid Month Calendar & + Log new moment Sheet (412x1050 Dawn Light EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 2100);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p7_vqa_2'),
              theme: buildMindTheme(Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const Scaffold(body: TrackScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text(const AppStrings('en').logNewMomentLink),
        );
        await tester.tap(find.text(const AppStrings('en').logNewMomentLink));
        await tester.pumpAndSettle();

        await capturePng(
          tester,
          repaintKey,
          '02_track_tactile_steppers_light.png',
          2.0,
        );
      },
    );

    testWidgets(
      '3. Discovery Milestones Card 5/5 Unlocked on Insights (412x980 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1960);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final sampleCase = CaseModel(
          id: 'p7_case',
          caseNumber: 'CASE-07',
          title: 'Evening decompression experiment',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Stepped away from screens after 20:00',
          isPrivate: false,
        );
        final container = ProviderContainer(
          overrides: [
            savedCasesProvider.overrideWith((ref) async => [sampleCase]),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(mindTraceRepositoryProvider);
        for (final t in sampleRichTraces(now)) {
          await repo.saveTrace(t);
        }
        await container.read(mindTraceControllerProvider.future);
        await container.read(savedCasesProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p7_vqa_3'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: const InsightsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        final moreBtn = find.byKey(
          const ValueKey<String>('patterns-more-details-btn'),
        );
        await tester.ensureVisible(moreBtn);
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text(enStrings.discoveryMilestonesTitle),
          300,
          scrollable: scrollable,
        );
        await tester.ensureVisible(find.text(enStrings.openMoodAuraBtn));
        await tester.ensureVisible(find.text(enStrings.discoveryMilestonesTitle));
        await tester.pumpAndSettle();

        expect(find.text(enStrings.discoveryMilestonesTitle), findsOneWidget);
        expect(find.text(enStrings.openMoodAuraBtn), findsOneWidget);

        await capturePng(
          tester,
          repaintKey,
          '03_discovery_milestones_history_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '4. Generative 1080x1350 Mood Aura Poster Sheet (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime(2026, 11, 24, 18, 30);
        final traces = sampleRichTraces(now);
        const enStrings = AppStrings('en');
        final summary = DiscoveryMilestonesService.compute(
          traces: traces,
          ledger: RecoveryLedger.fromTraces(traces),
          strings: enStrings,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p7_vqa_4'),
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: Scaffold(
                  backgroundColor: MindTokens.dark.scrim,
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: MoodAuraPosterSheet(
                      traces: traces,
                      summary: summary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < 120; i++) {
          final spinners = find.byType(CircularProgressIndicator).evaluate();
          final rawImages = find.byType(RawImage).evaluate();
          if (spinners.isEmpty &&
              rawImages.isNotEmpty &&
              (rawImages.first.widget as RawImage).image != null) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        await capturePng(
          tester,
          repaintKey,
          '04_generative_mood_aura_poster_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '5. Comfort & Clarity Mode ON (+15% & Boosted Contrast) 320px Arabic RTL Dawn Light',
      (tester) async {
        tester.view.physicalSize = const Size(640, 1840);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final container = ProviderContainer(
          overrides: [initialComfortModeProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);

        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        final repo = container.read(mindTraceRepositoryProvider);
        for (final t in sampleRichTraces(now)) {
          await repo.saveTrace(t);
        }
        await container.read(mindTraceControllerProvider.future);

        final comfortTokens = MindTokens.light.withComfortBoost(true);
        final repaintKey = GlobalKey();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p7_vqa_5'),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildMindTheme(
                Brightness.light,
                tokensOverride: comfortTokens,
                isArabic: true,
              ),
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: const TextScaler.linear(1.15),
                  ),
                  child: child!,
                );
              },
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
          '05_comfort_mode_ar_rtl_320_light.png',
          2.0,
        );
      },
    );
  });
}
