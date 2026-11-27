import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/auth/presentation/clinic_welcome_screen.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinic_handoff_bridge.dart';
import 'package:mind_forensics/features/clinician/data/clinician_auth_service.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
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

  group('Phase B — Two-Sided Editions & Clean Auth Clinician Portal', () {
    test('Patient edition routes fresh/signed-out user to /auth and blocks /clinician; Clinician edition gates behind /clinician-auth until unlocked', () async {
      addTearDown(() {
        AppEditionConfig.configureForTesting(null);
        ClinicianAuthService.setUnlockedForTesting(false);
      });

      AppEditionConfig.configureForTesting(MindoraEdition.patient);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.home), AppRouter.auth);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.clinician), AppRouter.auth);

      // Signing out blocks return to /home and /clinician even if onboarding was previously completed
      await AuthService().signUpWithEmail('patient@clinic.tn', '123456');
      await AuthService().setOnboardingCompleted(true);
      await AuthService().signOut();
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.home), AppRouter.auth);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.clinician), AppRouter.auth);

      // Doctor Edition: locked session must redirect to /clinician-auth
      AppEditionConfig.configureForTesting(MindoraEdition.clinician);
      ClinicianAuthService.setUnlockedForTesting(false);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.home), AppRouter.clinicianAuth);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.clinician), AppRouter.clinicianAuth);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.clinicianAuth), isNull);

      // Doctor Edition: unlocked session routes cleanly to /clinician
      ClinicianAuthService.setUnlockedForTesting(true);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.home), AppRouter.clinician);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.onboarding), AppRouter.clinician);
      expect(await AppRouter.resolveRedirectForLocation(AppRouter.clinician), isNull);
    });

    test('ClinicianProfile derives stable patient clinic pairing code', () {
      const profile = ClinicianProfile(
        displayName: 'Dr. Salma Ben Amor',
        clinicName: 'Tunis Mindora Practice',
      );
      expect(profile.effectiveClinicCode, startsWith('MIND-'));
      final custom = profile.copyWith(clinicCode: 'CLINIC-99');
      expect(custom.effectiveClinicCode, 'CLINIC-99');
    });

    testWidgets('Clinic QR login transitions from AuthScreen -> ClinicWelcomeScreen -> /home cleanly', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provision = await container
          .read(clinicAuthRepositoryProvider)
          .createPatientAccount(
            doctorId: 'doc_salma',
            clinicId: 'clinic_01',
            doctorName: 'Dr. Salma Ben Amor',
            clinicName: 'Tunis Mindora Practice',
            displayName: 'Nadia B.',
            loginIdentifier: '22900100',
            ageRange: '25-44',
            preferredLanguage: 'en',
            customTempPin: '998877',
          );

      final router = GoRouter(
        initialLocation: AppRouter.auth,
        routes: [
          GoRoute(
            path: AppRouter.auth,
            builder: (_, _) => const AuthScreen(),
          ),
          GoRoute(
            path: AppRouter.clinicWelcome,
            builder: (_, _) => const ClinicWelcomeScreen(),
          ),
          GoRoute(
            path: AppRouter.home,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('HOME_READY_OK'))),
          ),
        ],
      );

      final fakeContainer = ProviderContainer(
        overrides: [
          clinicHandoffBridgeProvider.overrideWithValue(
            _FakeQrHandoffBridge(provision.qrPayload),
          ),
        ],
      );
      addTearDown(fakeContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: fakeContainer,
          child: MaterialApp.router(
            routerConfig: router,
            theme: buildMindTheme(Brightness.light),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('auth-scan-qr-btn')));
      await tester.pumpAndSettle();

      // Lands on one-time first-login Welcome & Safety screen
      expect(find.text('Welcome, Nadia B.'), findsOneWidget);
      expect(find.text('You are connected to Dr. Salma Ben Amor'), findsOneWidget);
      expect(find.text('Not a 24/7 emergency monitor'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('clinic-welcome-start-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('clinic-welcome-start-btn')),
      );
      await tester.pumpAndSettle();

      expect(find.text('HOME_READY_OK'), findsOneWidget);
      expect(fakeContainer.read(authControllerProvider).hasCompletedOnboarding, isTrue);
    });

    testWidgets('Onboarding Step 4 shows optional clinic pairing code only when seeing a doctor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const en = AppStrings('en');
      await tester.tap(find.text(en.onboardingStartBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.skipBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.skipBtn));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('onboarding-clinic-code-input')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding-care-regular_doctor')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('onboarding-clinic-code-input')),
        findsOneWidget,
      );
    });

    testWidgets('ClinicianShellScreen search bar filters patients cleanly by name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const ClinicianShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nadia B.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Karim M.'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Karim M.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('clinician-patient-search-field')),
        'Nadia',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nadia B.'), findsOneWidget);
      expect(find.text('Karim M.'), findsNothing);
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

class _FakeQrHandoffBridge extends ClinicHandoffBridge {
  const _FakeQrHandoffBridge(this.payload);

  final String payload;

  @override
  Future<void> sharePdfFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {}

  @override
  Future<String?> scanQrCode(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  }) async {
    return payload;
  }
}
