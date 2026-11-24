import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 8.2: Zero-Typing Thought Sorter & Context-Aware Reply Sparks', () {
    testWidgets(
      'User statement bubble supports direct 1-tap Fact/Assumption/Interpretation switching and adaptive reply sparks',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final seededCase = CaseModel(
          id: 'case_sorter_8_2',
          caseNumber: 'SESSION 08',
          title: 'Presentation worry',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: 'My manager did not reply yet.',
          statements: [
            Statement(
              id: 'stmt_u1',
              text: 'My manager did not reply, so they must be upset with me.',
              speaker: StatementSpeaker.user,
              label: LabelType.assumption,
              timestamp: now,
            ),
            Statement(
              id: 'stmt_ai1',
              text: 'What part of that is directly observable right now?',
              speaker: StatementSpeaker.investigator,
              timestamp: now,
            ),
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(caseRepositoryProvider).saveCase(seededCase);
        container
            .read(activeCaseControllerProvider.notifier)
            .resumeCase(seededCase);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const FlashCaseScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Direct 3-pill sorter exists on the user bubble
        final factPill = find.byKey(const ValueKey('stmt-label-stmt_u1-fact'));
        final assumptionPill =
            find.byKey(const ValueKey('stmt-label-stmt_u1-assumption'));
        final interpPill =
            find.byKey(const ValueKey('stmt-label-stmt_u1-interpretation'));

        expect(factPill, findsOneWidget);
        expect(assumptionPill, findsOneWidget);
        expect(interpPill, findsOneWidget);

        // Before tagging a Fact, "Separate the observable fact" spark is highlighted
        expect(
          find.byKey(const ValueKey('reply-spark-find-fact')),
          findsOneWidget,
        );

        // 1-tap switch directly from Assumption -> Fact
        await tester.tap(factPill);
        await tester.pumpAndSettle();

        final afterFact =
            await container.read(caseRepositoryProvider).getCaseById(seededCase.id);
        expect(afterFact?.statements.first.label, equals(LabelType.fact));

        // Now that a Fact is tagged, "Separate the observable fact" steps aside cleanly
        expect(
          find.byKey(const ValueKey('reply-spark-find-fact')),
          findsNothing,
        );

        // Re-tapping Fact clears the label cleanly
        await tester.tap(factPill);
        await tester.pumpAndSettle();
        final afterClear =
            await container.read(caseRepositoryProvider).getCaseById(seededCase.id);
        expect(afterClear?.statements.first.label, isNull);

        // Tap 1-tap continuation reply spark ("Show another calm angle") without typing
        final angleSpark = find.byKey(const ValueKey('reply-spark-other-angle'));
        expect(angleSpark, findsOneWidget);
        await tester.ensureVisible(angleSpark);
        await tester.pumpAndSettle();
        await tester.tap(angleSpark);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        expect(find.text(enStrings.companionSparkOtherAngle), findsWidgets);
        final afterSend =
            await container.read(caseRepositoryProvider).getCaseById(seededCase.id);
        expect(afterSend?.statements.length, greaterThan(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Active conversation with 3-pill sorter and reply sparks fits 320px + 1.35x AR RTL without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final seededCase = CaseModel(
          id: 'case_ar_8_2',
          caseNumber: 'SESSION 09',
          title: 'تفكير مسائي',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: 'حاسس روحي مضغوط برشا خاطر ما كملتش كل شي اليوم.',
          statements: [
            Statement(
              id: 'stmt_ar1',
              text: 'حاسس روحي مضغوط برشا خاطر ما كملتش كل شي اليوم.',
              speaker: StatementSpeaker.user,
              label: LabelType.interpretation,
              timestamp: now,
            ),
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);
        await container.read(caseRepositoryProvider).saveCase(seededCase);
        container
            .read(activeCaseControllerProvider.notifier)
            .resumeCase(seededCase);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light, isArabic: true),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 720),
                    textScaler: TextScaler.linear(1.35),
                  ),
                  child: const FlashCaseScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('stmt-label-stmt_ar1-fact')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('companion-reply-sparks-bar')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
