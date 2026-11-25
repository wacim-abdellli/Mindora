import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 12 — Calm Talk & Progressive Patterns UX', () {
    testWidgets('Talk renders single clean AppBar without AI HUB jargon at 320px AR RTL', (
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
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
            home: const FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI HUB'), findsNothing);
      expect(find.text(const AppStrings('ar').navTalk), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Patterns shows 3 calm cards above fold and expands deeper details on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      for (var i = 0; i < 4; i++) {
        await repo.saveTrace(
          MindTraceModel(
            id: 'pat_$i',
            userId: 'u1',
            date: now.subtract(Duration(days: i)),
            overallMood: i.isEven ? 'good' : 'calm',
            moodIntensity: 6,
            selectedEmotions: [i.isEven ? 'good' : 'calm'],
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      await container.read(mindTraceControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const en = AppStrings('en');
      expect(find.text(en.yourWeekHeader), findsOneWidget);
      expect(find.text(en.moodColorsPosterTitle), findsOneWidget);
      expect(find.text(en.seeMoreDetailsBtn), findsOneWidget);
      // Deep chart hidden initially for low cognitive load
      expect(find.text(en.moodTrendsHeader), findsNothing);

      // Expand deeper details on demand
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('patterns-more-details-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('patterns-more-details-btn')),
      );
      await tester.pumpAndSettle();

      expect(find.text(en.hideDetailsBtn), findsOneWidget);
      expect(find.text(en.moodTrendsHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
