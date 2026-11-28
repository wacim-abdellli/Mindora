import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_card.dart';
import 'package:mind_forensics/core/widgets/mind_empty_state.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';

class _FixedLocaleController extends LocaleController {
  _FixedLocaleController(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

class _FixedComfortController extends DisplayComfortController {
  _FixedComfortController(this._enabled);
  final bool _enabled;

  @override
  bool build() => _enabled;
}

Future<void> _pumpDesktopMatrixScreen(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required Locale locale,
  required ThemeMode themeMode,
  double textScale = 1.0,
  bool comfortMode = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'mind_forensics_locale': locale.languageCode,
    'mf_onboarding_completed': true,
    'mf_clinician_demo_preview': true,
  });

  final errors = <FlutterErrorDetails>[];
  final prevOnError = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  try {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          localeControllerProvider.overrideWith(
            () => _FixedLocaleController(locale),
          ),
          displayComfortProvider.overrideWith(
            () => _FixedComfortController(comfortMode),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildMindTheme(
            Brightness.light,
            tokensOverride: MindTokens.light.withComfortBoost(comfortMode),
            isArabic: locale.languageCode == 'ar',
          ),
          darkTheme: buildMindTheme(
            Brightness.dark,
            tokensOverride: MindTokens.dark.withComfortBoost(comfortMode),
            isArabic: locale.languageCode == 'ar',
          ),
          themeMode: themeMode,
          builder: (context, appChild) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: appChild!,
            ),
          ),
          home: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      errors,
      isEmpty,
      reason:
          'Unexpected error at $size locale=${locale.languageCode} theme=$themeMode scale=$textScale:\n${errors.map((e) => e.exceptionAsString()).join('\n')}',
    );
    expect(tester.takeException(), isNull);
  } finally {
    FlutterError.onError = prevOnError;
    tester.view.reset();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 7 — Pre-User Cloud Backend, Security Rules & Launch Gate', () {
    test('Default ClinicBackendConfig stays on offline Spark-safe simulator', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(clinicBackendConfigProvider);
      expect(config.mode, ClinicBackendMode.offlineSimulator);
      expect(config.isOfflineSimulator, isTrue);
      expect(config.isProductionLaunchGateSatisfied, isTrue);
    });

    test('Production backend mode blocks unverified billing or missing AI proxy', () {
      const missingBilling = ClinicBackendConfig(
        mode: ClinicBackendMode.firebaseProduction,
        paidAiBillingVerified: false,
        aiProxyUrl: 'https://region-proj.cloudfunctions.net/aiCompanionProxy',
      );
      expect(missingBilling.isProductionLaunchGateSatisfied, isFalse);

      const missingProxy = ClinicBackendConfig(
        mode: ClinicBackendMode.firebaseProduction,
        paidAiBillingVerified: true,
        aiProxyUrl: '',
      );
      expect(missingProxy.isProductionLaunchGateSatisfied, isFalse);

      const ready = ClinicBackendConfig(
        mode: ClinicBackendMode.firebaseProduction,
        paidAiBillingVerified: true,
        aiProxyUrl: 'https://region-proj.cloudfunctions.net/aiCompanionProxy',
      );
      expect(ready.isProductionLaunchGateSatisfied, isTrue);
    });

    test('Firebase rules, Cloud Functions proxy, and Launch Checklist enforce isolation & billing gates', () {
      final rules = File('firebase/firestore.rules').readAsStringSync();
      expect(rules, contains("request.auth.token.role == 'clinician'"));
      expect(rules, contains('request.auth.token.clinicId == clinicId'));
      expect(rules, contains("data.status != 'paused'"));
      expect(rules, contains('request.resource.data.containsPrivateEntries == false'));
      expect(rules, contains('allow update, delete: if false;'));

      final functionsJs = File('firebase/functions/index.js').readAsStringSync();
      expect(functionsJs, contains('exports.provisionPatientAccount'));
      expect(functionsJs, contains('exports.exchangeQrInvite'));
      expect(functionsJs, contains('exports.setPatientAccessStatus'));
      expect(functionsJs, contains('exports.aiCompanionProxy'));
      expect(functionsJs, contains('revokeRefreshTokens'));
      expect(functionsJs, contains('GEMINI_PAID_API_KEY'));
      expect(functionsJs, contains('body.isPrivate === true'));

      final checklist = File('docs/PRODUCTION_LAUNCH_CHECKLIST.md').readAsStringSync();
      expect(checklist, contains('Steps 10 & 14'));
      expect(checklist, contains('human reviewers'));
      expect(checklist, contains('50%, 80%, and 100%'));
      expect(checklist, contains('Blaze'));
    });
  });

  group('Phase 7 — Desktop (1280x800 & 1440x900) & WCAG Contrast QA Matrix', () {
    testWidgets('Core design primitives meet Flutter textContrastGuideline in Light & Dark', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildMindTheme(brightness),
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MindCard(
                          padding: const EdgeInsets.all(16),
                          child: const MindEmptyState(
                            icon: Icons.spa_outlined,
                            title: 'No entries yet',
                            subtitle: 'Log one small moment when you feel ready.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        MindButton(
                          text: 'Save check-in',
                          onPressed: () {},
                        ),
                        const SizedBox(height: 10),
                        MindButton(
                          text: 'Delete note',
                          variant: MindButtonVariant.danger,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          handle.dispose();
        }
      }
    });

    final desktopScreens = <({String name, Widget Function() build})>[
      (name: 'HomeScreen', build: () => const HomeScreen()),
      (name: 'TrackScreen', build: () => const TrackScreen()),
      (name: 'FlashCaseScreen', build: () => const FlashCaseScreen()),
      (name: 'InsightsScreen', build: () => const InsightsScreen()),
      (name: 'SettingsScreen', build: () => const SettingsScreen()),
      (
        name: 'PsychologicalProfileScreen',
        build: () => const PsychologicalProfileScreen(),
      ),
      (
        name: 'ClinicianPatientDetailScreen',
        build: () => const ClinicianPatientDetailScreen(patientId: 'demo_nadia_b'),
      ),
    ];

    for (final entry in desktopScreens) {
      testWidgets('${entry.name} renders cleanly at 1280x800 Light EN', (tester) async {
        await _pumpDesktopMatrixScreen(
          tester,
          child: entry.build(),
          size: const Size(1280, 800),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        );
      });

      testWidgets('${entry.name} renders cleanly at 1440x900 Dark FR & 2.0x AR RTL', (tester) async {
        await _pumpDesktopMatrixScreen(
          tester,
          child: entry.build(),
          size: const Size(1440, 900),
          locale: const Locale('fr'),
          themeMode: ThemeMode.dark,
        );

        await _pumpDesktopMatrixScreen(
          tester,
          child: entry.build(),
          size: const Size(1440, 900),
          locale: const Locale('ar'),
          themeMode: ThemeMode.light,
          textScale: 2.0,
          comfortMode: true,
        );
      });
    }

    testWidgets('ClinicianShellScreen switches cleanly across Overview, Patients, and Practice tabs at 1440x900 AR RTL & EN Dark', (tester) async {
      await _pumpDesktopMatrixScreen(
        tester,
        child: const ClinicianShellScreen(),
        size: const Size(1440, 900),
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 1.5,
      );

      const ar = AppStrings('ar');
      await tester.tap(find.text(ar.clinicianTabOverview).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(ar.clinicianTabPractice).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
