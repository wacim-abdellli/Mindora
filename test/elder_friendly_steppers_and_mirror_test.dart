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
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
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
      'ProgressiveDetailsSheet 1-tap sleep and energy presets update saved telemetry cleanly',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        final initialTrace = MindTraceModel(
          id: 'elder_trace_1',
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          createdAt: now,
          updatedAt: now,
        );
        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(initialTrace, generateAi: false);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ProgressiveDetailsSheet(trace: initialTrace),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        // Card 1 (Nuance) -> Continue -> Card 2 (Sleep & Energy)
        await tester.tap(find.text(en.continueBtn));
        await tester.pumpAndSettle();

        await tester.tap(find.text(en.sleepAbout8));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.energyFullLabel));
        await tester.pumpAndSettle();

        await tester.tap(find.text(en.doneBtn));
        await tester.pumpAndSettle();

        final saved = container.read(todayTraceProvider);
        expect(saved, isNotNull);
        expect(saved!.sleepHours, closeTo(8.0, 0.01));
        expect(saved.energyLevel, equals(8));
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
