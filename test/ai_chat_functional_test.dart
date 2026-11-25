import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/companion_turn_response.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
    SecureKeyManager.resetStaticCache();
  });

  group('Talk v2 Adaptive Brain & Calm Sanctuary Lifecycle Tests', () {
    test(
      'MockInvestigatorService.getAdaptiveTurn chooses posture, options, calm offers, and silent labels autonomously',
      () async {
        final service = MockInvestigatorService();
        final now = DateTime.now();
        final baseCase = CaseModel(
          id: 'c_adapt',
          caseNumber: 'SESSION 01',
          title: 'Adaptive Check',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.incident,
          incidentDescription: '',
        );

        // 1. Acute somatic distress -> somaticGround + breathing offer
        final panicTurn = await service.getAdaptiveTurn(
          currentCase: baseCase,
          conversationHistory: [
            Statement(
              id: 'u1',
              text: 'My chest feels tight and I feel a panic coming on.',
              speaker: StatementSpeaker.user,
              timestamp: now,
            ),
          ],
          languageCode: 'en',
        );
        expect(panicTurn.chosenPosture, equals(AdaptivePosture.somaticGround));
        expect(panicTurn.offerCalmExercise, equals(CalmExerciseOffer.breathing));
        expect(panicTurn.suggestedReplies, isNotEmpty);

        // 2. Ambiguous silence -> gentleReframe + silent assumption / Mind Reading + tailored options
        final silenceTurn = await service.getAdaptiveTurn(
          currentCase: baseCase,
          conversationHistory: [
            Statement(
              id: 'u2',
              text: 'They read my message four hours ago and still did not reply.',
              speaker: StatementSpeaker.user,
              timestamp: now,
            ),
          ],
          languageCode: 'en',
        );
        expect(silenceTurn.chosenPosture, equals(AdaptivePosture.gentleReframe));
        expect(silenceTurn.offerCalmExercise, equals(CalmExerciseOffer.none));
        expect(silenceTurn.silentThoughtType, equals(LabelType.assumption));
        expect(silenceTurn.silentDistortionTheme, equals('Mind Reading'));
        expect(silenceTurn.suggestedReplies.length, inInclusiveRange(2, 3));

        // 3. Exhausted / "Just sit" -> sootheListen, no diagnostic pressure
        final tiredTurn = await service.getAdaptiveTurn(
          currentCase: baseCase,
          conversationHistory: [
            Statement(
              id: 'u3',
              text: 'اقعد معايا شوية من غير أسئلة ثقيلة، تعبان اليوم.',
              speaker: StatementSpeaker.user,
              timestamp: now,
            ),
          ],
          languageCode: 'ar',
        );
        expect(tiredTurn.chosenPosture, equals(AdaptivePosture.sootheListen));
        expect(tiredTurn.suggestedReplies, isNotEmpty);
      },
    );

    test(
      'CompanionTurnResponse parses fenced JSON, strips emojis, and deduplicates options safely',
      () {
        final parsed = CompanionTurnResponse.tryParseJson('''
```json
{
  "reply": "Take a slow breath here. 🌸 Does this tension stay in your chest?",
  "chosen_posture": "somatic_ground",
  "suggested_replies": ["My chest is tight 😊", "My chest is tight", "Just sit calmly"],
  "offer_calm_exercise": "breathing",
  "silent_thought_type": "interpretation",
  "silent_distortion_theme": "catastrophizing",
  "save_worthy_summary": "Paused to ground before spiraling."
}
```
''');
        expect(parsed, isNotNull);
        expect(parsed!.reply, isNot(contains('🌸')));
        expect(parsed.chosenPosture, equals(AdaptivePosture.somaticGround));
        expect(parsed.offerCalmExercise, equals(CalmExerciseOffer.breathing));
        expect(parsed.suggestedReplies, equals(['My chest is tight', 'Just sit calmly']));
        expect(parsed.silentThoughtType, equals(LabelType.interpretation));
        expect(parsed.silentDistortionTheme, equals('Catastrophizing'));
      },
    );

    test(
      'AiCompanionSystemPrompt.buildAdaptivePrompt embeds autonomous rules and custom directives',
      () {
        final prompt = AiCompanionSystemPrompt.buildAdaptivePrompt(
          languageCode: 'ar',
          customDirectives: 'Be extra brief and calming.',
          ageGroupHint: '65+ older adult',
        );
        expect(
          prompt,
          contains('SENIOR CLINICAL CONSULTATION ROLE & STRUCTURED DOCTOR HANDOFF'),
        );
        expect(prompt, contains('clinical_intake_note'));
        expect(prompt, contains('65+ older adult'));
        expect(prompt, contains('Be extra brief and calming.'));
        expect(prompt, contains('تحدث بلهجة تونسية دافئة'));
      },
    );

    test(
      'ActiveCaseController.sendMessageAndGenerateReply persists adaptive options, silent labels, and privacy toggle',
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
        expect(afterReply.title, contains('colleague read'));
        expect(afterReply.suggestedReplies, isNotEmpty);
        final userStmt = afterReply.statements
            .firstWhere((s) => s.speaker == StatementSpeaker.user);
        expect(userStmt.label, equals(LabelType.assumption));
        expect(userStmt.distortionTag, equals('Mind Reading'));

        await notifier.toggleCasePrivacy(afterReply.id);
        expect(
          container.read(activeCaseControllerProvider).value!.isPrivate,
          isTrue,
        );

        await notifier.bookmarkTakeaway(afterReply.statements.last.text);
        expect(
          container.read(activeCaseControllerProvider).value!.isCompleted,
          isFalse,
        );
      },
    );

    testWidgets(
      'FlashCaseScreen renders calm Talk UI, prevents duplicate empty chats, and toggles private mode in More sheet',
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
        expect(find.text('6 MODES'), findsNothing);

        // 2. Live calm chat + prevents duplicate empty Saved sessions
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const FlashCaseScreen(
                key: ValueKey('calm_live_chat'),
                initialHubView: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialCount =
            (await container.read(savedCasesProvider.future)).length;
        await tester.tap(find.byKey(const ValueKey('talk-new-chat-btn')));
        await tester.pumpAndSettle();
        final afterPlusCount =
            (await container.read(savedCasesProvider.future)).length;
        expect(afterPlusCount, equals(initialCount));
        expect(
          find.text(const AppStrings('en').alreadyFreshChatNotice),
          findsOneWidget,
        );

        // 3. More sheet allows locking conversation private cleanly (zero mode-chooser wall)
        await tester.tap(find.byKey(const ValueKey('talk-more-btn')));
        await tester.pumpAndSettle();
        expect(find.text('Modes & History'), findsNothing);
        await tester.tap(
          find.text(const AppStrings('en').talkPrivateToggleTitle),
        );
        await tester.pumpAndSettle();
        expect(
          container.read(activeCaseControllerProvider).value?.isPrivate,
          isTrue,
        );
      },
    );

    test(
      'Clinical consultation turn populates CaseModel chain, intake summary, and Doctor EHR note',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(activeCaseControllerProvider.notifier)
            .startNewCase('');
        await container
            .read(activeCaseControllerProvider.notifier)
            .sendMessageAndGenerateReply(
              'My mind keeps spinning and ruining my sleep tonight.',
            );

        final activeCase = container.read(activeCaseControllerProvider).value;
        expect(activeCase, isNotNull);
        final chain = activeCase!.chain;
        expect(chain, isNotNull);
        expect(chain!.trigger, isNotEmpty);
        expect(chain.thought, isNotEmpty);
        expect(chain.emotion, isNotEmpty);
        expect(chain.emotionIntensity, greaterThan(0));
        expect(chain.behavior, isNotEmpty);
        expect(activeCase.findingsSummary, isNotEmpty);

        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime.now();
        final packet = syncService.buildPatientPacket(
          patientDisplayName: 'Salma T.',
          patientAnonymousId: 'u_consult',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: true,
            includePersonalNotes: true,
            includeSharedCases: true,
            includeSymptomReports: true,
            includePsychologicalProfile: false,
            includePreVisitAgenda: false,
          ),
          traces: const [],
          cases: [activeCase],
          symptomReports: const [],
          referenceNow: now,
        );

        expect(packet.sharedCases.length, equals(1));
        expect(packet.sharedCases.first.findingsSummary, equals(activeCase.findingsSummary));

        final record = ClinicianPatientRecord(
          patientId: 'u_consult',
          displayName: 'Salma T.',
          importedAt: now,
          lastSyncedAt: now,
          latestPacket: packet,
        );
        final ehrNote = syncService.generateEhrClinicalNote(
          record,
          const AppStrings('en'),
        );
        expect(ehrNote, contains('Clinical intake note:'));
        expect(ehrNote, contains(activeCase.findingsSummary));
      },
    );
  });
}
