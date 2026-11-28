import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/case_file/presentation/case_report_screen.dart';
import '../../features/clinician/data/clinician_auth_service.dart';
import '../../features/clinician/presentation/clinician_auth_screen.dart';
import '../../features/clinician/presentation/clinician_patient_detail_screen.dart';
import '../../features/clinician/presentation/clinician_shell_screen.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/clinic_welcome_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/investigation/presentation/flash_case_screen.dart';
import '../../features/observatory/presentation/inner_observatory_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/psychological_profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import '../config/app_edition.dart';
import 'scaffold_with_nav_bar.dart';

/// App router configuration using GoRouter with 5 persistent bottom tabs:
/// Home, Track, Inner Observatory (Explore & Investigator), Insights, Profile.
class AppRouter {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String clinicWelcome = '/clinic-welcome';
  static const String home = '/home';
  static const String journal = '/journal';
  static const String investigator = '/investigation';
  static const String observatory = '/observatory';
  static const String toolkit = '/toolkit';
  static const String profile = '/profile';
  static const String caseReport = '/case/:id';
  static const String mindTrace = '/mind-trace';
  static const String progress = '/progress';
  static const String track = '/track';
  static const String insights = '/insights';
  static const String companion = '/companion';
  static const String clinicianAuth = '/clinician-auth';
  static const String clinician = '/clinician';
  static const String clinicianPatient = '/clinician/patient/:id';

  /// Whether first-launch gating redirects new users to /onboarding.
  static bool enableFirstLaunchGating = true;

  // Legacy route aliases for backward compatibility
  static const String tools = '/toolkit';
  static const String settings = '/profile';
  static const String investigation = '/investigation';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorHomeKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final GlobalKey<NavigatorState> _shellNavigatorTrackKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellTrack');
  static final GlobalKey<NavigatorState> _shellNavigatorCompanionKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellCompanion');
  static final GlobalKey<NavigatorState> _shellNavigatorInsightsKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellInsights');
  static final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  /// Resolves startup redirect rules cleanly across Patient and Doctor editions.
  static Future<String?> resolveRedirectForLocation(
    String matchedLocation,
  ) async {
    if (!enableFirstLaunchGating) return null;

    final isGoingToOnboarding = matchedLocation == onboarding;
    final isGoingToAuth = matchedLocation == auth;
    final isGoingToWelcome = matchedLocation == clinicWelcome;
    final isGoingToClinicianAuth = matchedLocation == clinicianAuth;
    final isGoingToClinician = matchedLocation.startsWith(clinician);

    // Dedicated Doctor / Admin edition gates all patient dossiers behind
    // explicit clinician PIN/biometric unlock before entering `/clinician`.
    if (AppEditionConfig.isClinicianApp) {
      if (!ClinicianAuthService.isSessionUnlocked) {
        return isGoingToClinicianAuth ? null : clinicianAuth;
      }
      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('mf_clinician_demo_preview') == true) {
          return null;
        }
      }
      if (isGoingToClinicianAuth || !isGoingToClinician) {
        return clinician;
      }
      return null;
    }

    // Strict Patient Edition role isolation: never expose clinician routes
    // inside the Patient binary, even unauthenticated or via deep link.
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('mf_auth_current_user');
    final signedOut = prefs.getBool('mf_signed_out') ?? false;
    final hasCompleted = prefs.getBool('mf_onboarding_completed') ?? false;

    if (signedOut || rawUser == null) {
      return isGoingToAuth ? null : auth;
    }

    if (isGoingToClinician || isGoingToClinicianAuth) {
      return hasCompleted ? home : clinicWelcome;
    }

    if (!hasCompleted) {
      bool isClinicUser = false;
      try {
        isClinicUser = AuthUser.fromJson(rawUser).isClinicAccount;
      } catch (_) {}
      final target = isClinicUser ? clinicWelcome : onboarding;
      if (matchedLocation != target && !isGoingToAuth) {
        return target;
      }
      return null;
    }

    // Completed returning patients go straight to Home
    if (isGoingToOnboarding || isGoingToWelcome || isGoingToAuth) {
      return home;
    }
    return null;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppEditionConfig.isClinicianApp ? clinician : home,
    redirect: (context, state) =>
        resolveRedirectForLocation(state.matchedLocation),
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: clinicWelcome,
        name: 'clinicWelcome',
        builder: (context, state) => const ClinicWelcomeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: caseReport,
        name: 'caseReport',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CaseReportScreen(caseId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/conditions',
        name: 'profileConditions',
        builder: (context, state) => const PsychologicalProfileScreen(),
      ),
      GoRoute(
        path: mindTrace,
        name: 'mindTrace',
        redirect: (context, state) => track,
      ),
      GoRoute(
        path: progress,
        name: 'progress',
        redirect: (context, state) => track,
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: observatory,
        name: 'observatory',
        builder: (context, state) => const InnerObservatoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: clinicianAuth,
        name: 'clinicianAuth',
        builder: (context, state) => const ClinicianAuthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: clinician,
        name: 'clinician',
        builder: (context, state) => const ClinicianShellScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: clinicianPatient,
        name: 'clinicianPatient',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ClinicianPatientDetailScreen(patientId: id);
        },
      ),

      // Route aliases for backward compatibility
      GoRoute(
        path: '/journal',
        redirect: (context, state) => home,
      ),
      GoRoute(
        path: '/check-in',
        redirect: (context, state) => track,
      ),
      GoRoute(
        path: '/investigation',
        redirect: (context, state) => companion,
      ),
      GoRoute(
        path: '/tools',
        redirect: (context, state) => observatory,
      ),
      GoRoute(
        path: '/toolkit',
        redirect: (context, state) => observatory,
      ),
      GoRoute(
        path: '/settings',
        redirect: (context, state) => profile,
      ),

      // Persistent 5-Tab Bottom Navigation Shell (Master Reference):
      // Home, Track, Inner Observatory (Center), Insights, Profile.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Track & Self-Observation
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTrackKey,
            routes: [
              GoRoute(
                path: track,
                name: 'track_nav',
                builder: (context, state) {
                  final tabIndex =
                      int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                  final startNewMoment =
                      state.uri.queryParameters['newMoment'] == '1';
                  final dateKey = state.uri.queryParameters['date'];
                  return TrackScreen(
                    initialTab: tabIndex.clamp(0, 1),
                    startNewMoment: startNewMoment,
                    initialDateKey: dateKey,
                  );
                },
              ),
            ],
          ),

          // Branch 2: AI Guide (Center prominent)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCompanionKey,
            routes: [
              GoRoute(
                path: companion,
                name: 'companion',
                builder: (context, state) => FlashCaseScreen(
                  initialHubView: state.uri.queryParameters['view'] == 'hub',
                ),
              ),
            ],
          ),

          // Branch 3: Insights & Pattern Understanding
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInsightsKey,
            routes: [
              GoRoute(
                path: insights,
                name: 'insights_nav',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),

          // Branch 4: Profile & Preferences
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: profile,
                name: 'profile',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
