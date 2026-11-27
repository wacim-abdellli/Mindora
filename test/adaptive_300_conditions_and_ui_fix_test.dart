import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_clinical_pulse_card.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/adaptive_tracking_engine.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/onboarding/domain/app_personalization_engine.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/clinical_condition_catalog.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/profile/presentation/widgets/clinical_condition_search_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _vqaOutDir = String.fromEnvironment('VQA_OUT_DIR');

Future<void> _loadTestFonts() async {
  try {
    final fontPaths = <String, String>{
      'Inter': 'C:/Windows/Fonts/segoeui.ttf',
      'Noto Sans Arabic': 'C:/Windows/Fonts/tahoma.ttf',
    };
    for (final entry in fontPaths.entries) {
      final f = File(entry.value);
      if (f.existsSync()) {
        final bytes = await f.readAsBytes();
        final loader = FontLoader(entry.key)
          ..addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();
      }
    }
  } catch (_) {}
}

Future<void> _saveShot(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  if (_vqaOutDir.isEmpty) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final img = await boundary.toImage(pixelRatio: 2.0);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = Directory(_vqaOutDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File('$_vqaOutDir/$filename').writeAsBytes(data.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadTestFonts();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
  });

  group('Phase 1-4: 300+ Condition Catalog, Adaptive Daily Ritual & UI Fixes', () {
    test(
      'ClinicalConditionCatalog contains 300+ conditions across 12 tracks with zero forbidden words or emojis',
      () {
        expect(ClinicalConditionCatalog.all.length, greaterThanOrEqualTo(300));

        final seenIds = <String>{};
        final emojiRegex = RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
          unicode: true,
        );
        const banned = ['calorie', 'weight loss', 'diet plan', 'relapse', 'cbt treatment'];

        for (final track in ClinicalTrack.values) {
          expect(ClinicalConditionCatalog.byTrack(track), isNotEmpty);
        }

        for (final item in ClinicalConditionCatalog.all) {
          expect(seenIds.add(item.id), isTrue, reason: 'Duplicate id ${item.id}');
          final combined = '${item.en} ${item.fr} ${item.ar}'.toLowerCase();
          expect(emojiRegex.hasMatch(combined), isFalse);
          for (final bad in banned) {
            expect(combined, isNot(contains(bad)), reason: 'Forbidden "$bad" in ${item.id}');
          }
        }

        // Fast trilingual searches
        expect(
          ClinicalConditionCatalog.search('bipolar').map((e) => e.id),
          contains('bipolar_1'),
        );
        expect(
          ClinicalConditionCatalog.search('وسواس').map((e) => e.track),
          contains(ClinicalTrack.obsessiveCompulsive),
        );
        expect(
          ClinicalConditionCatalog.search('insomnie').map((e) => e.track),
          contains(ClinicalTrack.sleepWake),
        );
      },
    );

    test(
      'AdaptiveTrackingEngine prioritizes sleep/motorSpeed for Bipolar, loopLoad for OCD, and caps <= 3 metrics',
      () {
        final bipolarProfile = PsychologicalProfileModel(
          selectedConditionIds: const ['bipolar_1'],
          updatedAt: DateTime.now(),
        );
        final bipolarSpecs = AdaptiveTrackingEngine.buildDailyRitual(
          profile: bipolarProfile,
          plan: AppPersonalizationEngine.resolve(bipolarProfile),
          todayTrace: null,
          hour: 20, // Even at night, unlogged sleep must still ask Bipolar user!
        );
        expect(bipolarSpecs.length, lessThanOrEqualTo(3));
        expect(
          bipolarSpecs.map((s) => s.kind),
          containsAll([
            AdaptiveMetricKind.sleepHours,
            AdaptiveMetricKind.motorEnergy,
            AdaptiveMetricKind.routineAnchor,
          ]),
        );

        final ocdProfile = PsychologicalProfileModel(
          selectedConditionIds: const ['ocd_checking', 'gad', 'adhd_combined'],
          updatedAt: DateTime.now(),
        );
        final multiSpecs = AdaptiveTrackingEngine.buildDailyRitual(
          profile: ocdProfile,
          plan: AppPersonalizationEngine.resolve(ocdProfile),
          todayTrace: null,
          hour: 21,
        );
        // Capped cleanly at 3 even with multiple conditions
        expect(multiSpecs.length, equals(3));
        expect(multiSpecs.map((s) => s.kind), contains(AdaptiveMetricKind.loopLoad));
      },
    );

    testWidgets(
      'Interactive Done pill collapses HomeClinicalPulseCard cleanly, ProgressiveDetailsSheet Done closes without hanging, and Home hides +Add sleep CTA',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        await container.read(profileControllerProvider.future);
        final bipolarProfile = PsychologicalProfileModel(
          preferredName: 'Yassine',
          selectedConditionIds: const ['bipolar_2'],
          careContext: 'regular_doctor',
          updatedAt: now,
        );
        await container
            .read(profileControllerProvider.notifier)
            .saveFullProfile(bipolarProfile);
        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'today_bipolar',
                date: now,
                overallMood: 'calm',
                moodIntensity: 6,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container.read(mindTraceControllerProvider.future);

        final repaintKey = GlobalKey();
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: RepaintBoundary(
                key: repaintKey,
                child: const HomeScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        // Hero card must NOT render redundant "+ Add sleep, tags or a note"
        expect(find.text(en.addDetailsCta), findsNothing);
        expect(find.byKey(const ValueKey('home-clinical-pulse-card')), findsOneWidget);

        // Tap all Bipolar options -> interactive Done button unlocks
        await tester.ensureVisible(find.byKey(const ValueKey('pulse-sleep-7to8')));
        await tester.tap(find.byKey(const ValueKey('pulse-sleep-7to8')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('pulse-energy-high')));
        await tester.tap(find.byKey(const ValueKey('pulse-energy-high')));
        await tester.pumpAndSettle();

        final routineBtn = find.byKey(const ValueKey('pulse-routine-yes'));
        if (routineBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(routineBtn);
          await tester.tap(routineBtn);
          await tester.pumpAndSettle();
        }

        // Capture full visual open state first
        await _saveShot(tester, repaintKey, '01_home_bipolar_ritual_light.png');

        final doneToggle = find.byKey(const ValueKey('pulse-done-toggle-btn'));
        expect(doneToggle, findsOneWidget);
        await tester.ensureVisible(doneToggle);
        await tester.tap(doneToggle);
        await tester.pumpAndSettle();

        // Collapsed state shows "Saved · Edit" and hides individual sleep question rows
        expect(find.text(en.ritualSavedCompactBtn), findsOneWidget);
        expect(find.byKey(const ValueKey('pulse-sleep-7to8')), findsNothing);
        await _saveShot(tester, repaintKey, '02_home_ritual_collapsed_done.png');

        // Verify ProgressiveDetailsSheet Done button saves & pops cleanly
        final trace = container.read(todayTraceProvider)!;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          ProgressiveDetailsSheet.show(ctx, trace: trace),
                      child: const Text('OPEN_EDIT'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('OPEN_EDIT'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('progressive-sheet-done-btn')));
        await tester.pumpAndSettle();
        expect(find.byType(ProgressiveDetailsSheet), findsNothing);
      },
    );

    testWidgets(
      'ClinicalConditionSearchSheet captures Dark visual & Condition Markers sync into Doctor Dossier + EHR even with includePersonalNotes false',
      (tester) async {
        final now = DateTime.now();
        final profile = PsychologicalProfileModel(
          preferredName: 'Karim',
          selectedConditionIds: const ['ocd_checking', 'bipolar_2'],
          updatedAt: now,
        );
        final trace = AdaptiveTrackingEngine.applySelection(
          AdaptiveTrackingEngine.applySelection(
            MindTraceModel.createFresh(id: 'tr_doc_sync', date: now),
            AdaptiveMetricKind.loopLoad,
            AdaptiveTrackingEngine.loopLoadSpec.options.last, // Sticky
            strings: const AppStrings('en'),
          ),
          AdaptiveMetricKind.motorEnergy,
          AdaptiveTrackingEngine.motorEnergySpec.options.last, // Revved
          strings: const AppStrings('en'),
        );

        const sync = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final packet = sync.buildPatientPacket(
          patientDisplayName: 'Karim B.',
          patientAnonymousId: 'u_k',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: true,
            includePersonalNotes: false,
            includeSharedCases: true,
            includeSymptomReports: false,
            includePsychologicalProfile: true,
            includePreVisitAgenda: false,
          ),
          traces: [trace],
          cases: const [],
          symptomReports: const [],
          profile: profile,
          referenceNow: now,
        );

        final record = ClinicianPatientRecord(
          patientId: 'u_k',
          displayName: 'Karim B.',
          importedAt: now,
          lastSyncedAt: now,
          latestPacket: packet,
        );
        final ehr = sync.generateEhrClinicalNote(record, const AppStrings('en'));
        expect(ehr, contains('Condition-specific markers'));
        expect(ehr, contains('Intrusive loop load: Sticky'));
        expect(ehr, contains('Energy & activation: Revved'));

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(clinicianRepositoryProvider).upsertPatient(record);

        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: Builder(
                  builder: (ctx) => Scaffold(
                    body: ClinicianPatientDetailScreen(patientId: 'u_k'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('clinician-condition-markers-card')),
          findsOneWidget,
        );
        expect(find.textContaining('Intrusive loop load: Sticky'), findsOneWidget);

        // Capture Search 300+ Conditions Sheet visual + 320px AR RTL zero overflow
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: RepaintBoundary(
                key: repaintKey,
                child: Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const ClinicalConditionSearchSheet(
                        initialConditionIds: ['bipolar_1', 'ocd_checking'],
                        initialTrackIds: [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _saveShot(tester, repaintKey, '03_search_300_conditions_dark.png');

        // Narrow 320px 1.35x Arabic RTL HomeClinicalPulseCard zero-overflow audit
        await tester.binding.setSurfaceSize(const Size(320, 640));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildMindTheme(Brightness.light, isArabic: true),
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
              home: RepaintBoundary(
                key: repaintKey,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: HomeClinicalPulseCard(
                      tokens: MindTokens.light,
                      strings: const AppStrings('ar'),
                      plan: AppPersonalizationEngine.resolve(profile),
                      profile: profile,
                      loggedDaysThisWeek: 4,
                      todayTrace: trace,
                      overrideHour: 9,
                      onUpdateTrace: (_) async {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _saveShot(tester, repaintKey, '04_ritual_ar_rtl_320.png');
      },
    );
  });
}
