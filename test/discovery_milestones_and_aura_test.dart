import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinic_handoff_bridge.dart';
import 'package:mind_forensics/features/insights/domain/discovery_milestones_model.dart';
import 'package:mind_forensics/features/insights/domain/recovery_ledger_model.dart';
import 'package:mind_forensics/features/insights/presentation/widgets/discovery_milestones_card.dart';
import 'package:mind_forensics/features/insights/presentation/widgets/mood_aura_poster_sheet.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuraShareBridge extends ClinicHandoffBridge {
  int sharePngCalls = 0;
  String? sharedPngPath;
  String? sharedSubject;

  @override
  Future<void> sharePdfFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {}

  @override
  Future<void> sharePngFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    sharePngCalls++;
    sharedPngPath = filePath;
    sharedSubject = subject;
  }

  @override
  Future<String?> scanQrCode(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  }) async =>
      null;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 7.3: Discovery Milestones & Generative Mood Aura Poster', () {
    test(
      'DiscoveryMilestonesService is strictly cumulative and never resets across multi-day gaps',
      () {
        const strings = AppStrings('en');
        final now = DateTime(2026, 11, 24, 20, 0);

        final emptySummary = DiscoveryMilestonesService.compute(
          traces: const [],
          ledger: const RecoveryLedger.empty(),
          strings: strings,
        );
        expect(emptySummary.unlockedCount, equals(0));
        expect(emptySummary.totalCount, equals(5));

        // Build 7 distinct logged days spread across 28 days (huge gaps between days)
        final gappedTraces = <MindTraceModel>[
          MindTraceModel(
            id: 'g1_a',
            date: now.subtract(const Duration(days: 27, hours: 6)),
            overallMood: 'anxious',
            selectedEmotions: const ['anxious', 'overwhelmed', 'tense'],
            moodIntensity: 8,
            behavioralResponse: 'Took a walk outside',
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 'g1_b',
            date: now.subtract(const Duration(days: 27)),
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'grounded'],
            moodIntensity: 4,
            behavioralResponse: 'Breathing pause',
            createdAt: now,
            updatedAt: now,
          ),
          for (final gapDays in [22, 18, 12, 7, 3, 0])
            MindTraceModel(
              id: 'g_$gapDays',
              date: now.subtract(Duration(days: gapDays)),
              overallMood: gapDays.isEven ? 'calm' : 'heavy',
              selectedEmotions: const ['calm', 'hopeful'],
              moodIntensity: 5,
              createdAt: now,
              updatedAt: now,
            ),
        ];

        final ledger = RecoveryLedger.fromTraces(gappedTraces);
        final fullSummary = DiscoveryMilestonesService.compute(
          traces: gappedTraces,
          ledger: ledger,
          strings: strings,
        );

        expect(fullSummary.distinctDays, equals(7));
        expect(fullSummary.unlockedCount, equals(5));
        expect(fullSummary.items.every((m) => m.isUnlocked), isTrue);
      },
    );

    testWidgets(
      'MoodAuraPosterSheet renders PNG artwork, shares via ClinicHandoffBridge, and fits 320px AR RTL cleanly',
      (tester) async {
        final fakeBridge = _FakeAuraShareBridge();
        final container = ProviderContainer(
          overrides: [
            clinicHandoffBridgeProvider.overrideWithValue(fakeBridge),
          ],
        );
        addTearDown(container.dispose);

        final now = DateTime(2026, 11, 24, 18, 0);
        final traces = [
          MindTraceModel(
            id: 'aura_1',
            date: now,
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'grounded', 'hopeful', 'content'],
            moodIntensity: 4,
            journalText: 'SECRET_PRIVATE_NOTE_NEVER_ON_POSTER',
            createdAt: now,
            updatedAt: now,
          ),
        ];
        const enStrings = AppStrings('en');
        final summary = DiscoveryMilestonesService.compute(
          traces: traces,
          ledger: RecoveryLedger.fromTraces(traces),
          strings: enStrings,
        );

        // Verify offscreen PNG bytes directly inside runAsync (toByteData uses native raster thread)
        final rawPng = await tester.runAsync(
          () => MoodAuraPosterRenderer.renderPng(
            traces: traces,
            summary: summary,
            tokens: MindTokens.dark,
            strings: enStrings,
            referenceNow: now,
          ),
        );
        expect(rawPng, isNotNull);
        expect(rawPng!.sublist(0, 4), equals([137, 80, 78, 71]));
        expect(rawPng.length, greaterThan(5000));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('aura_sheet_en'),
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: MoodAuraPosterSheet(traces: traces, summary: summary),
              ),
            ),
          ),
        );

        for (var i = 0; i < 120; i++) {
          final spinners = find.byType(CircularProgressIndicator).evaluate();
          final rawImages = find.byType(RawImage).evaluate();
          if (spinners.isEmpty &&
              rawImages.isNotEmpty &&
              (rawImages.first.widget as RawImage).image != null) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        expect(
          find.textContaining('SECRET_PRIVATE_NOTE_NEVER_ON_POSTER'),
          findsNothing,
        );

        await tester.ensureVisible(find.text(enStrings.shareMoodAuraBtn));
        await tester.tap(find.text(enStrings.shareMoodAuraBtn));
        for (var i = 0; i < 80 && fakeBridge.sharePngCalls == 0; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pump();
        await tester.pumpAndSettle();

        expect(fakeBridge.sharePngCalls, equals(1));
        expect(fakeBridge.sharedPngPath, endsWith('.png'));
        expect(fakeBridge.sharedSubject, equals(enStrings.moodAuraShareSubject));
        final sharedFile = File(fakeBridge.sharedPngPath!);
        expect(sharedFile.existsSync(), isTrue);
        expect(
          sharedFile.readAsBytesSync().sublist(0, 4),
          equals([137, 80, 78, 71]),
        );
        if (sharedFile.existsSync()) {
          sharedFile.deleteSync();
        }

        // Narrow 320px + 1.35x Arabic RTL overflow check on DiscoveryMilestonesCard
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        const arStrings = AppStrings('ar');
        final arSummary = DiscoveryMilestonesService.compute(
          traces: traces,
          ledger: RecoveryLedger.fromTraces(traces),
          strings: arStrings,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('milestones_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: DiscoveryMilestonesCard(
                          traces: traces,
                          summary: arSummary,
                          strings: arStrings,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(arStrings.discoveryMilestonesTitle), findsOneWidget);
      },
    );
  });
}
