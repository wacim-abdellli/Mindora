import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/router/scaffold_with_nav_bar.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/auth/presentation/clinic_welcome_screen.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/mind_qr_scanner_sheet.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';

GoRouter _buildAdaptiveTestRouter({String initialLocation = AppRouter.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.track,
                builder: (_, _) => const TrackScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.companion,
                builder: (_, _) => const Scaffold(body: Text('TalkDest')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.insights,
                builder: (_, _) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.profile,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  const en = AppStrings('en');
  final lightTheme = buildMindTheme(Brightness.light);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6 — Auth Polish, Lockout & QR First-Time PIN Setup', () {
    testWidgets(
      'AuthScreen shows inline validation errors, Forgot PIN help, and enforces 5-attempt lockout cooldown',
      (tester) async {
        tester.view.physicalSize = const Size(430, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(clinicAuthRepositoryProvider)
            .createPatientAccount(
              doctorId: 'doc_p6',
              doctorName: 'Dr. Amine',
              clinicId: 'clinic_p6',
              clinicName: 'Cabinet Carthage',
              displayName: 'Salma',
              loginIdentifier: '+21622000111',
              ageRange: '25-44',
              preferredLanguage: 'en',
              customTempPin: '1234',
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: lightTheme,
              home: const AuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('auth-forgot-pin-help')),
          findsOneWidget,
        );

        // 1. Inline validation on empty submit
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('auth-login-submit-btn')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('auth-login-submit-btn')),
        );
        await tester.pumpAndSettle();

        expect(find.text(en.authIdentifierRequiredError), findsOneWidget);
        expect(find.text(en.authPinTooShortError), findsOneWidget);

        // 2. Five consecutive wrong PIN attempts trigger 30s lockout
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-identifier-field')),
          '+21622000111',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('auth-pin-field')),
          '9999',
        );

        for (var i = 0; i < 5; i++) {
          await tester.tap(
            find.byKey(const ValueKey<String>('auth-login-submit-btn')),
          );
          await tester.pumpAndSettle();
        }

        expect(container.read(authControllerProvider).isLockedOut, isTrue);
        expect(
          find.byKey(const ValueKey<String>('auth-error-banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('wait'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ClinicWelcomeScreen allows QR-signed-in patient to set own PIN directly without Current PIN prompt',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(clinicAuthRepositoryProvider);
        final provision = await repo.createPatientAccount(
          doctorId: 'doc_qr',
          doctorName: 'Dr. Leila',
          clinicId: 'clinic_qr',
          clinicName: 'Clinique El Amen',
          displayName: 'Kamel',
          loginIdentifier: '+21629000222',
          ageRange: '25-44',
          preferredLanguage: 'en',
          customTempPin: '4321',
        );

        // Sign in via single-use QR invite
        final ok = await container
            .read(authControllerProvider.notifier)
            .signInWithClinicQr(provision.qrPayload);
        expect(ok, isTrue);
        expect(container.read(authControllerProvider).signedInViaQr, isTrue);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: lightTheme,
              home: const ClinicWelcomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(en.setOwnPinOptionalBtn));
        await tester.tap(find.text(en.setOwnPinOptionalBtn));
        await tester.pumpAndSettle();

        // QR session must NOT ask for Current PIN
        expect(
          find.byKey(const ValueKey<String>('welcome-current-pin-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('welcome-new-pin-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('welcome-confirm-pin-field')),
          findsOneWidget,
        );

        // Mismatch validation check
        await tester.enterText(
          find.byKey(const ValueKey<String>('welcome-new-pin-field')),
          '5678',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('welcome-confirm-pin-field')),
          '1111',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('welcome-save-pin-btn')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('welcome-save-pin-btn')),
        );
        await tester.pumpAndSettle();
        expect(find.text(en.pinsDoNotMatchError), findsOneWidget);

        // Matching PIN updates credentials without requiring currentPin
        await tester.enterText(
          find.byKey(const ValueKey<String>('welcome-confirm-pin-field')),
          '5678',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('welcome-save-pin-btn')),
        );
        await tester.pumpAndSettle();

        expect(find.text(en.pinChangedToast), findsOneWidget);

        // Verify the newly chosen PIN authenticates
        final signedInWithNewPin = await container
            .read(authControllerProvider.notifier)
            .signInWithClinicCredentials('+21629000222', '5678');
        expect(signedInWithNewPin, isTrue);

        await tester.pump(const Duration(seconds: 4));
      },
    );
  });

  group('Phase 6 — Adaptive NavigationRail & Multi-Viewport Responsive Layouts',
      () {
    testWidgets(
      'ScaffoldWithNavBar uses floating dock on phone (390px) and NavigationRail on desktop (1280px) incl. AR RTL',
      (tester) async {
        // 1. Mobile 390x844 -> bottom dock, NO NavigationRail
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mobileRouter = _buildAdaptiveTestRouter();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: lightTheme,
              routerConfig: mobileRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('patient-nav-rail')),
          findsNothing,
        );
        expect(find.text(en.navToday), findsOneWidget);

        // 2. Desktop 1280x800 -> NavigationRail present & tab navigation works
        tester.view.physicalSize = const Size(1280, 800);
        final desktopRouter = _buildAdaptiveTestRouter();
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            child: MaterialApp.router(
              theme: lightTheme,
              routerConfig: desktopRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('patient-nav-rail')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Navigate via rail to My days -> renders 2-column desktop split
        await tester.tap(find.text(en.navMyDays).first);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('track-desktop-split-layout')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // 3. Arabic RTL Desktop 1024x720 -> zero overflow
        tester.view.physicalSize = const Size(1024, 720);
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            child: MaterialApp.router(
              theme: lightTheme,
              routerConfig: _buildAdaptiveTestRouter(),
              builder: (_, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('patient-nav-rail')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AuthScreen, MindQrScannerSheet, InsightsScreen & SettingsScreen render cleanly at 1440x900 desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: lightTheme,
              home: const AuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            child: MaterialApp(
              theme: lightTheme,
              home: const Scaffold(
                body: MindQrScannerSheet(
                  expectedPrefix: 'MF-CLINIC-V1:',
                  title: 'Scan QR',
                  subtitle: 'Point camera',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            child: MaterialApp(
              theme: lightTheme,
              home: const InsightsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            child: MaterialApp(
              theme: lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
