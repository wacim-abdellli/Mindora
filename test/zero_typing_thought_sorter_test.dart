import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

  group('Talk v2: Zero Clinical Clutter, Silent Pattern Tagging & Dynamic AI Options', () {
    testWidgets(
      'AI adapts automatically with contextual quick options and silently tags clinician pattern metadata without button clutter',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final freshCase = CaseModel(
          id: 'case_adaptive_v2',
          caseNumber: 'SESSION 08',
          title: 'Afternoon worry',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: '',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(caseRepositoryProvider).saveCase(freshCase);
        container
            .read(activeCaseControllerProvider.notifier)
            .resumeCase(freshCase);

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

        // Enter a worried thought — user does NOT need to choose any CBT mode
        await tester.enterText(
          find.byType(TextField),
          'My manager read my message and has not replied.',
        );
        await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // No clinical [Fact] [Guess] [Story] tag buttons clutter the user bubble
        expect(find.text('Guess'), findsNothing);
        expect(find.text('+ Tag thought'), findsNothing);
        expect(find.text('Save Takeaway'), findsNothing);

        // Yet the AI silently populated thought type + distortion theme on the user statement for the doctor view
        final saved = await container
            .read(caseRepositoryProvider)
            .getCaseById(freshCase.id);
        final userStmt = saved!.statements
            .firstWhere((s) => s.speaker == StatementSpeaker.user);
        expect(userStmt.label, equals(LabelType.assumption));
        expect(userStmt.distortionTag, equals('Mind Reading'));

        // Contextual AI-authored options appear cleanly above composer for 1-tap reply
        final firstOption = find.byKey(const ValueKey('talk-dynamic-option-0'));
        expect(firstOption, findsOneWidget);
        await tester.tap(firstOption);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final afterSecondTurn = await container
            .read(caseRepositoryProvider)
            .getCaseById(freshCase.id);
        expect(afterSecondTurn!.statements.length, greaterThan(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Active conversation with AI-chosen options fits 320px + 1.35x AR RTL without overflow',
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
              timestamp: now,
            ),
            Statement(
              id: 'stmt_ar2',
              text: 'مفهوم تماماً. خوذ نفس هادي معايا توا، ما فماش حتى ضغط.',
              speaker: StatementSpeaker.investigator,
              timestamp: now,
            ),
          ],
          suggestedReplies: const [
            'مجرد تعب من طول اليوم',
            'أعطيني خطوة خفيفة برك',
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
          find.byKey(const ValueKey('talk-dynamic-options-bar')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
