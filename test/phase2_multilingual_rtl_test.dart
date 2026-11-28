import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/localization/mind_formatters.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/app/theme/theme_controller.dart';
import 'package:mind_forensics/core/security/app_lock_provider.dart';
import 'package:mind_forensics/core/security/biometric_service.dart';
import 'package:mind_forensics/core/security/lock_overlay.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/presentation/clinic_welcome_screen.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_weekly_rhythm_card.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_month_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AlwaysLockedAppLockNotifier extends AppLockNotifier {
  @override
  AppLockState build() => const AppLockState(
        isEnabled: true,
        isLocked: true,
        isInitialized: true,
      );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'mf_onboarding_completed': true,
      'mf_auth_current_user':
          '{"id":"p_rtl","codename":"Amel","authType":"clinicPin","clinicId":"cln_1","doctorId":"doc_1","doctorName":"Dr. Salma","createdAt":"2026-01-01T00:00:00.000"}',
    });
  });

  group('Phase 2: Pre-Loaded Locale Boot & Formatters', () {
    test('LocaleController.loadInitialLocale hydrates synchronously with zero EN flash', () async {
      SharedPreferences.setMockInitialValues({'mind_forensics_locale': 'ar'});
      final preloaded = await LocaleController.loadInitialLocale();
      expect(preloaded, const Locale('ar'));

      final container = ProviderContainer(
        overrides: [initialLocaleProvider.overrideWithValue(preloaded)],
      );
      addTearDown(container.dispose);

      // Synchronous read on frame 0 is already Arabic (no async flash from EN)
      expect(container.read(localeControllerProvider), const Locale('ar'));
      expect(container.read(appStringsProvider).isArabic, isTrue);
    });

    test('MindFormatters formats decimals, hours, plurals, arrows & LTR isolates per locale', () {
      const en = AppStrings('en');
      const fr = AppStrings('fr');
      const ar = AppStrings('ar');

      expect(MindFormatters.hours(6.5, en), '6.5h');
      expect(MindFormatters.hours(6.5, fr), '6,5 h');
      expect(MindFormatters.hours(6.5, ar), '\u20666.5\u2069 س');

      expect(MindFormatters.signedDelta(-1.2, en, unit: 'h'), '\u2066-1.2\u2069h');
      expect(MindFormatters.signedDelta(1.4, fr), '\u2066+1,4\u2069');
      expect(MindFormatters.signedDelta(-0.8, ar, unit: 'h'), '\u2066-0.8\u2069 س');

      expect(MindFormatters.times(1, ar), 'مرة واحدة');
      expect(MindFormatters.times(2, ar), 'مرتان');
      expect(MindFormatters.times(5, ar), '5 مرات');
      expect(MindFormatters.times(3, fr), '3×');

      expect(MindFormatters.daysShort(2, ar), 'يومان');
      expect(MindFormatters.daysShort(7, fr), '7 j');

      expect(MindFormatters.rangeArrow(en), '→');
      expect(MindFormatters.rangeArrow(ar), '←');
    });
  });

  group('Phase 2: Exhaustive EN/FR/AR Errors, EHR Brief & ConversationMode', () {
    test('All ClinicAuthErrorCode & ClinicianSyncErrorCode values map cleanly in EN/FR/AR', () {
      const en = AppStrings('en');
      const fr = AppStrings('fr');
      const ar = AppStrings('ar');

      for (final code in ClinicAuthErrorCode.values) {
        final enMsg = en.localizedClinicAuthError(code);
        final frMsg = fr.localizedClinicAuthError(code);
        final arMsg = ar.localizedClinicAuthError(code);
        expect(enMsg, isNotEmpty);
        expect(frMsg, isNotEmpty);
        expect(arMsg, isNotEmpty);
        expect(frMsg, isNot(equals(enMsg)));
        expect(arMsg, isNot(equals(enMsg)));
      }

      for (final code in ClinicianSyncErrorCode.values) {
        final enMsg = en.localizedClinicianSyncError(code);
        final frMsg = fr.localizedClinicianSyncError(code);
        final arMsg = ar.localizedClinicianSyncError(code);
        expect(enMsg, isNotEmpty);
        expect(frMsg, isNotEmpty);
        expect(arMsg, isNotEmpty);
        expect(frMsg, isNot(equals(enMsg)));
        expect(arMsg, isNot(equals(enMsg)));
      }
    });

    test('AuthController emits French and Arabic error messages for invalid clinic credentials', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.french);
      final okFr = await container
          .read(authControllerProvider.notifier)
          .signInWithClinicCredentials('unknown_id', '0000');
      expect(okFr, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        const AppStrings('fr').localizedClinicAuthError(
          ClinicAuthErrorCode.invalidCredentials,
        ),
      );

      await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.arabic);
      final okAr = await container
          .read(authControllerProvider.notifier)
          .signInWithClinicCredentials('unknown_id', '0000');
      expect(okAr, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        const AppStrings('ar').localizedClinicAuthError(
          ClinicAuthErrorCode.invalidCredentials,
        ),
      );
    });

    test('generateEhrClinicalNote renders full French and Arabic briefs without English section leaks', () {
      const sync = ClinicianSyncService();
      final demoRecord = DemoClinicalCohort.buildRecords().first;

      final frNote = sync.generateEhrClinicalNote(demoRecord, const AppStrings('fr'));
      expect(frNote, contains('SYNTHÈSE CLINIQUE DE CONSULTATION'));
      expect(frNote, contains('[2] 7 DERNIERS JOURS VS REPÈRE PERSONNEL'));
      expect(frNote, contains('Durée du sommeil'));
      expect(frNote, isNot(contains('[4] OBJECTIVE BASELINE SHIFTS')));
      expect(frNote, isNot(contains('PRE-VISIT CONSULTATION AGENDA')));

      final arNote = sync.generateEhrClinicalNote(demoRecord, const AppStrings('ar'));
      expect(arNote, contains('ملخص استشارة سريري'));
      expect(arNote, contains('[2] مقارنة آخر 7 أيام بالمرجع الشخصي'));
      expect(arNote, contains('مدّة النوم'));
      expect(arNote, isNot(contains('[4] OBJECTIVE BASELINE SHIFTS')));
      expect(arNote, isNot(contains('CLINICAL CONSULTATION SUMMARY')));
    });

    test('ConversationMode and startNewCase localize opening prompts in French and Arabic', () async {
      const fr = AppStrings('fr');
      const ar = AppStrings('ar');

      for (final mode in ConversationMode.values) {
        expect(mode.localizedTitle(fr), isNot(mode.displayName));
        expect(mode.localizedTitle(ar), isNot(mode.displayName));
        expect(mode.localizedOpeningQuestion(fr), isNot(mode.openingQuestion));
        expect(mode.localizedOpeningQuestion(ar), isNot(mode.openingQuestion));
      }

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.arabic);
      final created = await container
          .read(activeCaseControllerProvider.notifier)
          .startNewCase('', mode: ConversationMode.exploreThought);
      expect(
        created.statements.first.text,
        ConversationMode.exploreThought.localizedOpeningQuestion(ar),
      );
      expect(
        created.title,
        ConversationMode.exploreThought.localizedTitle(ar),
      );
    });
  });

  group('Phase 2: Doctor Portal Language/Display Controls & RTL Integrity', () {
    testWidgets('Doctor Practice tab switches EN/FR/AR, theme & comfort mode cleanly', (tester) async {
      tester.view.physicalSize = const Size(1200, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeControllerProvider);
              return MaterialApp(
                locale: locale,
                supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: buildMindTheme(
                  Brightness.light,
                  isArabic: locale.languageCode == 'ar',
                ),
                home: const ClinicianShellScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick rail language toggle cycles EN -> FR -> AR
      final railLangBtn = find.byKey(const ValueKey<String>('clinician-rail-lang-btn'));
      expect(railLangBtn, findsOneWidget);
      await tester.tap(railLangBtn);
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), const Locale('fr'));

      // Navigate to Practice tab ('Cabinet' in FR)
      await tester.tap(find.text(const AppStrings('fr').clinicianTabPractice));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('clinician-language-segmented')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('clinician-theme-segmented')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('clinician-comfort-switch')), findsOneWidget);

      // Switch to Arabic in Practice card -> RTL directionality activates
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), const Locale('ar'));
      expect(
        Directionality.of(tester.element(find.byType(ClinicianShellScreen))),
        TextDirection.rtl,
      );

      // Toggle comfort mode and dark theme from Doctor Practice card
      await tester.tap(find.byKey(const ValueKey<String>('clinician-comfort-switch')));
      await tester.pumpAndSettle();
      expect(container.read(displayComfortProvider), isTrue);

      await tester.tap(find.text(const AppStrings('ar').themeNightLabel));
      await tester.pumpAndSettle();
      expect(container.read(themeControllerProvider), ThemeMode.dark);
    });

    testWidgets('TrackMonthCalendar & ContextualSupportSheet do not double-flip RTL icons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocaleProvider.overrideWithValue(const Locale('ar'))],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    TrackMonthCalendar(
                      month: DateTime(2026, 11, 1),
                      traces: const <MindTraceModel>[],
                      selectedDateKey: null,
                      strings: const AppStrings('ar'),
                      onPreviousMonth: () {},
                      onNextMonth: () {},
                      canGoNextMonth: true,
                      onSelectDateKey: (_) {},
                    ),
                    HomeWeeklyRhythmCard(
                      traces: const <MindTraceModel>[],
                      tokens: MindTokens.light,
                      strings: const AppStrings('ar'),
                      isDark: false,
                      getMoodColor: MindTokens.moodColorByKey,
                      getMoodLabel: (key, s) => s.plainMoodLabel(key),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Previous month button keeps canonical chevron_left_rounded (auto-mirrored once by Flutter)
      final prevBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(const AppStrings('ar').previousMonthTooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect((prevBtn.icon as Icon).icon, Icons.chevron_left_rounded);

      final nextBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(const AppStrings('ar').nextMonthTooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect((nextBtn.icon as Icon).icon, Icons.chevron_right_rounded);

      // HomeWeeklyRhythmCard chronological 7-day strip uses explicit LTR plot direction
      final rhythmRow = find.descendant(
        of: find.byType(HomeWeeklyRhythmCard),
        matching: find.byWidgetPredicate(
          (w) => w is Directionality && w.textDirection == TextDirection.ltr,
        ),
      );
      expect(rhythmRow, findsOneWidget);

      // ContextualSupportSheet in Arabic uses canonical arrow_forward_ios_rounded (auto-mirrored once)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocaleProvider.overrideWithValue(const Locale('ar'))],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMindTheme(Brightness.light, isArabic: true),
            home: const Scaffold(body: ContextualSupportSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsNothing);
    });

    testWidgets('ClinicWelcomeScreen and LockOverlay both expose working language switchers', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appLockProvider.overrideWith(_AlwaysLockedAppLockNotifier.new),
          biometricServiceProvider.overrideWithValue(BiometricSecurityService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const ClinicWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('clinic-welcome-lang-btn')));
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), const Locale('fr'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const LockOverlay(child: Text('Hidden')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('lock-overlay-lang-btn')));
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), const Locale('ar'));
    });
  });
}
