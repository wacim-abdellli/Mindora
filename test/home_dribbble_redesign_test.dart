import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_organic_exercise_art.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Home Screen Clean Single-Job & Clinical Pulse Layout Tests', () {
    testWidgets('Renders clean Today Home with 6 MoodFace tiles, Clinical Pulse, and Breather card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();

      const strings = AppStrings('en');
      expect(find.text('Mindora'), findsOneWidget);
      expect(find.textContaining(strings.defaultFriendName), findsOneWidget);

      // Hero 2-tap MoodFace grid + Clinical Pulse + Breather card
      expect(find.byType(MoodFaceTile), findsNWidgets(6));
      expect(find.byKey(const ValueKey('home-clinical-pulse-card')), findsOneWidget);
      expect(find.byType(HomeOrganicExerciseArt), findsOneWidget);
      expect(find.text(strings.takeOneMinuteBreather), findsOneWidget);
    });

    testWidgets('Reflects today check-in summary calmly on Home when logged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(
        MindTraceModel(
          id: 'trace_today_home',
          userId: 'test_user',
          date: now,
          overallMood: 'calm',
          moodIntensity: 7,
          energyLevel: 7,
          anxietyLevel: 3,
          journalText: 'Steady breath after afternoon walk',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      const strings = AppStrings('en');
      expect(
        find.text(strings.youFeelTodayTitle(strings.plainMoodLabel('calm'))),
        findsOneWidget,
      );
    });

    testWidgets(
      'Logging a 2-tap check-in on Home saves to MindTraceController and updates todayTraceProvider',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        await tester.tap(find.byKey(const ValueKey('today-mood-calm')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.strengthMedium));
        await tester.pumpAndSettle();

        final traces = container.read(mindTraceControllerProvider).value ?? [];
        expect(traces.isNotEmpty, isTrue);
        expect(traces.first.overallMood, equals('calm'));

        final todayTrace = container.read(todayTraceProvider);
        expect(todayTrace, isNotNull);
        expect(todayTrace?.overallMood, equals('calm'));
      },
    );

    testWidgets(
      'Optional note via ProgressiveDetailsSheet persists note to journalText',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'trace_home_note',
                userId: 'local_user',
                date: now,
                overallMood: 'calm',
                moodIntensity: 6,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container.read(mindTraceControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        final addDetailsBtn = find.text(strings.addDetailsCta);
        await tester.ensureVisible(addDetailsBtn);
        await tester.tap(addDetailsBtn);
        await tester.pumpAndSettle();

        expect(find.byType(ProgressiveDetailsSheet), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text(strings.skipBtn));
          await tester.pumpAndSettle();
        }
        await tester.enterText(
          find.byType(TextField),
          'Felt peaceful during evening walk',
        );
        await tester.tap(find.text(strings.saveDetailsBtn));
        await tester.pumpAndSettle();

        final todayTrace = container.read(todayTraceProvider);
        expect(
          todayTrace?.journalText,
          equals('Felt peaceful during evening walk'),
        );
      },
    );

    testWidgets(
      'Tapping breather card opens the breathing exercise sheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        final exerciseCard = find.text(strings.takeOneMinuteBreather);
        expect(exerciseCard, findsOneWidget);
        await tester.ensureVisible(exerciseCard);
        await tester.pumpAndSettle();
        await tester.tap(exerciseCard);
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ContextualSupportSheet), findsOneWidget);
        expect(find.text(strings.breatheQuickBtn), findsOneWidget);

        Navigator.of(tester.element(find.byType(ContextualSupportSheet))).pop();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ContextualSupportSheet), findsNothing);
      },
    );
  });
}
