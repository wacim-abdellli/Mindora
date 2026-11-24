import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/check_in_micro_mirror.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 7.2: Elder-Friendly Somatic Steppers & Check-In Micro-Mirror',
      () {
    test('CheckInMicroMirror synthesizes calm non-diagnostic reflections', () {
      const en = AppStrings('en');
      const ar = AppStrings('ar');
      final now = DateTime(2026, 11, 24, 21, 0);

      final firstTrace = MindTraceModel(
        id: 'm1',
        date: DateTime(2026, 11, 24, 10, 0),
        overallMood: 'anxious',
        moodIntensity: 8,
        createdAt: now,
        updatedAt: now,
      );

      // Single moment -> first-moment calm copy
      expect(
        CheckInMicroMirror.build(
          latestToday: firstTrace,
          todayTraces: [firstTrace],
          allTraces: [firstTrace],
          strings: en,
        ),
        equals(en.microMirrorFirstMoment),
      );

      // Second calmer moment today (-4 drop)
      final secondCalm = MindTraceModel(
        id: 'm2',
        date: DateTime(2026, 11, 24, 20, 30),
        overallMood: 'calm',
        moodIntensity: 4,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        CheckInMicroMirror.build(
          latestToday: secondCalm,
          todayTraces: [firstTrace, secondCalm],
          allTraces: [firstTrace, secondCalm],
          strings: en,
        ),
        equals(en.microMirrorCalmerShift(4)),
      );
      expect(
        CheckInMicroMirror.build(
          latestToday: secondCalm,
          todayTraces: [firstTrace, secondCalm],
          allTraces: [firstTrace, secondCalm],
          strings: ar,
        ),
        equals(ar.microMirrorCalmerShift(4)),
      );

      // >= 3 distinct days this week -> weekly rhythm reflection
      final threeDays = [
        firstTrace,
        MindTraceModel(
          id: 'd2',
          date: DateTime(2026, 11, 23, 9, 0),
          overallMood: 'calm',
          moodIntensity: 4,
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'd3',
          date: DateTime(2026, 11, 21, 9, 0),
          overallMood: 'calm',
          moodIntensity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(
        CheckInMicroMirror.build(
          latestToday: firstTrace,
          todayTraces: [firstTrace],
          allTraces: threeDays,
          strings: en,
        ),
        equals(en.microMirrorWeeklyRhythm(3)),
      );
    });

    testWidgets(
      'TrackScreen 1-tap sleep presets and +/- steppers update saved telemetry without dragging',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const TrackScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Expand optional context
        await tester.ensureVisible(find.text('Add context (optional)'));
        await tester.tap(find.text('Add context (optional)'));
        await tester.pumpAndSettle();

        // Tap 8h preset then +0.5 step -> 8.5h sleep
        final sleepPreset8 = find.byKey(const ValueKey<String>('sleep-preset-8'));
        await tester.ensureVisible(sleepPreset8);
        await tester.tap(sleepPreset8);
        await tester.pumpAndSettle();

        final sleepInc = find.byKey(const ValueKey<String>('sleep_inc'));
        await tester.ensureVisible(sleepInc);
        await tester.tap(sleepInc);
        await tester.pumpAndSettle();

        // Energy 5 -> +1 = 6; Anxiety 3 -> -1 = 2
        final energyInc = find.byKey(const ValueKey<String>('energy_inc'));
        await tester.ensureVisible(energyInc);
        await tester.tap(energyInc);
        await tester.pumpAndSettle();

        final anxietyDec = find.byKey(const ValueKey<String>('anxiety_dec'));
        await tester.ensureVisible(anxietyDec);
        await tester.tap(anxietyDec);
        await tester.pumpAndSettle();

        expect(find.text('8.5h'), findsOneWidget);
        expect(find.text('6/10'), findsOneWidget);
        expect(find.text('2/10'), findsOneWidget);

        await tester.ensureVisible(find.text('Save Check-In'));
        await tester.tap(find.text('Save Check-In'));
        await tester.pumpAndSettle();

        final saved = container.read(todayTraceProvider);
        expect(saved, isNotNull);
        expect(saved!.sleepHours, closeTo(8.5, 0.01));
        expect(saved.energyLevel, equals(6));
        expect(saved.anxietyLevel, equals(2));
        expect(
          find.text(const AppStrings('en').microMirrorFirstMoment),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HomeDailyCheckInCard displays Micro-Mirror cleanly at 320px + 1.35x Arabic RTL',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        final now = DateTime.now();
        final t1 = MindTraceModel(
          id: 'ar_m1',
          date: now.subtract(const Duration(hours: 3)),
          overallMood: 'anxious',
          moodIntensity: 8,
          createdAt: now,
          updatedAt: now,
        );
        final t2 = MindTraceModel(
          id: 'ar_m2',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          createdAt: now,
          updatedAt: now,
        );
        const arStrings = AppStrings('ar');

        await tester.pumpWidget(
          MaterialApp(
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
                      padding: const EdgeInsets.all(12),
                      child: HomeDailyCheckInCard(
                        tokens: MindTokens.dark,
                        strings: arStrings,
                        isDark: true,
                        todayTrace: t2,
                        traces: [t1, t2],
                        todayTraces: [t1, t2],
                        selectedMoodIndex: 0,
                        moodIntensity: 4,
                        todayNoteController: TextEditingController(),
                        moodOptions: const [
                          (key: 'calm', icon: Icons.spa_outlined),
                        ],
                        onMoodSelected: (_) {},
                        onIntensityChanged: (_) {},
                        onSave: () {},
                        getMoodLabel: (k, s) => s.moodCalm,
                        getMoodColor: (_) => MindTokens.moodCalm,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(arStrings.microMirrorCalmerShift(4)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
