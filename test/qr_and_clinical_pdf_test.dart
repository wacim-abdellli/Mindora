import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/local_data_cipher.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_qr_code.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinical_brief_pdf_service.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/clinical_brief_preview_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/compose_post_visit_focus_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/share_with_psychiatrist_sheet.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 5.3: Zero-Cloud In-Room QR Handoff & Printable A4 PDF Brief', () {
    test(
      '1. MindQrCodeEncoder obeys ISO/IEC 18004 sizing, finder/timing/dark invariants, and 2953-byte limit',
      () {
        expect(MindQrCodeEncoder.byteCapacityForVersion(1), equals(17));
        expect(MindQrCodeEncoder.byteCapacityForVersion(40), equals(2953));

        final m1 = MindQrCodeEncoder.encode('MF-CAREPLAN-V1');
        expect(m1, isNotNull);
        expect(m1!.version, equals(1));
        expect(m1.size, equals(21));

        // Check all 3 7x7 finder corners & always-dark module
        void expectFinder(int top, int left) {
          for (var r = 0; r < 7; r++) {
            for (var c = 0; c < 7; c++) {
              final onOuter = r == 0 || r == 6 || c == 0 || c == 6;
              final onInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
              expect(
                m1.isDark(top + r, left + c),
                equals(onOuter || onInner),
              );
            }
          }
        }

        expectFinder(0, 0);
        expectFinder(0, m1.size - 7);
        expectFinder(m1.size - 7, 0);
        expect(m1.isDark(m1.size - 8, 8), isTrue); // Dark module
        expect(m1.isDark(6, 8), isTrue); // Timing strip alternating dark/light
        expect(m1.isDark(6, 9), isFalse);

        // Format info Copy 1 <-> Copy 2 symmetry per ISO/IEC 18004 Figure 25
        for (var i = 0; i <= 5; i++) {
          expect(m1.isDark(m1.size - 1 - i, 8), equals(m1.isDark(8, i)));
        }
        expect(m1.isDark(m1.size - 7, 8), equals(m1.isDark(8, 7)));
        expect(m1.isDark(8, m1.size - 8), equals(m1.isDark(8, 8)));
        expect(m1.isDark(8, m1.size - 1), equals(m1.isDark(0, 8)));

        // Realistic medium payload fits within QR limits
        final med = MindQrCodeEncoder.encode('X' * 900);
        expect(med, isNotNull);
        expect(med!.size, equals(17 + 4 * med.version));

        // Exceeding 2953 bytes safely returns null
        final oversized = MindQrCodeEncoder.encode('A' * 2954);
        expect(oversized, isNull);
      },
    );

    test(
      '2. ClinicianSyncService gzip compresses handoff packets to fit QR while remaining backward-compatible with legacy uncompressed envelopes',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 22, 10, 0);
        final traces = List<MindTraceModel>.generate(
          10,
          (i) => MindTraceModel(
            id: 'gz_t_$i',
            date: now.subtract(Duration(days: i)),
            overallMood: i.isEven ? 'calm' : 'anxious',
            selectedEmotions: const ['calm', 'focused'],
            moodIntensity: 5,
            sleepHours: 7.0,
            contextTags: const ['routine_kept', 'sleep_consistent'],
            createdAt: now,
            updatedAt: now,
          ),
        );

        final packet = syncService.buildPatientPacket(
          referenceNow: now,
          patientDisplayName: 'Salma H.',
          patientAnonymousId: 'p_salma',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: true,
          ),
          traces: traces,
          cases: const [],
          symptomReports: const [],
        );

        final compressedCode = await syncService.encryptPacketToShareCode(
          packet,
          'room-pin-42',
          pbkdf2Iterations: 2000,
        );
        // Should comfortably fit inside MindQrCodeEncoder Version 40-L limit
        expect(
          compressedCode.length,
          lessThanOrEqualTo(MindQrCodeEncoder.maxByteCapacity),
        );
        expect(MindQrCodeEncoder.encode(compressedCode), isNotNull);

        final decryptedCompressed = await syncService.decryptShareCode(
          compressedCode,
          'room-pin-42',
        );
        expect(decryptedCompressed.traces.length, equals(10));

        // Legacy uncompressed envelope (no 'enc': 'gz') still decrypts seamlessly
        final salt = AuthService.generateSecureSalt(16);
        final hashRecord = AuthService.hashPassword(
          'room-pin-42',
          explicitSalt: salt,
          iterations: 2000,
        );
        final keyBytes = base64Url.decode(hashRecord.split('\$')[3]);
        final encryptedLegacyPayload = await LocalDataCipher(
          secretKeyBytes: keyBytes,
        ).encryptString(jsonEncode(packet.toJson()));
        final legacyEnvelope = {
          'v': 1,
          'kdf': 'pbkdf2_sha256',
          'iter': 2000,
          'salt': base64Url.encode(salt),
          'payload': encryptedLegacyPayload,
        };
        final legacyCode =
            '${ClinicianSyncService.codePrefix}${base64Url.encode(utf8.encode(jsonEncode(legacyEnvelope)))}';

        final decryptedLegacy = await syncService.decryptShareCode(
          legacyCode,
          'room-pin-42',
        );
        expect(decryptedLegacy.patientAnonymousId, equals('p_salma'));
        expect(decryptedLegacy.traces.length, equals(10));
      },
    );

    test(
      '3. ClinicalBriefPdfService generates valid PDF 1.4 A4 document and PNG preview for EN and Arabic RTL',
      () async {
        const pdfService = ClinicalBriefPdfService();
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 22, 11, 0);
        final nadia = DemoClinicalCohort.buildRecords(referenceNow: now).first;

        final carePlan = syncService.buildPostVisitFocusPlan(
          clinicianName: 'Dr. Salma Ben Amor',
          focusTitles: const ['Protect offline evening buffer'],
          referenceNow: now,
        );
        final carePlanCode = await syncService.encryptCarePlanToCode(
          carePlan,
          'clinic-2026',
          pbkdf2Iterations: 2000,
        );

        final enResult = await pdfService.renderConsultationBrief(
          record: nadia,
          strings: const AppStrings('en'),
          encryptedCode: carePlanCode,
        );

        final pdfText = ascii.decode(enResult.pdfBytes, allowInvalid: true);
        expect(pdfText.startsWith('%PDF-1.4'), isTrue);
        expect(pdfText.trimRight().endsWith('%%EOF'), isTrue);
        expect(pdfText, matches(RegExp(r'/MediaBox\s*\[0 0 595 842\]')));
        expect(pdfText, contains('xref'));
        expect(pdfText, contains('startxref'));
        expect(enResult.hasEmbeddedQr, isTrue);
        expect(
          enResult.previewPngBytes.sublist(0, 4),
          equals([137, 80, 78, 71]),
        );

        final tmpDir = Directory.systemTemp.createTempSync('mf_pdf_test_');
        addTearDown(() {
          if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
        });
        final savedPath = await pdfService.savePdfToLocalFile(
          enResult.pdfBytes,
          fileName: 'nadia_brief.pdf',
          directory: tmpDir,
        );
        expect(File(savedPath).existsSync(), isTrue);
        expect(File(savedPath).lengthSync(), equals(enResult.pdfBytes.length));

        final arResult = await pdfService.renderConsultationBrief(
          record: nadia,
          strings: const AppStrings('ar'),
        );
        expect(arResult.pdfBytes.length, greaterThan(1000));
        expect(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true)
              .hasMatch(enResult.plainSummary),
          isFalse,
        );
      },
    );

    testWidgets(
      '4. In-Room QR views and ClinicalBriefPreviewSheet render without overflow (incl. 320px AR RTL)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            clinicianSyncServiceProvider.overrideWithValue(
              const ClinicianSyncService(defaultPbkdf2Iterations: 2000),
            ),
          ],
        );
        addTearDown(container.dispose);

        // ComposePostVisitFocusSheet renders automatic QR after generating code
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('compose_qr_host'),
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(
                body: ComposePostVisitFocusSheet(
                  patientDisplayName: 'Nadia B.',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text('Note sleep & wake timing daily'),
        );
        await tester.tap(find.text('Note sleep & wake timing daily'));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.ensureVisible(textFields.last);
        await tester.enterText(textFields.last, 'room-pin-99');
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text('Generate Encrypted Focus Code'),
        );
        await tester.tap(find.text('Generate Encrypted Focus Code'));
        await tester.pumpAndSettle();

        expect(find.byType(MindQrCodeView), findsOneWidget);
        expect(
          find.textContaining('verbal room PIN'),
          findsOneWidget,
        );

        // ShareWithPsychiatristSheet toggles In-Room QR cleanly
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('share_qr_host'),
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(body: ShareWithPsychiatristSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final passField = find.byType(TextField).last;
        await tester.ensureVisible(passField);
        await tester.enterText(passField, 'share-pin-99');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Generate Encrypted Sync Code'));
        await tester.tap(find.text('Generate Encrypted Sync Code'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Show In-Room QR'));
        await tester.tap(find.text('Show In-Room QR'));
        await tester.pumpAndSettle();

        expect(find.byType(MindQrCodeView), findsOneWidget);
        expect(find.text('Hide QR Code'), findsOneWidget);

        // Narrow 320px + 1.35x text scaling + Arabic RTL on ClinicalBriefPreviewSheet
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        final nadia = DemoClinicalCohort.buildRecords().first;
        const arStrings = AppStrings('ar');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('brief_preview_ar_320'),
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
                      body: ClinicalBriefPreviewSheet(record: nadia),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Poll deterministically until async A4 rasterization finishes
        for (var i = 0; i < 30; i++) {
          if (find.byType(Image).evaluate().isNotEmpty) break;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(find.text(arStrings.savePdfBriefBtn), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
