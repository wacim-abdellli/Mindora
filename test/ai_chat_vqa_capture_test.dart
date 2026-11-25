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
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/mode_chooser_sheet.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const outDir =
      r'C:\Users\pc\.gemini\antigravity\brain\a4ea709b-c435-4760-9e37-1f5a1d16d793\screenshots\ai_chat_after';

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

  group('AI Chat Pre-Fix Visual Capture', () {
    testWidgets('01 & 02 Welcome + Context Bridge (Light & Dark EN)', (
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

    testWidgets('03 & 04 Active Multi-Turn Chat (Dark & Light EN)', (
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
              label: LabelType.assumption,
              distortionTag: 'Mind Reading',
              timestamp: now.subtract(const Duration(minutes: 5)),
            ),
            Statement(
              id: 's2',
              text:
                  'That uncertainty can feel sharp in your chest. Before we test that worry, what concrete fact do we know for sure right now versus what your mind is filling in?',
              speaker: StatementSpeaker.investigator,
              timestamp: now.subtract(const Duration(minutes: 4)),
            ),
            Statement(
              id: 's3',
              text:
                  'The fact is they saw the message at 14:00 and stayed silent. The guess is that my work was bad.',
              speaker: StatementSpeaker.user,
              label: LabelType.fact,
              timestamp: now.subtract(const Duration(minutes: 2)),
            ),
            Statement(
              id: 's4',
              text:
                  'Separating the read receipt from the fear takes real steadiness. Could there be another ordinary reason a manager has not answered in four hours?',
              speaker: StatementSpeaker.investigator,
              timestamp: now.subtract(const Duration(minutes: 1)),
            ),
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

    testWidgets('05 Hub View & 06 Mode Chooser Sheet (Dark EN) — Zero Overflow', (
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

      // Capture ModeChooserSheet standalone
      final sheetKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildMindTheme(Brightness.dark),
            home: RepaintBoundary(
              key: sheetKey,
              child: Scaffold(
                backgroundColor: MindTokens.dark.scrim,
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: ModeChooserSheet(
                    activeMode: ConversationMode.exploreThought,
                    onModeSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capturePng(tester, sheetKey, '06_talk_mode_chooser_dark.png');
    });

    testWidgets('08 Hub View 320px 1.35x Arabic RTL (Light) — Zero Overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setLanguage(AppLanguage.arabic);

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
              child: const Scaffold(body: SafeArea(child: AiCompanionHubView())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturePng(tester, repaintKey, '08_talk_hub_ar_rtl_320.png');
    });

    testWidgets('07 Active Chat Narrow 320px 1.35x Arabic RTL (Light)', (
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
        currentStage: CaseStage.incident,
        conversationMode: ConversationMode.exploreThought,
        createdAt: now,
        updatedAt: now,
        incidentDescription: 'حاسس روحي متقلق شوية الليلة.',
        statements: [
          Statement(
            id: 'ar_u1',
            text: 'حاسس روحي متقلق شوية الليلة ومخي يخدم برشا.',
            speaker: StatementSpeaker.user,
            label: LabelType.assumption,
            timestamp: now.subtract(const Duration(minutes: 2)),
          ),
          Statement(
            id: 'ar_a1',
            text:
                'باين عليه حمل ثقيل. شنوة اللي صار بالضبط قبل ما بدا القلق هذا؟',
            speaker: StatementSpeaker.investigator,
            timestamp: now.subtract(const Duration(minutes: 1)),
          ),
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
    });
  });
}
