import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/organic_mood_orb.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/affect_taxonomy.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 1 & 2: Synchronous Hydration, Affect Taxonomy & Intra-Day Multi-Moment Tracking', () {
    testWidgets(
      '1. Zero-flash synchronous Frame-1 hydration on TrackScreen and HomeScreen when Heavy is logged today',
      (tester) async {
        final now = DateTime.now();
        final todayMorning = DateTime(now.year, now.month, now.day, 9, 15);
        final heavyTrace = MindTraceModel(
          id: 'trace_heavy_sync',
          userId: 'local_user',
          date: todayMorning,
          overallMood: 'heavy',
          selectedEmotions: const ['heavy', 'numb', 'exhausted'],
          moodIntensity: 8,
          journalText: 'Heavy fatigue this morning',
          createdAt: todayMorning,
          updatedAt: todayMorning,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(mindTraceRepositoryProvider).saveTrace(heavyTrace);
        // Ensure MindTraceNotifier is preloaded (mirroring persistent IndexedStack shell behavior)
        await container.read(mindTraceControllerProvider.future);
        expect(container.read(todayTraceProvider)?.overallMood, equals('heavy'));

        // Mount TrackScreen: VERY FIRST FRAME must already render 'heavy' (no 1s calm flash)
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: TrackScreen()),
            ),
          ),
        );
        await tester.pump();

        final trackOrb = tester.widget<OrganicMoodOrb>(
          find.byType(OrganicMoodOrb),
        );
        expect(trackOrb.moodKey, equals('heavy'));
        expect(trackOrb.intensity, equals(8));
        expect(trackOrb.animateChanges, isFalse);

        // Mount HomeScreen: VERY FIRST FRAME must also render 'heavy' (no calm fallback)
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump();

        final homeOrb = tester.widget<OrganicMoodOrb>(
          find.byType(OrganicMoodOrb),
        );
        expect(homeOrb.moodKey, equals('heavy'));
        expect(homeOrb.intensity, equals(8));
        expect(find.textContaining('Heavy (8/10)'), findsOneWidget);
      },
    );

    test(
      '2. Multi-moment same-day storage, chronological providers & PersonalBaseline diurnal analytics',
      () async {
        final now = DateTime.now();
        final tMorning = DateTime(now.year, now.month, now.day, 9, 0);
        final tAfternoon = DateTime(now.year, now.month, now.day, 14, 0);
        final tEvening = DateTime(now.year, now.month, now.day, 20, 0);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final repo = container.read(mindTraceRepositoryProvider);

        await repo.saveTrace(
          MindTraceModel(
            id: 'moment_am',
            date: tMorning,
            overallMood: 'heavy',
            selectedEmotions: const ['heavy', 'numb', 'exhausted'],
            moodIntensity: 8,
            createdAt: tMorning,
            updatedAt: tMorning,
          ),
        );
        await repo.saveTrace(
          MindTraceModel(
            id: 'moment_pm',
            date: tAfternoon,
            overallMood: 'anxious',
            selectedEmotions: const ['anxious', 'overwhelmed', 'on_edge'],
            moodIntensity: 6,
            createdAt: tAfternoon,
            updatedAt: tAfternoon,
          ),
        );
        await repo.saveTrace(
          MindTraceModel(
            id: 'moment_eve',
            date: tEvening,
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'relieved'],
            moodIntensity: 3,
            createdAt: tEvening,
            updatedAt: tEvening,
          ),
        );

        final allSaved = await repo.getAllTraces();
        expect(allSaved.length, equals(3));

        await container.read(mindTraceControllerProvider.future);
        final todayList = container.read(todayTracesProvider);
        expect(todayList.length, equals(3));
        expect(todayList[0].id, equals('moment_am'));
        expect(todayList[1].id, equals('moment_pm'));
        expect(todayList[2].id, equals('moment_eve'));

        expect(container.read(todayTraceProvider)?.id, equals('moment_eve'));
        expect(todayList[0].formattedTime, equals('09:00'));
        expect(todayList[0].timeBucket, equals(DayTimeBucket.morning));
        expect(todayList[1].timeBucket, equals(DayTimeBucket.afternoon));
        expect(todayList[2].timeBucket, equals(DayTimeBucket.evening));

        final baseline = PersonalBaseline.fromTraces(allSaved);
        // Must count 1 distinct calendar day despite 3 intra-day moments
        expect(baseline.totalRecordedDays, equals(1));
        expect(baseline.multiEntryDaysCount, equals(1));
        expect(baseline.averageIntraDaySwing, equals(5.0)); // 8 - 3
        expect(
          baseline.diurnalIntensityAverages[DayTimeBucket.morning],
          equals(8.0),
        );
        expect(
          baseline.diurnalIntensityAverages[DayTimeBucket.afternoon],
          equals(6.0),
        );
        expect(
          baseline.diurnalIntensityAverages[DayTimeBucket.evening],
          equals(3.0),
        );
        expect(baseline.emotionFrequencyMap['numb'], equals(1));
        expect(baseline.emotionFrequencyMap['overwhelmed'], equals(1));
        expect(baseline.emotionFrequencyMap['relieved'], equals(1));
      },
    );

    test(
      '3. AffectTaxonomy prioritizes 6 feelings per core mood with zero exact Tier-1 collision',
      () {
        const tier1English = {'Calm', 'Anxious', 'Frustrated', 'Heavy', 'Restless'};
        for (final f in AffectTaxonomy.nuancedFeelings) {
          expect(tier1English.contains(f.english), isFalse);
          expect(f.localized(const AppStrings('fr')), isNotEmpty);
          expect(f.localized(const AppStrings('ar')), isNotEmpty);
        }
        for (final core in AffectTaxonomy.coreMoodKeys) {
          final ordered = AffectTaxonomy.prioritizedForCore(core);
          expect(ordered.length, equals(AffectTaxonomy.nuancedFeelings.length));
          expect(
            ordered.take(6).every((f) => f.primaryAffinity.contains(core)),
            isTrue,
          );
        }
      },
    );

    testWidgets(
      '4. TrackScreen supports Tier-2 nuanced multi-select and logging multiple moments in one day',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: TrackScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select Core Heavy -> displays Heavy-affiliated Tier-2 feelings (Sad, Numb, Exhausted...)
        await tester.ensureVisible(find.text('Heavy'));
        await tester.tap(find.text('Heavy'));
        await tester.pumpAndSettle();
        expect(find.text('Numb'), findsOneWidget);
        expect(find.text('Exhausted'), findsOneWidget);

        await tester.ensureVisible(find.text('Numb'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Numb'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Exhausted'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exhausted'));
        await tester.pumpAndSettle();

        final saveBtn = find.text('Save Check-In');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(find.text("Update Today's Entry"), findsOneWidget);
        expect(find.text('+ New moment'), findsOneWidget);
        expect(container.read(todayTracesProvider).length, equals(1));
        expect(
          container.read(todayTraceProvider)?.nuancedEmotions,
          containsAll(['numb', 'exhausted']),
        );

        // Tap + New moment to add a second intra-day check-in without overwriting the first
        await tester.ensureVisible(find.text('+ New moment'));
        await tester.tap(find.text('+ New moment'));
        await tester.pumpAndSettle();

        expect(find.text('Log New Moment'), findsOneWidget);

        await tester.ensureVisible(find.text('Relieved'));
        await tester.tap(find.text('Relieved'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Log New Moment'));
        await tester.tap(find.text('Log New Moment'));
        await tester.pumpAndSettle();

        final todayList = container.read(todayTracesProvider);
        expect(todayList.length, equals(2));
        expect(todayList[0].overallMood, equals('heavy'));
        expect(todayList[1].overallMood, equals('calm'));
        expect(todayList[1].nuancedEmotions, contains('relieved'));

        // Switch to History & Calendar and confirm both moments render
        await tester.tap(find.text('History & Calendar'));
        await tester.pumpAndSettle();
        expect(find.text('Numb'), findsWidgets);
        expect(find.text('Relieved'), findsWidgets);
      },
    );
  });
}
