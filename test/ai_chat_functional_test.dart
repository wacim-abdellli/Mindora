import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
    SecureKeyManager.resetStaticCache();
  });

  group('AI Chat Functionality & State Lifecycle Tests', () {
    test(
      'MockInvestigatorService progresses distinctly across turns in all 6 modes and respects customDirectives',
      () async {
        final service = MockInvestigatorService();
        final now = DateTime.now();
        final baseCase = CaseModel(
          id: 'c_prog',
          caseNumber: 'SESSION 01',
          title: 'Progression Check',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: 'Feeling tense before Monday review.',
          statements: const [],
        );

        for (final mode in ConversationMode.values) {
          final replies = <String>{};
          final history = <Statement>[];
          for (var turn = 1; turn <= 4; turn++) {
            history.add(
              Statement(
                id: 'u_$turn',
                text: 'Turn $turn sharing my worry.',
                speaker: StatementSpeaker.user,
                label: LabelType.assumption,
                timestamp: now.add(Duration(minutes: turn)),
              ),
            );
            final reply = await service.getNextQuestion(
              currentCase: baseCase.copyWith(conversationMode: mode),
              conversationHistory: List.of(history),
              languageCode: 'en',
              conversationMode: mode,
            );
            expect(reply.trim(), isNotEmpty);
            replies.add(reply);
            history.add(
              Statement(
                id: 'a_$turn',
                text: reply,
                speaker: StatementSpeaker.investigator,
                timestamp: now.add(Duration(minutes: turn)),
              ),
            );
          }
          expect(
            replies.length,
            equals(4),
            reason: 'Expected 4 distinct progressive replies for mode $mode',
          );
        }

        // Arabic topic-aware + custom brief directive check
        final briefProfile = PsychologicalProfileModel(
          customAiDirectives: 'Keep replies short and direct.',
          shareWithAiCompanion: false,
          updatedAt: now,
        );
        final topicReply = await service.getNextQuestion(
          currentCase: baseCase,
          conversationHistory: [
            Statement(
              id: 'u_spark',
              text: 'نفرّق بين الحقيقة والتخمين',
              speaker: StatementSpeaker.user,
              timestamp: now,
            ),
          ],
          languageCode: 'ar',
          profile: briefProfile,
          conversationMode: ConversationMode.exploreThought,
        );
        expect(topicReply, contains('الحاجة اللي شفتها'));
      },
    );

    test(
      'AiCompanionSystemPrompt injects customDirectives cleanly without duplicating user context',
      () {
        final prompt = AiCompanionSystemPrompt.buildFullPrompt(
          mode: ConversationMode.exploreThought,
          languageCode: 'en',
          customDirectives: 'Be concise, calm, and structured.',
        );
        expect(prompt, contains('USER COMMUNICATION & TONE PREFERENCES:'));
        expect(prompt, contains('Be concise, calm, and structured.'));

        final deduplicated = AiCompanionSystemPrompt.buildFullPrompt(
          mode: ConversationMode.exploreThought,
          languageCode: 'en',
          contextualUserPrompt:
              'USER PROFILE CONTEXT:\n• Custom User Directives: "Keep it brief"',
          customDirectives: 'Keep it brief',
        );
        expect(
          deduplicated.contains('USER COMMUNICATION & TONE PREFERENCES:'),
          isFalse,
        );
      },
    );

    test(
      'ActiveCaseController.bookmarkTakeaway preserves active chat and sendMessageAndGenerateReply persists reply & backfills title',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(activeCaseControllerProvider.notifier);
        await notifier.startNewCase('');
        final proceeded = await notifier.sendMessageAndGenerateReply(
          'My colleague read my message and said nothing.',
        );
        expect(proceeded, isTrue);

        final afterReply = container.read(activeCaseControllerProvider).value!;
        expect(afterReply.incidentDescription, contains('colleague read'));
        expect(afterReply.title, contains('colleague read'));
        expect(
          afterReply.statements.any(
            (s) => s.speaker == StatementSpeaker.investigator,
          ),
          isTrue,
        );

        final aiMsg = afterReply.statements
            .lastWhere((s) => s.speaker == StatementSpeaker.investigator)
            .text;
        await notifier.bookmarkTakeaway(aiMsg);

        final afterBookmark =
            container.read(activeCaseControllerProvider).value!;
        expect(afterBookmark.findingsSummary, equals(aiMsg));
        expect(
          afterBookmark.isCompleted,
          isFalse,
          reason: 'Bookmarking a single AI reply must not close active chat',
        );
      },
    );

    testWidgets(
      'FlashCaseScreen(initialHubView: true) stays on Hub, More switches active mode, and + prevents empty duplicate sessions',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 1. Staying on Hub when initialHubView: true
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const FlashCaseScreen(initialHubView: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AiCompanionHubView), findsOneWidget);

        // 2. Live chat + prevents duplicate empty Saved sessions
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const FlashCaseScreen(
                key: ValueKey('live_chat_screen'),
                initialHubView: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialCount =
            (await container.read(savedCasesProvider.future)).length;
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        final afterPlusCount =
            (await container.read(savedCasesProvider.future)).length;
        expect(afterPlusCount, equals(initialCount));
        expect(
          find.text(const AppStrings('en').alreadyFreshChatNotice),
          findsOneWidget,
        );

        // 3. More -> Switch style updates both mode provider and active case
        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text(const AppStrings('en').modesAndHistoryTooltip));
        await tester.pumpAndSettle();
        final groundingFinder = find.text('Grounding');
        await tester.scrollUntilVisible(
          groundingFinder,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(groundingFinder);
        await tester.pumpAndSettle();

        expect(
          container.read(currentConversationModeProvider),
          equals(ConversationMode.grounding),
        );
        expect(
          container.read(activeCaseControllerProvider).value?.conversationMode,
          equals(ConversationMode.grounding),
        );
      },
    );
  });
}
