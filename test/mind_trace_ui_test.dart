import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/daily_mind_trace_stepper.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/thought_trace_detail_sheet.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/trace_investigation_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Daily Mind Trace & The Thought Trace UI Tests', () {
    testWidgets('DailyMindTraceStepper renders opening poetic quote and 4-step options-first wizard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailyMindTraceStepper(
                onViewConstellation: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check opening header & step indicator
      expect(find.text('1. How Are You Feeling?'), findsOneWidget);
      expect(find.text('Step 1/4'), findsOneWidget);

      // Check 14-emotion library cards (Step 1)
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Overwhelmed'), findsOneWidget);
      expect(find.text('Custom emotion'), findsOneWidget);

      // Step navigation: select emotion and tap Continue
      await tester.tap(find.text('Calm'));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Intensity scale (1-10)
      expect(find.text('2. Emotional Intensity'), findsOneWidget);
      expect(find.text('/ 10'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Mind check
      expect(find.text('3. How Is Your Mind?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Body check & final submission (options-first 4-step wizard)
      expect(find.text('4. How Is Your Body?'), findsOneWidget);
      expect(find.text('Save daily check-in'), findsOneWidget);
      expect(find.text('5. PERSONAL REFLECTION'), findsNothing);
    });

    testWidgets('ThoughtTraceDetailSheet and TraceInvestigationSheet allow Socratic inquiry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final trace = MindTraceModel(
        id: 't_inspect',
        date: now,
        overallMood: 'overwhelmed',
        selectedEmotions: const ['Overwhelmed'],
        moodIntensity: 7,
        journalText: 'Feeling like I will let everyone down if this fails.',
        situation: 'Preparing a presentation.',
        behavioralResponse: 'Procrastinating on social media.',
        createdAt: now,
        updatedAt: now,
      );

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThoughtTraceDetailSheet(trace: trace),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify thought quotation
      expect(find.text('“Feeling like I will let everyone down if this fails.”'), findsOneWidget);
      expect(find.text('Explore This Thought'), findsOneWidget);

      // Verify context displayed
      expect(find.text('Preparing a presentation.'), findsOneWidget);
      expect(find.text('Procrastinating on social media.'), findsOneWidget);

      // Test TraceInvestigationSheet directly
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TraceInvestigationSheet(trace: trace),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 6 Socratic inquiries
      expect(find.text('Explore this thought'), findsOneWidget);
      expect(find.text('What happened before this thought appeared?'), findsOneWidget);
      expect(find.text('What was I feeling?'), findsOneWidget);
      expect(find.text('What did I believe was happening?'), findsOneWidget);
      expect(find.text('What did I do in response?'), findsOneWidget);
      expect(find.text('Is this something I have noticed before?'), findsOneWidget);
      expect(find.text('What would I like to understand about this experience?'), findsOneWidget);
      expect(find.text('Save reflection to trace'), findsOneWidget);
    });

    testWidgets('DailyMindTraceStepper with historical 5-step trace preserves uncollected fields upon re-saving',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final historicalDate = DateTime(2026, 10, 20, 10, 30);
      final historicalTrace = MindTraceModel(
        id: 'trace_historical_step5',
        userId: 'clinical_user_01',
        date: historicalDate,
        overallMood: 'anxious',
        selectedEmotions: const ['Anxious'],
        moodIntensity: 7,
        energyLevel: 4,
        anxietyLevel: 8,
        sleepHours: 6.0,
        sleepQuality: 3,
        physicalTension: 7,
        concentrationLevel: 4,
        mentalClarity: 5,
        racingThoughts: 7,
        intrusiveThoughts: 6,
        emotionalDisconnection: 3,
        situation: 'Historical critical incident situation text.',
        symptomsAndExperiences: 'Tension, shortness of breath.',
        behavioralResponse: 'Left the room, drank water.',
        investigationAnswers: {'q1': 'answer 1'},
        aiReflection: 'Historical AI clinical reflection note.',
        suggestedJourneyActivityId: 'act_breathing_01',
        journalText: 'Historical personal journal reflection that must not be deleted.',
        voiceNotePath: 'voice/historical_memo.m4a',
        dynamicAnswers: {'q_env': 'Office environment'},
        isCompleted: true,
        createdAt: historicalDate,
        updatedAt: historicalDate,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: DailyMindTraceStepper(
                initialTrace: historicalTrace,
                onViewConstellation: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Deselect Anxious, select Calm, and Continue
      await tester.tap(find.text('Anxious'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Intensity -> Continue
      expect(find.text('2. Emotional Intensity'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Mind -> Continue
      expect(find.text('3. How Is Your Mind?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Body -> Submit
      expect(find.text('4. How Is Your Body?'), findsOneWidget);
      final submitButton = find.text('Save daily check-in');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the saved trace in repository
      final repo = container.read(mindTraceRepositoryProvider);
      final savedTraces = await repo.getAllTraces();
      expect(savedTraces.isNotEmpty, isTrue);

      final saved = savedTraces.firstWhere((t) => t.id == 'trace_historical_step5');

      // 1. Wizard-edited fields updated (canonical key stored):
      expect(saved.overallMood, equals('calm'));
      expect(saved.selectedEmotions.contains('calm'), isTrue);
      expect(saved.updatedAt.isAfter(historicalDate), isTrue);

      // 2. All 10 historical uncollected fields preserved 100%:
      expect(saved.userId, equals('clinical_user_01'));
      expect(saved.date, equals(historicalDate));
      expect(saved.createdAt, equals(historicalDate));
      expect(saved.anxietyLevel, equals(8));
      expect(saved.situation, equals('Historical critical incident situation text.'));
      expect(saved.symptomsAndExperiences, equals('Tension, shortness of breath.'));
      expect(saved.behavioralResponse, equals('Left the room, drank water.'));
      expect(saved.investigationAnswers, equals({'q1': 'answer 1'}));
      expect(saved.aiReflection, equals('Historical AI clinical reflection note.'));
      expect(saved.suggestedJourneyActivityId, equals('act_breathing_01'));
      expect(saved.journalText, equals('Historical personal journal reflection that must not be deleted.'));
      expect(saved.voiceNotePath, equals('voice/historical_memo.m4a'));
      expect(saved.dynamicAnswers['q_env'], equals('Office environment'));
    });
  });
}
