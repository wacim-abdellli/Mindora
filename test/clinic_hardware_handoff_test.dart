import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinic_handoff_bridge.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/clinical_brief_preview_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/import_care_focus_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/import_patient_packet_sheet.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeClinicHandoffBridge extends ClinicHandoffBridge {
  FakeClinicHandoffBridge({this.scannedCode});

  final String? scannedCode;
  String? sharedFilePath;
  String? sharedSubject;
  String? sharedText;
  String? lastExpectedPrefix;
  int shareCalls = 0;
  int scanCalls = 0;

  @override
  Future<void> sharePdfFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    shareCalls++;
    sharedFilePath = filePath;
    sharedSubject = subject;
    sharedText = text;
  }

  @override
  Future<String?> scanQrCode(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  }) async {
    scanCalls++;
    lastExpectedPrefix = expectedPrefix;
    return scannedCode;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 6.1: Clinic Hardware Handoff Bridge & Camera QR Flows', () {
    testWidgets(
      '1. ClinicalBriefPreviewSheet shares rendered %PDF-1.4 file via ClinicHandoffBridge',
      (tester) async {
        final fakeBridge = FakeClinicHandoffBridge();
        final container = ProviderContainer(
          overrides: [
            clinicHandoffBridgeProvider.overrideWithValue(fakeBridge),
          ],
        );
        addTearDown(container.dispose);

        final nadia = DemoClinicalCohort.buildRecords(
          referenceNow: DateTime(2026, 11, 22, 12, 0),
        ).first;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('share_pdf_test'),
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(body: ClinicalBriefPreviewSheet(record: nadia)),
            ),
          ),
        );

        for (var i = 0; i < 60; i++) {
          final rawImages = find.byType(RawImage).evaluate();
          if (rawImages.isNotEmpty &&
              (rawImages.first.widget as RawImage).image != null) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        await tester.ensureVisible(find.text(strings.sharePdfBriefBtn));
        await tester.tap(find.text(strings.sharePdfBriefBtn));
        for (var i = 0; i < 40 && fakeBridge.shareCalls == 0; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(fakeBridge.shareCalls, 1);
        expect(fakeBridge.sharedFilePath, endsWith('.pdf'));
        expect(fakeBridge.sharedSubject, strings.pdfShareSubject);
        final sharedFile = File(fakeBridge.sharedFilePath!);
        expect(sharedFile.existsSync(), isTrue);
        final header = String.fromCharCodes(sharedFile.readAsBytesSync().take(8));
        expect(header, startsWith('%PDF-1.4'));
        if (sharedFile.existsSync()) {
          sharedFile.deleteSync();
        }
      },
    );

    testWidgets(
      '2. ImportPatientPacketSheet scans MF-CLINIC-V1 QR via bridge, populates field, and imports patient',
      (tester) async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 22, 12, 0);
        final packet = syncService.buildPatientPacket(
          referenceNow: now,
          patientDisplayName: 'Kenza T.',
          patientAnonymousId: 'p_kenza_qr',
          consentScope: const ClinicalConsentScope(
            windowDays: 14,
            includeMoodMetrics: true,
          ),
          traces: [
            MindTraceModel(
              id: 'qr_t1',
              date: now,
              overallMood: 'calm',
              selectedEmotions: const ['calm'],
              moodIntensity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          cases: const [],
          symptomReports: const [],
        );
        final encryptedPacketCode = await syncService.encryptPacketToShareCode(
          packet,
          'clinic-qr-77',
          pbkdf2Iterations: 2000,
        );

        final fakeBridge =
            FakeClinicHandoffBridge(scannedCode: encryptedPacketCode);
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(syncService),
            clinicHandoffBridgeProvider.overrideWithValue(fakeBridge),
          ],
        );
        addTearDown(container.dispose);
        await container.read(clinicianRosterProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('import_packet_qr'),
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: ImportPatientPacketSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        await tester.ensureVisible(find.text(strings.scanInRoomQrBtn));
        await tester.tap(find.text(strings.scanInRoomQrBtn));
        await tester.pumpAndSettle();

        expect(fakeBridge.scanCalls, 1);
        expect(fakeBridge.lastExpectedPrefix, ClinicianSyncService.codePrefix);
        expect(find.text(encryptedPacketCode), findsOneWidget);

        final passField = find.byType(TextField).last;
        await tester.ensureVisible(passField);
        await tester.enterText(passField, 'clinic-qr-77');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(strings.decryptAndImportBtn));
        await tester.tap(find.text(strings.decryptAndImportBtn));
        await tester.pumpAndSettle();

        final roster = await container.read(clinicianRosterProvider.future);
        expect(roster.any((r) => r.patientId == 'p_kenza_qr'), isTrue);
      },
    );

    testWidgets(
      '3. ImportCareFocusSheet scans MF-CAREPLAN-V1 QR via bridge, activates PostVisitFocusPlan, and renders 320px AR RTL cleanly',
      (tester) async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 22, 12, 0);
        final plan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Amira Ben Salem',
          focusTitles: const ['Evening wind-down pause'],
          referenceNow: now,
        );
        final carePlanCode = await syncService.encryptCarePlanToCode(
          plan,
          'focus-qr-88',
          pbkdf2Iterations: 2000,
        );

        final fakeBridge = FakeClinicHandoffBridge(scannedCode: carePlanCode);
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(syncService),
            clinicHandoffBridgeProvider.overrideWithValue(fakeBridge),
          ],
        );
        addTearDown(container.dispose);
        await container.read(postVisitFocusControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('import_care_qr'),
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: ImportCareFocusSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const enStrings = AppStrings('en');
        await tester.ensureVisible(find.text(enStrings.scanInRoomQrBtn));
        await tester.tap(find.text(enStrings.scanInRoomQrBtn));
        await tester.pumpAndSettle();

        expect(fakeBridge.scanCalls, 1);
        expect(
          fakeBridge.lastExpectedPrefix,
          ClinicianSyncService.carePlanPrefix,
        );
        expect(find.text(carePlanCode), findsOneWidget);

        final passField = find.byType(TextField).last;
        await tester.ensureVisible(passField);
        await tester.enterText(passField, 'focus-qr-88');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(enStrings.decryptAndImportBtn));
        await tester.tap(find.text(enStrings.decryptAndImportBtn));
        await tester.pumpAndSettle();

        final activePlan =
            await container.read(postVisitFocusControllerProvider.future);
        expect(activePlan?.clinicianName, 'Dr. Amira Ben Salem');
        expect(
          activePlan?.focusItems.first.title,
          'Evening wind-down pause',
        );

        // Narrow 320px + 1.35x Arabic RTL overflow check on ImportPatientPacketSheet & ImportCareFocusSheet
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('import_packet_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(body: ImportPatientPacketSheet()),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('import_care_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(body: ImportCareFocusSheet()),
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
