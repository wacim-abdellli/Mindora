import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_month_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 11 — Single-Job Today (2-Tap Check-In) & My days (Calendar)', () {
    testWidgets('Today completes and persists a mood check-in in 2 taps with 0 typing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const en = AppStrings('en');
      // Zero blank TextField on Today!
      expect(find.byType(TextField), findsNothing);
      expect(find.text(en.howAreYouRightNow), findsOneWidget);
      expect(find.byType(MoodFace), findsNWidgets(6));

      // Tap 1: Pick Good face
      await tester.tap(find.byKey(const ValueKey<String>('today-mood-good')));
      await tester.pumpAndSettle();
      expect(find.text(en.howStrongQuestion), findsOneWidget);

      // Tap 2: Pick A lot -> auto-saves immediately!
      await tester.tap(find.text(en.strengthALot));
      await tester.pumpAndSettle();

      final saved = container.read(todayTraceProvider);
      expect(saved, isNotNull);
      expect(saved!.overallMood, 'good');
      expect(saved.moodIntensity, 9);
      expect(find.text(en.addDetailsCta), findsOneWidget);
    });

    testWidgets('My days opens directly to Month Calendar without duplicate check-in form tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const TrackScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrackMonthCalendar), findsOneWidget);
      expect(find.text('Check-In Today'), findsNothing);
      expect(find.text('History & Calendar'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Today renders cleanly for Amel (68yo): 320px + 2.0x text + Arabic RTL Sunrise', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setLanguage(AppLanguage.arabic);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            ),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MoodFace), findsNWidgets(6));
    });
  });
}
