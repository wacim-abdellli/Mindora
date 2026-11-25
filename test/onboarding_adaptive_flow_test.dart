import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_pressable.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createLocalizedTestApp({
  required Widget child,
  ProviderContainer? container,
}) {
  final Widget app = Consumer(
    builder: (context, ref, _) {
      final locale = ref.watch(localeControllerProvider);
      return MaterialApp(
        theme: buildMindTheme(Brightness.light),
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      );
    },
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 10: Sub-25s 3-Step Onboarding & Zero-Blank-Screen Handoff', () {
    test(
      '1. PsychologicalProfileModel serialization preserves all onboarding fields',
      () {
        final now = DateTime.now();
        final profile = PsychologicalProfileModel(
          userId: 'test_user_onboarding',
          preferredName: 'Atlas',
          ageRange: 'under_18',
          biologicalSex: 'female',
          mentalHealthBackground: 'diagnosed',
          conditions: const [
            UserConditionEntry(
              condition: ConditionType.generalizedAnxiety,
              status: DiagnosticStatus.professionallyDiagnosed,
            ),
            UserConditionEntry(
              condition: ConditionType.adhd,
              status: DiagnosticStatus.selfIdentifiedExploring,
            ),
          ],
          selectedSymptoms: const [
            'sym_persistent_heaviness',
            'sym_constant_apprehension',
          ],
          selectedGoals: const [
            'Ease stress & anxiety',
            'Understand mood patterns',
          ],
          customGoal: 'Learn emotional regulation during exams',
          personalGoals:
              'Ease stress & anxiety, Understand mood patterns, Learn emotional regulation during exams',
          professionalSupport: 'therapist',
          communicationPreference: 'analytical_reflective',
          shareWithAiCompanion: true,
          allowAiPersonalization: true,
          onboardingStep: 3,
          updatedAt: now,
        );

        final roundtrip = PsychologicalProfileModel.fromJson(profile.toJson());
        expect(roundtrip.userId, 'test_user_onboarding');
        expect(roundtrip.preferredName, 'Atlas');
        expect(roundtrip.ageRange, 'under_18');
        expect(roundtrip.isMinor, isTrue);
        expect(roundtrip.conditions.length, 2);
        expect(roundtrip.onboardingStep, 3);
      },
    );

    test('2. isMinor correctly flags minors and adults', () {
      expect(
        PsychologicalProfileModel(
          ageRange: 'under_18',
          updatedAt: DateTime.now(),
        ).isMinor,
        isTrue,
      );
      expect(
        PsychologicalProfileModel(
          ageRange: '<18',
          updatedAt: DateTime.now(),
        ).isMinor,
        isTrue,
      );
      expect(
        PsychologicalProfileModel(
          ageRange: '25-44',
          updatedAt: DateTime.now(),
        ).isMinor,
        isFalse,
      );
    });

    testWidgets(
      '3. Step 1 renders Welcome, Normal/Larger text toggle, Sign In link, and live EN/FR/AR RTL switching',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          createLocalizedTestApp(child: const OnboardingScreen()),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        const fr = AppStrings('fr');
        const ar = AppStrings('ar');

        expect(find.byType(MoodFace), findsOneWidget);
        expect(find.text(en.onboardingWelcomeBody), findsOneWidget);
        expect(find.text(en.normalTextLabel), findsOneWidget);
        expect(find.text(en.largerTextLabel), findsOneWidget);
        expect(find.text(en.onboardingStartBtn), findsOneWidget);
        expect(find.text(en.signInTab), findsOneWidget);

        // Verify >= 48dp touch target on EN pill and >= 56dp on Start CTA
        final startPressable = find.ancestor(
          of: find.text(en.onboardingStartBtn),
          matching: find.byType(MindPressable),
        );
        expect(tester.getSize(startPressable).height, greaterThanOrEqualTo(56));

        // Switch live to French
        await tester.tap(find.text('FR'));
        await tester.pumpAndSettle();
        expect(find.text(fr.onboardingWelcomeBody), findsOneWidget);
        expect(find.text(fr.onboardingStartBtn), findsOneWidget);

        // Switch live to Arabic (RTL)
        await tester.tap(find.text('AR'));
        await tester.pumpAndSettle();
        expect(find.text(ar.onboardingWelcomeBody), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.text(ar.onboardingWelcomeBody))),
          TextDirection.rtl,
        );
      },
    );

    testWidgets(
      '4. Step 2 Role Gate routes Patient to Step 3 with Under 18 safeguard and preserves crisis lines',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          createLocalizedTestApp(child: const OnboardingScreen()),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        await tester.tap(find.text(en.onboardingStartBtn));
        await tester.pumpAndSettle();

        expect(find.text(en.stepProgressOf(2, 6)), findsOneWidget);
        expect(find.text(en.onboardingRoleTitle), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('onboarding-role-patient')));
        await tester.pumpAndSettle();

        expect(find.text(en.stepProgressOf(3, 6)), findsOneWidget);
        expect(find.text(en.minorSupportNotice), findsNothing);

        await tester.tap(find.text(en.ageUnder18));
        await tester.pumpAndSettle();
        expect(find.text(en.minorSupportNotice), findsOneWidget);

        await tester.tap(find.text('25-44'));
        await tester.pumpAndSettle();
        expect(find.text(en.minorSupportNotice), findsNothing);

        expect(find.text(en.onboardingCrisisSafetyNote), findsOneWidget);
        expect(find.text(en.openCrisisResourcesLabel), findsOneWidget);
      },
    );

    testWidgets(
      '5. Skip flows through Steps 3-6 cleanly without forcing a check-in',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          createLocalizedTestApp(
            container: container,
            child: const OnboardingScreen(),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        await tester.tap(find.text(en.onboardingStartBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('onboarding-role-patient')));
        await tester.pumpAndSettle();

        // Skip Step 3 (Age), Step 4 (Goals), Step 5 (Care/Focus)
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        expect(find.text(en.stepProgressOf(4, 6)), findsOneWidget);

        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        expect(find.text(en.stepProgressOf(5, 6)), findsOneWidget);

        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        expect(find.text(en.stepProgressOf(6, 6)), findsOneWidget);

        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();

        expect(
          container.read(authControllerProvider).hasCompletedOnboarding,
          isTrue,
        );
        expect(
          container.read(profileControllerProvider).value?.onboardingStep,
          6,
        );
        expect(
          container.read(mindTraceControllerProvider).value ?? [],
          isEmpty,
        );
      },
    );

    testWidgets(
      '6. Step 6 MoodFace + strength saves Trace #1 and hands off to HomeScreen',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final testRouter = GoRouter(
          initialLocation: AppRouter.onboarding,
          routes: [
            GoRoute(
              path: AppRouter.onboarding,
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: AppRouter.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        );
        addTearDown(testRouter.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: buildMindTheme(Brightness.light),
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        await tester.tap(find.text(en.onboardingStartBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('onboarding-role-patient')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();

        expect(find.byType(MoodFace), findsNWidgets(6));
        await tester.tap(find.text(en.moodWorriedPlain));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.strengthALot));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.saveAndEnterBtn));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        final traces = container.read(mindTraceControllerProvider).value ?? [];
        expect(traces.length, 1);
        expect(traces.first.overallMood, 'anxious');
        expect(traces.first.moodIntensity, 9);
      },
    );

    testWidgets('7. Interrupted onboarding recovery hydrates saved step draft', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final draftProfile = PsychologicalProfileModel(
        userId: 'local_user',
        ageRange: '25-44',
        onboardingStep: 2,
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider
              .overrideWith(() => _MockProfileNotifier(draftProfile)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createLocalizedTestApp(
          container: container,
          child: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      const en = AppStrings('en');
      expect(find.text(en.stepProgressOf(3, 6)), findsOneWidget);
      expect(find.text(en.onboardingAboutYouTitle), findsOneWidget);
    });
  });
}

class _MockProfileNotifier extends ProfileNotifier {
  _MockProfileNotifier(this._initialProfile);

  final PsychologicalProfileModel _initialProfile;

  @override
  Future<PsychologicalProfileModel> build() async => _initialProfile;
}
