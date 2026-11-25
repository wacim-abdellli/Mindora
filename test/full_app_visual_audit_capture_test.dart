import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedLocale extends LocaleController {
  _FixedLocale(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FixedComfort extends DisplayComfortController {
  _FixedComfort(this._val);
  final bool _val;
  @override
  bool build() => _val;
}

class _SeededTraces extends MindTraceNotifier {
  _SeededTraces(this._items);
  final List<MindTraceModel> _items;
  @override
  Future<List<MindTraceModel>> build() async => _items;
}

class _SeededRoster extends ClinicianRosterNotifier {
  _SeededRoster(this._records);
  final List<ClinicianPatientRecord> _records;
  @override
  Future<List<ClinicianPatientRecord>> build() async => _records;
}

void main() {
  const outDir =
      r'C:\Users\pc\.gemini\antigravity\brain\a4ea709b-c435-4760-9e37-1f5a1d16d793\screenshots\audit_v3_vercel';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    final interLoader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/Inter-$weight.ttf');
      if (f.existsSync()) {
        interLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await interLoader.load();

    final arabicLoader = FontLoader('Noto Sans Arabic');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/NotoSansArabic-$weight.ttf');
      if (f.existsSync()) {
        arabicLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await arabicLoader.load();

    final iconFile = File('assets/fonts/MaterialIcons-Regular.otf');
    if (iconFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(
        iconFile
            .readAsBytes()
            .then((b) => ByteData.sublistView(Uint8List.fromList(b))),
      );
      await iconLoader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
  });

  List<MindTraceModel> sampleTraces() {
    final now = DateTime.now();
    return [
      MindTraceModel(
        id: 't1',
        userId: 'audit',
        date: DateTime(now.year, now.month, now.day - 4, 21, 0),
        overallMood: 'good',
        selectedEmotions: const ['good', 'content'],
        moodIntensity: 3,
        energyLevel: 7,
        anxietyLevel: 2,
        sleepHours: 8.0,
        contextTags: const ['sleep_consistent', 'physical_movement'],
        behavioralResponse: 'Evening walk',
        createdAt: now,
        updatedAt: now,
      ),
      MindTraceModel(
        id: 't2',
        userId: 'audit',
        date: DateTime(now.year, now.month, now.day - 3, 20, 0),
        overallMood: 'anxious',
        selectedEmotions: const ['anxious', 'overwhelmed'],
        moodIntensity: 7,
        energyLevel: 4,
        anxietyLevel: 7,
        sleepHours: 5.5,
        contextTags: const ['high_workload', 'late_caffeine_screens'],
        behavioralResponse: 'Slow breathing',
        createdAt: now,
        updatedAt: now,
      ),
      MindTraceModel(
        id: 't3',
        userId: 'audit',
        date: DateTime(now.year, now.month, now.day - 2, 19, 30),
        overallMood: 'calm',
        selectedEmotions: const ['calm', 'grounded'],
        moodIntensity: 3,
        energyLevel: 6,
        anxietyLevel: 3,
        sleepHours: 7.5,
        contextTags: const ['sleep_consistent'],
        behavioralResponse: 'Talked with family',
        createdAt: now,
        updatedAt: now,
      ),
      MindTraceModel(
        id: 't4',
        userId: 'audit',
        date: DateTime(now.year, now.month, now.day - 1, 22, 0),
        overallMood: 'heavy',
        selectedEmotions: const ['heavy', 'drained'],
        moodIntensity: 8,
        energyLevel: 3,
        anxietyLevel: 6,
        sleepHours: 5.0,
        contextTags: const ['high_workload'],
        behavioralResponse: 'Quiet rest',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> snap(
    WidgetTester tester, {
    required String filename,
    required Widget child,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    bool comfortMode = false,
    double textScale = 1.0,
    Size size = const Size(412, 915),
    List<dynamic> extraOverrides = const [],
  }) async {
    final key = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final tokens = (brightness == Brightness.dark
            ? MindTokens.dark
            : MindTokens.light)
        .withComfortBoost(comfortMode);
    final theme = buildMindTheme(
      brightness,
      tokensOverride: tokens,
      isArabic: locale.languageCode == 'ar',
    );

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          localeControllerProvider.overrideWith(() => _FixedLocale(locale)),
          displayComfortProvider.overrideWith(() => _FixedComfort(comfortMode)),
          ...extraOverrides.cast(),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: theme,
          builder: (ctx, c) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: RepaintBoundary(key: key, child: c!),
            ),
          ),
          home: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      final outFile = File('$outDir${Platform.pathSeparator}$filename');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes);
    });
  }

  testWidgets('Capture all patient & doctor pages (Light, Dark & Amel AR RTL)', (
    tester,
  ) async {
    final traces = sampleTraces();
    final demoCohort = DemoClinicalCohort.buildRecords();
    final firstPatient = demoCohort.first;

    await snap(
      tester,
      filename: '01_onboarding_light.png',
      child: const OnboardingScreen(),
    );
    await snap(
      tester,
      filename: '01b_onboarding_ar_dark.png',
      child: const OnboardingScreen(),
      brightness: Brightness.dark,
      locale: const Locale('ar'),
    );
    await snap(
      tester,
      filename: '02_auth_dark.png',
      child: const AuthScreen(),
      brightness: Brightness.dark,
    );
    await snap(
      tester,
      filename: '03_today_home_light.png',
      child: const HomeScreen(),
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '04_today_home_dark.png',
      child: const HomeScreen(),
      brightness: Brightness.dark,
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '05_my_days_track_light.png',
      child: const TrackScreen(),
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '06_talk_light.png',
      child: const FlashCaseScreen(),
    );
    await snap(
      tester,
      filename: '07_patterns_insights_light.png',
      child: const InsightsScreen(),
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '08_patterns_insights_dark.png',
      child: const InsightsScreen(),
      brightness: Brightness.dark,
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '09_me_settings_light.png',
      child: const SettingsScreen(),
    );
    await snap(
      tester,
      filename: '10_me_settings_dark.png',
      child: const SettingsScreen(),
      brightness: Brightness.dark,
    );
    await snap(
      tester,
      filename: '11_doctor_roster_light.png',
      child: const ClinicianShellScreen(),
      extraOverrides: [
        clinicianRosterProvider.overrideWith(() => _SeededRoster(demoCohort)),
      ],
    );
    await snap(
      tester,
      filename: '12_doctor_roster_dark.png',
      child: const ClinicianShellScreen(),
      brightness: Brightness.dark,
      extraOverrides: [
        clinicianRosterProvider.overrideWith(() => _SeededRoster(demoCohort)),
      ],
    );
    await snap(
      tester,
      filename: '13_doctor_dossier_dark.png',
      child: ClinicianPatientDetailScreen(patientId: firstPatient.patientId),
      brightness: Brightness.dark,
      extraOverrides: [
        clinicianRosterProvider.overrideWith(() => _SeededRoster(demoCohort)),
      ],
    );
    await snap(
      tester,
      filename: '14_doctor_desktop_split_dark.png',
      child: const ClinicianShellScreen(),
      brightness: Brightness.dark,
      size: const Size(1280, 800),
      extraOverrides: [
        clinicianRosterProvider.overrideWith(() => _SeededRoster(demoCohort)),
      ],
    );
    await snap(
      tester,
      filename: '15_today_amel_ar_rtl_320.png',
      child: const HomeScreen(),
      locale: const Locale('ar'),
      comfortMode: true,
      textScale: 1.6,
      size: const Size(320, 640),
      extraOverrides: [
        mindTraceControllerProvider.overrideWith(() => _SeededTraces(traces)),
      ],
    );
    await snap(
      tester,
      filename: '16_talk_amel_ar_rtl_320.png',
      child: const FlashCaseScreen(),
      locale: const Locale('ar'),
      comfortMode: true,
      textScale: 1.5,
      size: const Size(320, 640),
    );
    await snap(
      tester,
      filename: '17_psychological_profile_light.png',
      child: const PsychologicalProfileScreen(),
    );
  });
}
