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
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
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
      'QuickNoteSparksBar appends/removes mood-specific phrases in ProgressiveDetailsSheet including 320px AR RTL',
      (tester) async {
        final noteController = TextEditingController();
        addTearDown(noteController.dispose);
        String activeMood = 'calm';

        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => activeMood = 'calm'),
                              child: const Text('Calm'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => activeMood = 'anxious'),
                              child: const Text('Anxious'),
                            ),
                          ],
                        ),
                        QuickNoteSparksBar(
                          moodKey: activeMood,
                          controller: noteController,
                          strings: const AppStrings('en'),
                        ),
                      ],
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

        // ProgressiveDetailsSheet Card 4 integrates QuickNoteSparksBar cleanly at 320px AR RTL
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        const arStrings = AppStrings('ar');
        final now = DateTime.now();
        final sampleTrace = MindTraceModel(
          id: 'sparks_ar_1',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          createdAt: now,
          updatedAt: now,
        );

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
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ProgressiveDetailsSheet(trace: sampleTrace),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Advance from Card 1 -> 2 -> 3 -> 4
        for (var step = 0; step < 3; step++) {
          await tester.ensureVisible(find.text(arStrings.skipBtn));
          await tester.tap(find.text(arStrings.skipBtn));
          await tester.pumpAndSettle();
        }

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
