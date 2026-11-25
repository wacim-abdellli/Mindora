import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_clinical_pulse_card.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/onboarding/domain/app_personalization_engine.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Phase B — AppPersonalizationEngine Decision Rules', () {
    test('routes clinician role straight to clinician_workspace', () {
      final profile = PsychologicalProfileModel(
        userRole: 'clinician',
        updatedAt: DateTime.now(),
      );
      final plan = AppPersonalizationEngine.resolve(profile);
      expect(plan.isClinician, isTrue);
      expect(plan.primaryNextActionKey, 'clinician_workspace');
    });

    test('recommends Comfort Mode for 65+ and prioritizes Doctor + Sleep pulse', () {
      final profile = PsychologicalProfileModel(
        userRole: 'patient',
        ageRange: '65+',
        careContext: 'regular_doctor',
        selectedGoals: const ['doctor_visits', 'track_mood_sleep'],
        focusAreas: const ['sleep', 'routine'],
        updatedAt: DateTime.now(),
      );
      final plan = AppPersonalizationEngine.resolve(profile);
      expect(plan.recommendComfortMode, isTrue);
      expect(plan.isDoctorFollowed, isTrue);
      expect(plan.prioritizeSleepPulse, isTrue);
      expect(plan.showRoutineAnchorQuestion, isTrue);
      expect(plan.primaryNextActionKey, 'doctor_visit_ready');
    });
  });

  group('Phase B — Onboarding Role Gate Routes Doctor Straight to /clinician', () {
    testWidgets('tapping I am a Doctor / Psychiatrist navigates to /clinician', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRouter.onboarding,
        routes: [
          GoRoute(
            path: AppRouter.onboarding,
            builder: (_, _) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppRouter.clinician,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('CLINICIAN_PORTAL_OK'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: buildMindTheme(Brightness.light),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance from Step 1 (Language/Theme/Comfort) to Step 2 (Role Gate)
      await tester.tap(find.text(const AppStrings('en').onboardingStartBtn));
      await tester.pumpAndSettle();

      final doctorCard = find.byKey(const ValueKey('onboarding-role-clinician'));
      expect(doctorCard, findsOneWidget);

      await tester.tap(doctorCard);
      await tester.pumpAndSettle();

      expect(find.text('CLINICIAN_PORTAL_OK'), findsOneWidget);
    });
  });

  group('Phase C — HomeClinicalPulseCard Zero-Typing Capture & 320px AR RTL', () {
    testWidgets('Morning & Evening pulse capture clinical metrics in 1 tap with zero overflow', (
      tester,
    ) async {
      MindTraceModel? latestTrace;
      const stringsEn = AppStrings('en');
      final plan = AppPersonalizationEngine.resolve(
        PsychologicalProfileModel(
          careContext: 'regular_doctor',
          focusAreas: const ['sleep', 'routine'],
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.dark),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (ctx, setState) => HomeClinicalPulseCard(
                  tokens: MindTokens.dark,
                  strings: stringsEn,
                  plan: plan,
                  todayTrace: latestTrace,
                  overrideHour: 9,
                  onUpdateTrace: (updater) async {
                    setState(() => latestTrace = updater(latestTrace));
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pulse-sleep-7to8')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pulse-energy-steady')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pulse-routine-yes')));
      await tester.pumpAndSettle();

      expect(latestTrace?.sleepHours, 7.5);
      expect(latestTrace?.energyLevel, 7);
      expect(latestTrace?.dynamicAnswers['routine_adherence'], 'yes');
      expect(latestTrace?.contextTags, containsAll(['sleep_consistent', 'routine_kept']));

      // Evening 320x640 AR RTL 2.0x text scale overflow audit
      final errors = <FlutterErrorDetails>[];
      final prevErr = FlutterError.onError;
      FlutterError.onError = errors.add;
      await tester.binding.setSurfaceSize(const Size(320, 640));
      try {
        const stringsAr = AppStrings('ar');
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: Directionality(textDirection: TextDirection.rtl, child: child!),
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HomeClinicalPulseCard(
                  tokens: MindTokens.light,
                  strings: stringsAr,
                  plan: plan,
                  todayTrace: null,
                  overrideHour: 20,
                  onUpdateTrace: (_) async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = prevErr;
        await tester.binding.setSurfaceSize(null);
      }

      expect(errors, isEmpty);
    });
  });
}
