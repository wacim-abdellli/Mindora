import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/mind_strength_picker.dart';
import 'package:mind_forensics/core/widgets/mood_emblem.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/core/widgets/organic_mood_orb.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_active_case_card.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_weekly_rhythm_card.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';

void main() {
  group('Home Extracted Components Unit & Widget Tests', () {
    const tokens = MindTokens.dark;
    const strings = AppStrings('en');

    final moodOptions = const [
      (key: 'calm', icon: Icons.spa_outlined),
      (key: 'anxious', icon: Icons.bolt_outlined),
      (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    ];

    testWidgets('HomeDailyCheckInCard renders 2-tap MoodFace controls and triggers callbacks', (tester) async {
      int selectedIdx = 0;
      double intensity = 5.0;
      bool saved = false;
      String? quickMood;
      int? quickIntensity;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return HomeDailyCheckInCard(
                    tokens: tokens,
                    strings: strings,
                    isDark: true,
                    todayTrace: null,
                    traces: const [],
                    selectedMoodIndex: selectedIdx,
                    moodIntensity: intensity,
                    todayNoteController: controller,
                    moodOptions: moodOptions,
                    onMoodSelected: (idx) => setState(() => selectedIdx = idx),
                    onIntensityChanged: (val) => setState(() => intensity = val),
                    onSave: () => saved = true,
                    onQuickSave: (
                      moodKey,
                      strength, {
                      bool createNew = false,
                      String? note,
                      bool isPrivate = false,
                    }) {
                      quickMood = moodKey;
                      quickIntensity = strength;
                    },
                    getMoodLabel: (key, str) => str.plainMoodLabel(key),
                    getMoodColor: (key) => MindTokens.moodCalm,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 6 MoodFace options render upfront and strength picker is hidden until Tap 1
      expect(find.byType(MoodFaceTile), findsNWidgets(6));
      expect(find.text(strings.howAreYouRightNow), findsOneWidget);
      expect(find.byType(MindStrengthPicker), findsNothing);

      // Tap 1: Select Worried ('anxious')
      await tester.tap(find.byKey(const ValueKey<String>('today-mood-anxious')));
      await tester.pumpAndSettle();
      expect(selectedIdx, equals(1));
      expect(find.byType(MindStrengthPicker), findsOneWidget);

      // Tap 2: Select 'A lot' -> auto-saves at intensity 9
      await tester.ensureVisible(find.text(strings.strengthALot));
      await tester.tap(find.text(strings.strengthALot));
      await tester.pumpAndSettle();
      expect(quickMood, equals('anxious'));
      expect(quickIntensity, equals(9));
      expect(saved, isFalse);
    });

    testWidgets('HomeActiveCaseCard renders case progress and invokes onResume', (tester) async {
      bool resumed = false;
      final testCase = CaseModel(
        id: 'c1',
        caseNumber: 'CASE 07',
        title: 'Workplace presentation tension',
        incidentDescription: 'High somatic pressure during presentation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.evidence,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActiveCaseCard(
              caseModel: testCase,
              tokens: tokens,
              strings: strings,
              isDark: true,
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workplace presentation tension'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(strings.resumeInvestigation), findsOneWidget);

      await tester.tap(find.text(strings.resumeInvestigation));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('HomeDailyCheckInCard mood pills keep invariant layout geometry when selection changes', (tester) async {
      final allMoods = const [
        (key: 'calm', icon: Icons.spa_outlined),
        (key: 'anxious', icon: Icons.bolt_outlined),
        (key: 'frustrated', icon: Icons.local_fire_department_outlined),
        (key: 'heavy', icon: Icons.grain_outlined),
        (key: 'restless', icon: Icons.air_outlined),
      ];
      int selectedIdx = 4;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, extensions: const [MindTokens.light]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 340,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return HomeDailyCheckInCard(
                      tokens: MindTokens.light,
                      strings: strings,
                      isDark: false,
                      todayTrace: null,
                      traces: const [],
                      selectedMoodIndex: selectedIdx,
                      moodIntensity: 5.0,
                      todayNoteController: TextEditingController(),
                      moodOptions: allMoods,
                      onMoodSelected: (idx) => setState(() => selectedIdx = idx),
                      onIntensityChanged: (_) {},
                      onSave: () {},
                      getMoodLabel: (key, s) => s.plainMoodLabel(key),
                      getMoodColor: (_) => MindTokens.moodCalm,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Map<String, Rect> captureRects() => {
        for (final mood in AppMood.values)
          mood.key: tester.getRect(
            find.byKey(ValueKey<String>('today-mood-${mood.key}')),
          ),
      };

      final initialRects = captureRects();

      // Selecting any MoodFace tile must not reflow sibling tiles.
      for (final mood in AppMood.values) {
        final tileFinder = find.byKey(
          ValueKey<String>('today-mood-${mood.key}'),
        );
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();
        expect(
          captureRects(),
          equals(initialRects),
          reason: 'Reflow after selecting ${mood.key}',
        );
      }
    });

    testWidgets('MoodEmblem renders bespoke geometric vectors across all 5 states', (tester) async {
      const moodKeys = ['calm', 'anxious', 'frustrated', 'heavy', 'restless', 'هادئ', 'قلق'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                for (final key in moodKeys)
                  MoodEmblem(
                    moodKey: key,
                    size: 20,
                    color: MindTokens.moodColor(AppMood.fromKey(key)),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MoodEmblem), findsNWidgets(moodKeys.length));
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(moodKeys.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets('OrganicMoodOrb morphs cleanly across moods and intensity changes', (tester) async {
      String activeMood = 'calm';
      int intensity = 4;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: OrganicMoodOrb(
                    moodKey: activeMood,
                    intensity: intensity,
                    color: MindTokens.moodColor(AppMood.fromKey(activeMood)),
                    size: 96,
                    semanticLabel: activeMood,
                    onTap: () => setState(() {
                      activeMood = 'frustrated';
                      intensity = 9;
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrganicMoodOrb), findsOneWidget);
      await tester.tap(find.byType(OrganicMoodOrb));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeDailyCheckInCard logged summary exposes Breathe & Talk about it actions', (tester) async {
      bool breatheTapped = false;
      MindTraceModel? talkedTrace;
      final now = DateTime.now();
      final todayTrace = MindTraceModel(
        id: 't_logged',
        userId: 'u1',
        date: now,
        overallMood: 'frustrated',
        moodIntensity: 9,
        energyLevel: 4,
        anxietyLevel: 7,
        journalText: 'Too many notifications today',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDailyCheckInCard(
              tokens: MindTokens.dark,
              strings: const AppStrings('en'),
              isDark: true,
              todayTrace: todayTrace,
              traces: [todayTrace],
              selectedMoodIndex: 2,
              moodIntensity: 9,
              todayNoteController: TextEditingController(),
              moodOptions: moodOptions,
              onMoodSelected: (_) {},
              onIntensityChanged: (_) {},
              onSave: () {},
              getMoodLabel: (key, s) => key == 'frustrated' ? s.moodFrustrated : key,
              getMoodColor: (key) => MindTokens.moodColor(AppMood.fromKey(key)),
              onBreatheTap: () => breatheTapped = true,
              onTalkAboutIt: (trace) => talkedTrace = trace,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(strings.youFeelTodayTitle(strings.plainMoodLabel('frustrated'))),
        findsOneWidget,
      );
      expect(find.text(strings.breatheQuickBtn), findsOneWidget);
      expect(find.text(strings.talkItOutBtn), findsOneWidget);

      await tester.tap(find.text(strings.breatheQuickBtn));
      await tester.pumpAndSettle();
      expect(breatheTapped, isTrue);

      await tester.tap(find.text(strings.talkItOutBtn));
      await tester.pumpAndSettle();
      expect(talkedTrace?.id, equals('t_logged'));
    });

    testWidgets('HomeWeeklyRhythmCard maps 7-day continuity and renders cleanly in 320px RTL', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      final traces = <MindTraceModel>[
        MindTraceModel(
          id: 't_today',
          userId: 'u1',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          energyLevel: 7,
          anxietyLevel: 2,
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 't_prev',
          userId: 'u1',
          date: now.subtract(const Duration(days: 2)),
          overallMood: 'anxious',
          moodIntensity: 6,
          energyLevel: 5,
          anxietyLevel: 6,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      MindTraceModel? tappedTrace;
      const arStrings = AppStrings('ar');

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: HomeWeeklyRhythmCard(
                    traces: traces,
                    tokens: MindTokens.light,
                    strings: arStrings,
                    isDark: false,
                    getMoodColor: (k) => MindTokens.moodColor(AppMood.fromKey(k)),
                    getMoodLabel: (k, _) => k,
                    onDayTap: (_, trace) => tappedTrace = trace,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(arStrings.thisWeekTitle), findsOneWidget);
      expect(find.text(arStrings.daysThisWeekCount(2)), findsOneWidget);
      expect(find.byType(MoodFace), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(MoodFace).first);
      await tester.pumpAndSettle();
      expect(tappedTrace, isNotNull);
    });
  });
}
