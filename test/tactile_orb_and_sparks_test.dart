import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/organic_mood_orb.dart';
import 'package:mind_forensics/core/widgets/quick_note_sparks_bar.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 7.1: 2D Tactile Orb Sculpting & 1-Tap Quick Note Sparks', () {
    testWidgets(
      'OrganicMoodOrb supports vertical intensity drag, horizontal LTR/RTL mood stepping, and celebration bloom',
      (tester) async {
        int intensity = 5;
        final steps = <int>[];
        int celebrationRev = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OrganicMoodOrb(
                          moodKey: 'calm',
                          intensity: intensity,
                          color: MindTokens.moodCalm,
                          celebrationRevision: celebrationRev,
                          semanticLabel: 'Mood Orb',
                          onIntensityChanged: (next) =>
                              setState(() => intensity = next),
                          onMoodStep: steps.add,
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => celebrationRev++),
                          child: const Text('Bloom'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Vertical drag upward increases intensity
        await tester.drag(find.byType(OrganicMoodOrb), const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(intensity, greaterThan(5));

        // Horizontal drag right steps mood forward (+1) in LTR
        await tester.drag(find.byType(OrganicMoodOrb), const Offset(60, 0));
        await tester.pumpAndSettle();
        expect(steps, isNotEmpty);
        expect(steps.last, equals(1));

        // Trigger bloom ring and verify animation settles without errors
        await tester.tap(find.text('Bloom'));
        await tester.pump(const Duration(milliseconds: 180));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify RTL inverts horizontal drag semantics cleanly
        steps.clear();
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('orb_rtl_test'),
            theme: buildMindTheme(Brightness.dark),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(
                  child: OrganicMoodOrb(
                    moodKey: 'calm',
                    intensity: 5,
                    color: MindTokens.moodCalm,
                    semanticLabel: 'Orb RTL',
                    onMoodStep: steps.add,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(OrganicMoodOrb), const Offset(60, 0));
        await tester.pumpAndSettle();
        expect(steps.last, equals(-1));
      },
    );

    testWidgets(
      'QuickNoteSparksBar appends/removes mood-specific phrases in HomeDailyCheckInCard and TrackScreen with zero typing',
      (tester) async {
        final noteController = TextEditingController();
        addTearDown(noteController.dispose);
        int moodIndex = 0;
        const moodOptions = [
          (key: 'calm', icon: Icons.spa_outlined),
          (key: 'anxious', icon: Icons.bolt_outlined),
          (key: 'frustrated', icon: Icons.local_fire_department_outlined),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return HomeDailyCheckInCard(
                      tokens: MindTokens.dark,
                      strings: const AppStrings('en'),
                      isDark: true,
                      todayTrace: null,
                      traces: const [],
                      selectedMoodIndex: moodIndex,
                      moodIntensity: 5,
                      todayNoteController: noteController,
                      moodOptions: moodOptions,
                      onMoodSelected: (idx) => setState(() => moodIndex = idx),
                      onIntensityChanged: (_) {},
                      onSave: () {},
                      getMoodLabel: (k, s) => switch (k) {
                        'calm' => s.moodCalm,
                        'anxious' => s.moodAnxious,
                        'frustrated' => s.moodFrustrated,
                        _ => k,
                      },
                      getMoodColor: (_) => MindTokens.moodCalm,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QuickNoteSparksBar), findsOneWidget);
        final sparkPeaceful = find.descendant(
          of: find.byType(QuickNoteSparksBar),
          matching: find.text('Peaceful moment'),
        );
        expect(sparkPeaceful, findsOneWidget);

        await tester.ensureVisible(sparkPeaceful);
        await tester.tap(sparkPeaceful);
        await tester.pumpAndSettle();
        expect(noteController.text, equals('Peaceful moment'));

        // Switch mood -> sparks swap to anxious sparks; tapping second spark appends
        await tester.ensureVisible(find.text('Anxious'));
        await tester.tap(find.text('Anxious'));
        await tester.pumpAndSettle();
        final sparkRacing = find.descendant(
          of: find.byType(QuickNoteSparksBar),
          matching: find.text('Mind racing'),
        );
        expect(sparkRacing, findsOneWidget);

        await tester.ensureVisible(sparkRacing);
        await tester.tap(sparkRacing);
        await tester.pumpAndSettle();
        expect(noteController.text, equals('Peaceful moment · Mind racing'));

        // Tap active spark again to toggle it off cleanly
        await tester.tap(sparkRacing);
        await tester.pumpAndSettle();
        expect(noteController.text, equals('Peaceful moment'));

        // TrackScreen integrates orb swipe & quick sparks seamlessly down to 320px AR RTL
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        const arStrings = AppStrings('ar');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('track_sparks_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: TrackScreen(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(arStrings.quickSparksForMood('calm').first));
        await tester.tap(find.text(arStrings.quickSparksForMood('calm').first));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(arStrings.quickSparksForMood('calm').first),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
