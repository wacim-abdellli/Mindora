import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget _personaHarness({
  required Widget child,
  required Locale locale,
  required bool comfortMode,
  required ThemeMode themeMode,
  required double textScale,
}) {
  return ProviderScope(
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
  );
}

Future<void> _pumpAndAssertClean(
  WidgetTester tester, {
  required Size size,
  required Widget widget,
}) async {
  final errors = <FlutterErrorDetails>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };
  await tester.binding.setSurfaceSize(size);

  try {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  } finally {
    FlutterError.onError = previousOnError;
    await tester.binding.setSurfaceSize(null);
  }

  expect(
    errors,
    isEmpty,
    reason:
        'Unexpected FlutterError / RenderFlex overflow:\n${errors.map((e) => e.exceptionAsString()).join('\n')}',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Dual-Persona VQA — Amel (68yo, 320x640, 2.0x AR RTL, Sunrise)', () {
    final screens = <String, Widget Function()>{
      'OnboardingScreen': () => const OnboardingScreen(),
      'HomeScreen (Today)': () => const HomeScreen(),
      'TrackScreen (My days)': () => const TrackScreen(),
      'FlashCaseScreen (Talk)': () => const FlashCaseScreen(),
      'InsightsScreen (Patterns)': () => const InsightsScreen(),
      'SettingsScreen (Me)': () => const SettingsScreen(),
      'ClinicianShellScreen': () => const ClinicianShellScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders with zero overflow for Amel 68yo', (
        tester,
      ) async {
        await _pumpAndAssertClean(
          tester,
          size: const Size(320, 640),
          widget: _personaHarness(
            child: entry.value(),
            locale: const Locale('ar'),
            comfortMode: true,
            themeMode: ThemeMode.light,
            textScale: 2.0,
          ),
        );
      });
    }
  });

  group('Dual-Persona VQA — Yassine (19yo, 412x915, EN Sunrise & FR Twilight)', () {
    testWidgets('HomeScreen renders 6 MoodFace tiles cleanly in Sunrise & Twilight', (
      tester,
    ) async {
      await _pumpAndAssertClean(
        tester,
        size: const Size(412, 915),
        widget: _personaHarness(
          child: const HomeScreen(),
          locale: const Locale('en'),
          comfortMode: false,
          themeMode: ThemeMode.light,
          textScale: 1.0,
        ),
      );
      expect(find.byType(MoodFace), findsAtLeastNWidgets(6));

      await _pumpAndAssertClean(
        tester,
        size: const Size(412, 915),
        widget: _personaHarness(
          child: const HomeScreen(),
          locale: const Locale('fr'),
          comfortMode: false,
          themeMode: ThemeMode.dark,
          textScale: 1.0,
        ),
      );
      expect(find.byType(MoodFace), findsAtLeastNWidgets(6));
    });

    testWidgets('SettingsScreen stays minimalist without clinician or JSON clutter', (
      tester,
    ) async {
      await _pumpAndAssertClean(
        tester,
        size: const Size(412, 915),
        widget: _personaHarness(
          child: const SettingsScreen(),
          locale: const Locale('en'),
          comfortMode: false,
          themeMode: ThemeMode.light,
          textScale: 1.0,
        ),
      );

      const en = AppStrings('en');
      expect(find.byKey(const ValueKey('me-advanced-accordion')), findsNothing);
      expect(find.text('Psychiatrist Workspace'), findsNothing);
      expect(find.text(en.backupNowBtn), findsNothing);
      expect(find.text(en.privacyAccountSection), findsOneWidget);
      expect(find.text(en.logOutBtn), findsOneWidget);
    });
  });
}
