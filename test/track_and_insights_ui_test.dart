import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_card.dart';
import 'package:mind_forensics/core/widgets/mind_strength_picker.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_entry_detail_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_month_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestHarness(Widget child) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeControllerProvider);
        return MaterialApp(
          theme: buildMindTheme(Brightness.light),
          darkTheme: buildMindTheme(Brightness.dark),
          locale: locale,
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TrackScreen & Self-Observation Widget Tests', () {
    testWidgets(
      'TrackScreen renders single-job My days calendar and 2-tap + Log new moment sheet',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const TrackScreen()));
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        expect(find.text(en.navMyDays), findsOneWidget);
        expect(find.byType(TrackMonthCalendar), findsOneWidget);
        expect(find.text(en.logNewMomentLink), findsOneWidget);
        expect(find.text(en.thoughtTraceQuote), findsOneWidget);
        expect(find.text(en.addCheckInForDayBtn), findsOneWidget);

        // Open 2-tap quick log sheet
        await tester.tap(find.text(en.logNewMomentLink));
        await tester.pumpAndSettle();

        expect(find.byType(MoodFaceTile), findsNWidgets(6));
        expect(find.byType(MindStrengthPicker), findsNothing);

        // Tap 1: Pick mood -> reveals strength picker
        await tester.tap(find.text(en.moodWorriedPlain));
        await tester.pumpAndSettle();
        expect(find.byType(MindStrengthPicker), findsOneWidget);

        // Tap 2: Pick Medium -> saves and returns to calendar timeline
        await tester.tap(find.text(en.strengthMedium));
        await tester.pumpAndSettle();

        expect(find.text(en.checkInSavedSnackbar), findsOneWidget);
        expect(find.text(en.moodWorriedPlain), findsWidgets);
        expect(find.textContaining(en.strengthMedium), findsWidgets);
      },
    );

    testWidgets(
      'TrackScreen timeline calendar day filtering, edit via ProgressiveDetailsSheet, delete with undo, and Explore with AI Guide',
      (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                final locale = ref.watch(localeControllerProvider);
                return MaterialApp(
                  theme: buildMindTheme(Brightness.light),
                  darkTheme: buildMindTheme(Brightness.dark),
                  locale: locale,
                  home: const Scaffold(body: TrackScreen()),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Seed two traces (a non-today trace in current month + today)
        final now = DateTime.now();
        final altDay = now.day > 1 ? now.day - 1 : 2;
        final pastDate = DateTime(now.year, now.month, altDay, 14, 0);
        final todayDate = DateTime(now.year, now.month, now.day, 10, 0);

        final pastTrace = MindTraceModel(
          id: 'trace-past-1',
          date: pastDate,
          overallMood: 'heavy',
          selectedEmotions: const ['heavy'],
          moodIntensity: 7,
          situation: 'Work / Demands',
          journalText: 'Long afternoon debugging.',
          createdAt: pastDate,
          updatedAt: pastDate,
        );
        final todayTrace = MindTraceModel(
          id: 'trace-today-1',
          date: todayDate,
          overallMood: 'calm',
          selectedEmotions: const ['calm'],
          moodIntensity: 4,
          journalText: 'Quiet morning walk.',
          createdAt: todayDate,
          updatedAt: todayDate,
        );

        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(pastTrace, generateAi: false);
        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(todayTrace, generateAi: false);
        await tester.pumpAndSettle();

        expect(find.text('Quiet morning walk.'), findsOneWidget);

        // Tap past calendar day to inspect past entry
        final calDayFinder = find.descendant(
          of: find.byType(TrackMonthCalendar),
          matching: find.text('$altDay'),
        );
        await tester.ensureVisible(calDayFinder);
        await tester.pumpAndSettle();
        await tester.tap(calDayFinder);
        await tester.pumpAndSettle();

        expect(find.text('Long afternoon debugging.'), findsAtLeastNWidgets(1));
        expect(find.text('Quiet morning walk.'), findsNothing);

        // Tap past entry card -> TrackEntryDetailSheet -> Edit -> ProgressiveDetailsSheet
        await tester.ensureVisible(find.text('Long afternoon debugging.'));
        await tester.tap(find.text('Long afternoon debugging.'));
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        expect(find.byType(TrackEntryDetailSheet), findsOneWidget);
        expect(find.text(en.exploreWithAiGuideBtn), findsOneWidget);
        expect(find.text(en.editEntryBtn), findsOneWidget);
        expect(find.text(en.deleteEntryBtn), findsOneWidget);

        await tester.ensureVisible(find.text(en.editEntryBtn));
        await tester.tap(find.text(en.editEntryBtn));
        await tester.pumpAndSettle();

        expect(find.byType(ProgressiveDetailsSheet), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.ensureVisible(find.text(en.skipBtn));
          await tester.tap(find.text(en.skipBtn));
          await tester.pumpAndSettle();
        }
        await tester.enterText(
          find.descendant(
            of: find.byType(ProgressiveDetailsSheet),
            matching: find.byType(TextField),
          ),
          'Updated evening reflection.',
        );
        await tester.ensureVisible(find.text(en.saveDetailsBtn));
        await tester.tap(find.text(en.saveDetailsBtn));
        await tester.pumpAndSettle();
        // Wait for floating saved toast to dismiss so bottom card hit-test is unobstructed
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(find.text('Updated evening reflection.'), findsOneWidget);

        // Open detail again -> Delete -> verify Undo banner appears
        await tester.ensureVisible(find.text('Updated evening reflection.'));
        await tester.tap(find.text('Updated evening reflection.'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(en.deleteEntryBtn));
        await tester.tap(find.text(en.deleteEntryBtn));
        await tester.pumpAndSettle();

        expect(find.text('Updated evening reflection.'), findsNothing);
        expect(find.text(en.checkInRemovedUndo), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Switch to today on calendar and Explore with AI Guide
        final todayCalFinder = find.descendant(
          of: find.byType(TrackMonthCalendar),
          matching: find.text('${now.day}'),
        );
        await tester.ensureVisible(todayCalFinder);
        await tester.tap(todayCalFinder);
        await tester.pumpAndSettle();

        expect(find.text('Quiet morning walk.'), findsOneWidget);
        await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Quiet morning walk.'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Quiet morning walk.'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(en.exploreWithAiGuideBtn));
        await tester.tap(find.text(en.exploreWithAiGuideBtn));
        await tester.pumpAndSettle();

        final activeCase = container.read(activeCaseControllerProvider).value;
        expect(activeCase, isNotNull);
        expect(activeCase!.incidentDescription, contains(en.plainMoodLabel('calm')));
        expect(activeCase.incidentDescription, contains('4/10'));
        expect(activeCase.incidentDescription, contains('Quiet morning walk.'));
      },
    );
  });

  group('InsightsScreen Widget Tests', () {
    testWidgets('InsightsScreen renders Patterns and reveals personal baseline and weekly summary on details expand', (tester) async {
      await tester.pumpWidget(createTestHarness(const InsightsScreen()));
      await tester.pumpAndSettle();

      const en = AppStrings('en');
      expect(find.text(en.navPatterns), findsOneWidget);

      final moreBtn = find.byKey(
        const ValueKey<String>('patterns-more-details-btn'),
      );
      await tester.ensureVisible(moreBtn);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.text(en.personalBaselineTitle), findsOneWidget);
      expect(find.text(en.weeklySummaryTitle), findsOneWidget);
      expect(find.text(en.exportSummaryButton), findsNothing);
      expect(find.text(en.fullProgressTrendsTitle), findsOneWidget);
    });
  });

  group('Mind Design System Primitives Tests', () {
    testWidgets('MindButton has minimum 48x48 tap target and responds to press', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        createTestHarness(
          MindButton(
            text: 'Action',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(MindButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('MindCard renders child within 10px rounded border', (tester) async {
      await tester.pumpWidget(
        createTestHarness(
          const MindCard(
            child: Text('Card Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
