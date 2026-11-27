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
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/case_file/domain/clarity_anchor_model.dart';
import 'package:mind_forensics/features/case_file/presentation/case_report_screen.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/support/presentation/widgets/grounding_exercise_card.dart';
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

  group('Milestone 8.4: Pocket Clarity Anchor Unit & Widget Checks', () {
    test('ClarityAnchorModel extracts 3 pillars and honors excludePrivate vault isolation', () {
      final now = DateTime(2026, 11, 24, 10, 0);
      final shareable = CaseModel(
        id: 'c_public',
        caseNumber: 'SESSION 10',
        title: 'Delayed team reply',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'No reply for 3 hours.',
        statements: [
          Statement(
            id: 's1',
            text: 'My message has no reply yet after 3 hours.',
            speaker: StatementSpeaker.user,
            label: LabelType.fact,
            timestamp: now,
          ),
          Statement(
            id: 's2',
            text: 'They must be frustrated with my work.',
            speaker: StatementSpeaker.user,
            label: LabelType.assumption,
            timestamp: now,
          ),
        ],
        userConclusion: 'Silence during a busy morning is not negative feedback.',
        isPrivate: false,
      );

      final privateCase = shareable.copyWith(
        id: 'c_private',
        title: 'Private journal',
        isPrivate: true,
      );

      final emptyDraft = CaseModel(
        id: 'c_empty',
        caseNumber: 'SESSION 11',
        title: 'Draft',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: '',
      );

      final anchor = ClarityAnchorModel.fromCase(shareable);
      expect(anchor, isNotNull);
      expect(anchor!.observedFact, contains('3 hours'));
      expect(anchor.mindsJump, contains('frustrated'));
      expect(anchor.groundedPerspective, contains('Silence'));
      expect(ClarityAnchorModel.fromCase(emptyDraft), isNull);

      final allAnchors = ClarityAnchorModel.fromCases([shareable, privateCase]);
      expect(allAnchors.length, equals(2));

      final safeAnchors = ClarityAnchorModel.fromCases(
        [shareable, privateCase],
        excludePrivate: true,
      );
      expect(safeAnchors.length, equals(1));
      expect(safeAnchors.first.caseId, equals('c_public'));
    });

    testWidgets(
      'CaseReportScreen and AiCompanionHubView keep views clean with Pocket Clarity Anchors removed',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final c = CaseModel(
          id: 'case_anchor_ui',
          caseNumber: 'SESSION 12',
          title: 'Evening rumination check',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Felt drained after 19:00.',
          chain: const ForensicChain(
            trigger: 'Received two urgent emails at 19:00',
            thought: 'If I rest now, I will fall behind all week.',
            thoughtLabel: LabelType.assumption,
            emotion: 'Anxious',
            emotionIntensity: 7,
            behavior: 'Kept refreshing inbox',
          ),
          userConclusion: 'Rested work tomorrow beats exhausted work tonight.',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(caseRepositoryProvider).saveCase(c);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: CaseReportScreen(caseId: c.id),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('clarity-anchor-card-case_anchor_ui')),
          findsNothing,
        );
        expect(
          find.text('Rested work tomorrow beats exhausted work tonight.'),
          findsAtLeastNWidgets(1),
        );

        // Verify AiCompanionHubView stays clean without Pocket Clarity Anchors strip
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: AiCompanionHubView()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        expect(
          find.text(enStrings.pocketAnchorsSectionTitle.toUpperCase()),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('clarity-anchor-card-case_anchor_ui')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Phase 8 Visual Quality Assurance Showcase (4 Real-Font Captures)', () {
    testWidgets(
      '1. Companion Context Bridge Card above the fold (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'vqa_8_trace',
                date: now,
                overallMood: 'anxious',
                moodIntensity: 8,
                contextTags: const ['high_workload', 'late_caffeine_screens'],
                journalText: 'Tight chest thinking about tomorrow morning review',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container.read(postVisitFocusControllerProvider.notifier).savePlan(
              PostVisitFocusPlan(
                planId: 'vqa_8_plan',
                clinicianName: 'Dr. Amira',
                createdAt: now,
                focusItems: const [
                  FocusGoalItem(
                    id: 'fg1',
                    title: 'Take a 10-minute screen pause before 21:00',
                  ),
                ],
              ),
            );
        await container.read(mindTraceControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.future);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p8_vqa_1'),
              theme: buildMindTheme(Brightness.dark),
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
          '01_companion_context_bridge_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '2. Companion Zero-Typing 3-Pill Thought Sorter & Reply Sparks (412x915 Dark EN)',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final seeded = CaseModel(
          id: 'vqa_8_sorter',
          caseNumber: 'SESSION 14',
          title: 'Untangling presentation stress',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: 'Manager did not answer my draft message.',
          statements: [
            Statement(
              id: 'u1',
              text: 'My manager has not replied to my draft message since 14:00.',
              speaker: StatementSpeaker.user,
              label: LabelType.fact,
              timestamp: now,
            ),
            Statement(
              id: 'a1',
              text:
                  'That is a clear observable fact. What story or worry popped up right after you noticed the silence?',
              speaker: StatementSpeaker.investigator,
              timestamp: now,
            ),
            Statement(
              id: 'u2',
              text: 'They must think the whole proposal is weak and off track.',
              speaker: StatementSpeaker.user,
              label: LabelType.assumption,
              timestamp: now,
            ),
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(caseRepositoryProvider).saveCase(seeded);
        container
            .read(activeCaseControllerProvider.notifier)
            .resumeCase(seeded);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p8_vqa_2'),
              theme: buildMindTheme(Brightness.dark),
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
          '02_companion_thought_sorter_sparks_dark.png',
          2.0,
        );
      },
    );

    testWidgets(
      '3. Closed-Loop Relief Micro-Check after 5-4-3-2-1 Grounding (412x915 Dawn Light EN)',
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
              key: const ValueKey('p8_vqa_3'),
              theme: buildMindTheme(Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GroundingExerciseCard(
                        onSwitchToBreathing: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('Noticed • Next Step'));
          await tester.pumpAndSettle();
        }

        await capturePng(
          tester,
          repaintKey,
          '03_support_relief_micro_check_light.png',
          2.0,
        );
      },
    );

    testWidgets(
      '4. Pocket Clarity Anchor Card on CaseReportScreen (320x820 Dark Arabic RTL)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 1640);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime(2026, 11, 24, 18, 0);
        final arCase = CaseModel(
          id: 'vqa_8_ar_anchor',
          caseNumber: 'SESSION 15',
          title: 'تخفيف ضغط المساء',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'وصلتني رسالة متأخرة من الخدمة بعد 20:00.',
          statements: [
            Statement(
              id: 'arf1',
              text: 'وصلتني رسالة خدمة الساعة الثامنة مساءً بدون طلب رد فوري.',
              speaker: StatementSpeaker.user,
              label: LabelType.fact,
              timestamp: now,
            ),
            Statement(
              id: 'ara1',
              text: 'كان ما نردّش الليلة باش يظنّو اللي أنا مقصّر.',
              speaker: StatementSpeaker.user,
              label: LabelType.assumption,
              timestamp: now,
            ),
          ],
          userConclusion: 'الردّ غدوة الصباح وأنا مرتاح خير وأدقّ من التوتّر الليلة.',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);
        await container.read(caseRepositoryProvider).saveCase(arCase);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('p8_vqa_4'),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildMindTheme(Brightness.dark, isArabic: true),
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(textScaler: const TextScaler.linear(1.15)),
                  child: child!,
                );
              },
              home: RepaintBoundary(
                key: repaintKey,
                child: CaseReportScreen(caseId: arCase.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await capturePng(
          tester,
          repaintKey,
          '04_clarity_anchor_card_ar_rtl_320_dark.png',
          2.0,
        );
      },
    );
  });
}
