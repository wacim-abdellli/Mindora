import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const outDir = String.fromEnvironment('VQA_OUT_DIR');

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

  Future<void> capturePng(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename, {
    double pixelRatio = 2.0,
  }) async {
    if (outDir.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final outFile = File('$outDir${Platform.pathSeparator}$filename');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes);
    });
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Talk v2 Calm Adaptive Sanctuary Visual Capture', () {
    testWidgets('01 & 02 Calm Welcome + Context Bridge (Light & Dark EN)', (
      tester,
    ) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        if (isDark) {
          await container.read(mindTraceRepositoryProvider).saveTrace(
                MindTraceModel(
                  id: 'ai_vqa_trace',
                  userId: 'u1',
                  date: now,
                  overallMood: 'anxious',
                  moodIntensity: 7,
                  sleepHours: 5.5,
                  contextTags: const ['high_workload', 'late_caffeine_screens'],
                  journalText: 'Racing thoughts before tomorrow presentation.',
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          await container.read(mindTraceControllerProvider.future);
        }

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildMindTheme(isDark ? Brightness.dark : Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const FlashCaseScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await capturePng(
          tester,
          repaintKey,
          isDark ? '02_talk_welcome_dark.png' : '01_talk_welcome_light.png',
        );
      }
    });

    testWidgets('03 & 04 Uncluttered Editorial Active Chat + AI Options (Dark & Light EN)', (
      tester,
    ) async {
      for (final isDark in [true, false]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final activeCase = CaseModel(
          id: 'ai_vqa_chat',
          caseNumber: 'SESSION 03',
          title: 'Manager did not reply',
          conversationMode: ConversationMode.exploreThought,
          createdAt: now.subtract(const Duration(minutes: 10)),
          updatedAt: now,
          currentStage: CaseStage.evidence,
          incidentDescription: 'My manager has not replied since 14:00.',
          statements: [
            Statement(
              id: 's1',
              text:
                  'My manager read my message four hours ago and did not reply, so they must be upset with my report.',
              speaker: StatementSpeaker.user,
              timestamp: now.subtract(const Duration(minutes: 5)),
            ),
            Statement(
              id: 's2',
              text:
                  'Waiting in silence makes our minds race toward the scariest story. Have they ever taken hours to reply before simply because their afternoon got slammed?',
              speaker: StatementSpeaker.investigator,
              timestamp: now.subtract(const Duration(minutes: 4)),
            ),
          ],
          suggestedReplies: const [
            'Yeah, they get slammed at work',
            'Honestly today still feels personal',
            'Help me settle down first',
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(caseRepositoryProvider).saveCase(activeCase);
        container
            .read(activeCaseControllerProvider.notifier)
            .resumeCase(activeCase);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildMindTheme(isDark ? Brightness.dark : Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const FlashCaseScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await capturePng(
          tester,
          repaintKey,
          isDark
              ? '03_talk_active_chat_dark.png'
              : '04_talk_active_chat_light.png',
        );
      }
    });

    testWidgets('05 Past Talks Hub & 06 Inline Calm Breathing Offer (Dark EN)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildMindTheme(Brightness.dark),
            home: RepaintBoundary(
              key: repaintKey,
              child: const Scaffold(body: SafeArea(child: AiCompanionHubView())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturePng(tester, repaintKey, '05_talk_hub_dark.png');

      // Capture AI-triggered gentle breath offer state
      final now = DateTime.now();
      final overwhelmedCase = CaseModel(
        id: 'ai_vqa_breath',
        caseNumber: 'SESSION 04',
        title: 'Chest tightness before meeting',
        conversationMode: ConversationMode.grounding,
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: 'My chest feels tight and panicked.',
        offeredCalmExercise: 'breathing',
        suggestedReplies: const [
          'Breathing feels a little steadier',
          'Just keep it quiet for a moment',
        ],
        statements: [
          Statement(
            id: 'b1',
            text: 'My chest feels really tight right now and I cannot focus.',
            speaker: StatementSpeaker.user,
            timestamp: now.subtract(const Duration(minutes: 1)),
          ),
          Statement(
            id: 'b2',
            text:
                'This sounds genuinely heavy on your body right now. There is nothing you need to figure out this second — let us slow down together first.',
            speaker: StatementSpeaker.investigator,
            timestamp: now,
          ),
        ],
      );
      await container.read(caseRepositoryProvider).saveCase(overwhelmedCase);
      container
          .read(activeCaseControllerProvider.notifier)
          .resumeCase(overwhelmedCase);

      final breathKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildMindTheme(Brightness.dark),
            home: RepaintBoundary(
              key: breathKey,
              child: const FlashCaseScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capturePng(tester, breathKey, '06_talk_breath_offer_dark.png');
    });

    testWidgets('07 Active Chat & 08 Past Talks 320px 1.35x Arabic RTL (Light)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      final arCase = CaseModel(
        id: 'ai_vqa_ar',
        caseNumber: 'SESSION 02',
        title: 'قلق عشية',
        conversationMode: ConversationMode.exploreThought,
        currentStage: CaseStage.incident,
        createdAt: now,
        updatedAt: now,
        incidentDescription: 'حاسس روحي متقلق شوية الليلة.',
        statements: [
          Statement(
            id: 'ar_u1',
            text: 'حاسس روحي متقلق شوية الليلة ومخي يخدم برشا.',
            speaker: StatementSpeaker.user,
            timestamp: now.subtract(const Duration(minutes: 2)),
          ),
          Statement(
            id: 'ar_a1',
            text: 'باين عليك شايل حمل ثقيل الليلة. تحب نرتاحو شوية قبل أي تفكير؟',
            speaker: StatementSpeaker.investigator,
            timestamp: now.subtract(const Duration(minutes: 1)),
          ),
        ],
        suggestedReplies: const [
          'إي، نحب نهدا شوية',
          'فمّا حاجة مقلقتني نحب نحكيها',
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setLanguage(AppLanguage.arabic);
      await container.read(caseRepositoryProvider).saveCase(arCase);
      container.read(activeCaseControllerProvider.notifier).resumeCase(arCase);

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: const TextScaler.linear(1.35),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: repaintKey,
              child: const FlashCaseScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturePng(tester, repaintKey, '07_talk_active_ar_rtl_320.png');

      final hubKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: const TextScaler.linear(1.35),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: hubKey,
              child: const Scaffold(body: SafeArea(child: AiCompanionHubView())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturePng(tester, hubKey, '08_talk_hub_ar_rtl_320.png');
    });
  });
}
