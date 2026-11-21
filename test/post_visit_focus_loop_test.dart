import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/compose_post_visit_focus_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/import_care_focus_sheet.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_post_visit_focus_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 4.1: Two-Way Care Loop — Between-Session Focus Plan', () {
    test(
      '1. MF-CAREPLAN-V1 encryption roundtrip, wrong passphrase failure, and tamper rejection',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 21, 10, 30);

        final plan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Salma Ben Amor',
          clinicName: 'Tunis Practice',
          focusTitles: const [
            'Note sleep & wake timing daily',
            'Log an evening mood check-in',
          ],
          followUpDate: now.add(const Duration(days: 14)),
          observationCue: 'Notice if an offline buffer lowers evening tension.',
          referenceNow: now,
        );

        final code = await syncService.encryptCarePlanToCode(
          plan,
          'focus-pass-2026',
          pbkdf2Iterations: 2000,
        );
        expect(code.startsWith(ClinicianSyncService.carePlanPrefix), isTrue);

        final decrypted = await syncService.decryptCarePlanCode(
          code,
          'focus-pass-2026',
        );
        expect(decrypted.clinicianName, equals('Dr. Salma Ben Amor'));
        expect(decrypted.focusItems.length, equals(2));
        expect(
          decrypted.observationCue,
          equals('Notice if an offline buffer lowers evening tension.'),
        );

        await expectLater(
          syncService.decryptCarePlanCode(code, 'wrong-pass'),
          throwsA(
            isA<ClinicianSyncException>().having(
              (e) => e.code,
              'code',
              ClinicianSyncErrorCode.decryptionFailed,
            ),
          ),
        );

        final mid = code.length ~/ 2;
        final flipped = code[mid] == 'X' ? 'Y' : 'X';
        final tampered =
            '${code.substring(0, mid)}$flipped${code.substring(mid + 1)}';
        await expectLater(
          syncService.decryptCarePlanCode(tampered, 'focus-pass-2026'),
          throwsA(isA<ClinicianSyncException>()),
        );
      },
    );

    test(
      '2. LocalCarePlanRepository & postVisitFocusControllerProvider persist toggles and dismissal',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final plan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Youssef H.',
          focusTitles: const ['Track morning vs evening energy'],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(postVisitFocusControllerProvider.notifier)
            .savePlan(plan);
        final loaded = await container.read(carePlanRepositoryProvider).loadActivePlan();
        expect(loaded, isNotNull);
        expect(loaded!.focusItems.first.isCompleted, isFalse);

        final itemId = loaded.focusItems.first.id;
        await container
            .read(postVisitFocusControllerProvider.notifier)
            .toggleGoalItem(itemId);

        final afterToggle =
            await container.read(carePlanRepositoryProvider).loadActivePlan();
        expect(afterToggle!.focusItems.first.isCompleted, isTrue);

        await container
            .read(postVisitFocusControllerProvider.notifier)
            .dismissPlan();
        final afterDismiss =
            await container.read(carePlanRepositoryProvider).loadActivePlan();
        expect(afterDismiss!.isDismissed, isTrue);
      },
    );

    testWidgets(
      '3. ComposePostVisitFocusSheet delivers focus plan to HomeScreen with interactive toggle & dismiss',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(
              const ClinicianSyncService(defaultPbkdf2Iterations: 2000),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => ComposePostVisitFocusSheet.show(
                        ctx,
                        patientDisplayName: 'Nadia B.',
                      ),
                      child: const Text('Compose Focus'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Compose Focus'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Note sleep & wake timing daily'));
        await tester.tap(find.text('Note sleep & wake timing daily'));
        await tester.pumpAndSettle();

        // Enter passphrase and generate MF-CAREPLAN-V1 code
        final fields = find.byType(TextField);
        await tester.ensureVisible(fields.last);
        await tester.enterText(fields.last, 'tunis-focus-21');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Generate Encrypted Focus Code'));
        await tester.tap(find.text('Generate Encrypted Focus Code'));
        await tester.pumpAndSettle();

        expect(find.textContaining('MF-CAREPLAN-V1:'), findsOneWidget);

        // Deliver directly to Patient Workspace
        await tester.ensureVisible(
          find.text('Deliver to Patient Workspace on This Device'),
        );
        await tester.tap(
          find.text('Deliver to Patient Workspace on This Device'),
        );
        await tester.pumpAndSettle();

        // Mount HomeScreen and confirm the agreed focus card appears
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BETWEEN-SESSION FOCUS'), findsOneWidget);
        expect(find.text('Note sleep & wake timing daily'), findsOneWidget);

        // Toggle goal completion inside HomeScreen card
        await tester.ensureVisible(find.text('Note sleep & wake timing daily'));
        await tester.tap(find.text('Note sleep & wake timing daily'));
        await tester.pumpAndSettle();

        final updated = container.read(postVisitFocusControllerProvider).value;
        expect(updated?.focusItems.first.isCompleted, isTrue);

        // Dismiss card cleanly
        await tester.ensureVisible(find.byTooltip('Dismiss focus card'));
        await tester.tap(find.byTooltip('Dismiss focus card'));
        await tester.pumpAndSettle();

        expect(find.text('BETWEEN-SESSION FOCUS'), findsNothing);
      },
    );

    testWidgets(
      '4. ImportCareFocusSheet decrypts MF-CAREPLAN-V1 code and activates it',
      (tester) async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final plan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Amine K.',
          focusTitles: const ['Capture one thing that helped steady the day'],
          observationCue: 'Evening routine check.',
        );
        final code = await syncService.encryptCarePlanToCode(
          plan,
          'session-key-88',
          pbkdf2Iterations: 2000,
        );

        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(syncService),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => ImportCareFocusSheet.show(ctx),
                      child: const Text('Import Care Plan'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Import Care Plan'));
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), code);
        await tester.enterText(fields.at(1), 'session-key-88');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Decrypt & Import'));
        await tester.tap(find.text('Decrypt & Import'));
        await tester.pumpAndSettle();

        final saved = container.read(postVisitFocusControllerProvider).value ??
            await container.read(postVisitFocusControllerProvider.future);
        expect(saved, isNotNull);
        expect(saved!.clinicianName, equals('Dr. Amine K.'));
        expect(
          saved.focusItems.first.title,
          equals('Capture one thing that helped steady the day'),
        );
      },
    );

    testWidgets(
      '5. HomePostVisitFocusCard & ComposePostVisitFocusSheet pass a11y guidelines and 320px Arabic RTL zero-overflow',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final now = DateTime.now();
        final samplePlan = PostVisitFocusPlan(
          planId: 'p_a11y',
          clinicianName: 'Dr. Salma Ben Amor',
          createdAt: now,
          followUpDate: now.add(const Duration(days: 7)),
          focusItems: const [
            FocusGoalItem(id: '1', title: 'Log an evening mood check-in'),
          ],
          observationCue: 'Notice what precedes evening restlessness.',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomePostVisitFocusCard(
                    plan: samplePlan,
                    onToggleItem: (_) {},
                    onDismiss: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();

        // 320px narrow + 1.35x text scaling + Arabic RTL
        tester.view.physicalSize = const Size(320, 640);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.35),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: HomePostVisitFocusCard(
                        plan: samplePlan,
                        onToggleItem: (_) {},
                        onDismiss: () {},
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
      },
    );
  });
}
