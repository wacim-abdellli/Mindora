import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/export/document_exporter.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_banner.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/data/clinical_brief_pdf_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/data/patient_welcome_card_pdf_service.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/clinical_brief_preview_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/create_patient_account_sheet.dart';
import 'package:mind_forensics/features/insights/domain/discovery_milestones_model.dart';
import 'package:mind_forensics/features/insights/presentation/widgets/mood_aura_poster_sheet.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDocumentExporter extends DocumentExporter {
  _FakeDocumentExporter({this.throwOnSave = false});

  final bool throwOnSave;
  final List<String> savedPdfNames = <String>[];
  final List<Uint8List> savedPdfBytes = <Uint8List>[];
  final List<String> savedPngNames = <String>[];
  final List<String> printedNames = <String>[];

  @override
  Future<DocumentExportResult> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (throwOnSave) {
      throw Exception('Disk write failed');
    }
    savedPdfNames.add(fileName);
    savedPdfBytes.add(bytes);
    return DocumentExportResult(
      status: DocumentExportStatus.saved,
      fileName: fileName,
      savedPath: '/downloads/$fileName',
    );
  }

  @override
  Future<DocumentExportResult> savePng({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (throwOnSave) {
      throw Exception('PNG write failed');
    }
    savedPngNames.add(fileName);
    return DocumentExportResult(
      status: DocumentExportStatus.saved,
      fileName: fileName,
      savedPath: '/downloads/$fileName',
    );
  }

  @override
  Future<DocumentExportResult> printPdf({
    required Uint8List bytes,
    required String documentName,
  }) async {
    printedNames.add(documentName);
    return DocumentExportResult(
      status: DocumentExportStatus.printed,
      fileName: documentName,
    );
  }

  @override
  Future<DocumentExportResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String subject,
    required String text,
  }) async {
    return DocumentExportResult(
      status: DocumentExportStatus.shared,
      fileName: fileName,
    );
  }
}

ClinicianPatientRecord _buildRichMultiPageRecord(DateTime now) {
  final baseRecord = DemoClinicalCohort.buildRecords(referenceNow: now).first;

  final richCases = List<CaseModel>.generate(8, (i) {
    return CaseModel(
      id: 'rich_case_$i',
      caseNumber: 'SESSION 0${i + 1}',
      title: 'Evening overload and sleep wind-down reflection #${i + 1}',
      createdAt: now.subtract(Duration(days: i + 1)),
      updatedAt: now.subtract(Duration(days: i + 1)),
      currentStage: CaseStage.conclusion,
      incidentDescription:
          'Long workday followed by rapid cycling thoughts before midnight.',
      findingsSummary:
          'AI synthesis #$i: Late caffeine and unanswered work messages repeatedly coincided with elevated evening worry.',
      userConclusion:
          'Patient takeaway #$i: Putting the phone outside the bedroom at 22:30 noticeably lowered restlessness.',
      isCompleted: true,
      isPrivate: false,
    );
  });

  final privateCase = CaseModel(
    id: 'secret_private_case',
    caseNumber: 'PRIVATE 99',
    title: 'PRIVATE_SECRET_DO_NOT_EXPORT_TITLE',
    createdAt: now,
    updatedAt: now,
    currentStage: CaseStage.conclusion,
    incidentDescription: 'Private family topic kept strictly on device.',
    findingsSummary: 'PRIVATE_SECRET_AI_SUMMARY',
    userConclusion: 'PRIVATE_SECRET_TAKEAWAY',
    isCompleted: true,
    isPrivate: true,
  );

  final symptoms = [
    SymptomReport(
      id: 'sym_1',
      symptomIds: const ['racing_thoughts', 'muscle_tension', 'early_waking'],
      intensity: 7,
      userAdaptiveAnswer: 'Noticed tight shoulders right after team standup.',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];

  final notes = List<ClinicianSessionNote>.generate(5, (i) {
    return ClinicianSessionNote(
      id: 'cn_$i',
      createdAt: now.subtract(Duration(days: i * 4 + 1)),
      updatedAt: now.subtract(Duration(days: i * 4 + 1)),
      category: ClinicianNoteCategory.values[i % ClinicianNoteCategory.values.length],
      content:
          'Consultation observation #$i: Discussed sleep anchoring routine, pacing workload boundaries, and follow-up check-in schedule for next fortnight.',
    );
  });

  final packet = baseRecord.latestPacket.copyWith(
    consentScope: baseRecord.latestPacket.consentScope.copyWith(
      includeMoodMetrics: true,
      includeSleepEnergyAnxiety: true,
      includeSharedCases: true,
      includeSymptomReports: true,
      includePreVisitAgenda: true,
    ),
    sharedCases: [...richCases, privateCase],
    symptomReports: symptoms,
    preVisitAgenda: PreVisitAgenda(
      selectedTopics: const ['Sleep rhythm', 'Evening tension', 'Work boundaries'],
      patientQuestion: 'Should we adjust my evening routine before travel?',
      whatHelpedRecently: 'Short morning walk and 4-4-4-4 breathing.',
      focusPlanFeedback: 'Completed 2 of 3 check-in goals this week.',
      updatedAt: now,
    ),
  );

  return baseRecord.copyWith(
    latestPacket: packet,
    clinicianNotes: notes,
  );
}

ClinicProvisionResult _buildSampleProvision({String lang = 'en'}) {
  final now = DateTime(2026, 11, 25, 10, 0);
  return ClinicProvisionResult(
    account: ClinicPatientAccount(
      patientId: 'pat_welcome_1',
      doctorId: 'doc_1',
      clinicId: 'clinic_tunis',
      doctorName: 'Dr. Salma Ben Amor',
      clinicName: 'Tunis Mindora Practice',
      displayName: 'Youssef Trabelsi',
      loginIdentifier: '+216 22 456 789',
      preferredLanguage: lang,
      credentialHash: 'pbkdf2_placeholder',
      createdAt: now,
      updatedAt: now,
    ),
    temporaryPin: '482910',
    qrPayload: const ClinicInvitePayload(
      tokenId: 'tok_demo_123',
      secret: 'sec_demo_abc',
    ).encode(),
    expiresAt: now.add(const Duration(hours: 72)),
  );
}

Future<void> _waitForRenderedImage(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    final rawImages = find.byType(RawImage).evaluate();
    if (rawImages.isNotEmpty &&
        (rawImages.first.widget as RawImage).image != null) {
      break;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 3: Multi-Page Vector PDF Engine & Cross-Platform Export', () {
    test('1. DocumentExporter.sanitizeFileName produces safe cross-platform names', () {
      expect(
        DocumentExporter.sanitizeFileName('  Amine Ben-Ali / 2026! '),
        equals('amine_ben-ali_2026'),
      );
      expect(
        DocumentExporter.sanitizeFileName('../../../etc/passwd'),
        equals('.._.._.._etc_passwd'),
      );
      expect(
        DocumentExporter.sanitizeFileName('   !!!   '),
        equals('mindora_document'),
      );
    });

    test(
      '2. ClinicalBriefPdfService produces multi-page searchable vector PDF with zero truncation and notes toggle',
      () async {
        const service = ClinicalBriefPdfService();
        final now = DateTime(2026, 11, 25, 10, 0);
        final richRecord = _buildRichMultiPageRecord(now);
        const profile = ClinicianProfile(
          displayName: 'Dr. Salma Ben Amor',
          specialty: 'Psychiatrist',
          clinicName: 'Tunis Mindora Practice',
          licenseRef: 'CNOM-4412',
        );
        final focusPlan = PostVisitFocusPlan(
          planId: 'fp_1',
          clinicianName: 'Dr. Salma Ben Amor',
          createdAt: now,
          focusItems: const [
            FocusGoalItem(id: 'g1', title: 'Consistent wake time', isCompleted: true),
            FocusGoalItem(id: 'g2', title: 'Evening screen pause at 22:30'),
          ],
          observationCue: 'Notice whether waking fatigue eases after 4 nights.',
        );

        final withNotes = await service.renderConsultationBrief(
          record: richRecord,
          strings: const AppStrings('en'),
          encryptedCode: 'MF-SYNC-V1:TEST_PAYLOAD_VECTOR_QR',
          clinicianProfile: profile,
          includeClinicianNotes: true,
          activeFocusPlan: focusPlan,
        );

        final pdfText = latin1.decode(withNotes.pdfBytes);
        expect(withNotes.isVectorPdf, isTrue);
        expect(withNotes.hasEmbeddedQr, isTrue);
        expect(withNotes.pageCount, greaterThanOrEqualTo(2));
        expect(pdfText.startsWith('%PDF-1.4'), isTrue);
        expect(pdfText.trimRight().endsWith('%%EOF'), isTrue);
        expect(pdfText, matches(RegExp(r'/MediaBox\s*\[0 0 595 842\]')));
        expect(pdfText, matches(RegExp(r'/Type\s*/Font')));
        expect(pdfText, contains('xref'));
        expect(pdfText, contains('startxref'));
        // Cover preview PNG magic bytes
        expect(
          withNotes.previewPngBytes.sublist(0, 4),
          equals([137, 80, 78, 71]),
        );
        // Hard privacy shield: isPrivate == true cases must never leak
        expect(withNotes.plainSummary, isNot(contains('PRIVATE_SECRET')));

        // Toggling doctor consultation notes OFF must omit Block 6
        final withoutNotes = await service.renderConsultationBrief(
          record: richRecord,
          strings: const AppStrings('en'),
          encryptedCode: 'MF-SYNC-V1:TEST_PAYLOAD_VECTOR_QR',
          clinicianProfile: profile,
          includeClinicianNotes: false,
          activeFocusPlan: focusPlan,
        );
        expect(withoutNotes.pdfBytes.length, lessThan(withNotes.pdfBytes.length));

        // French & Arabic RTL renders complete cleanly as valid vector PDFs
        for (final lang in const ['fr', 'ar']) {
          final localized = await service.renderConsultationBrief(
            record: richRecord,
            strings: AppStrings(lang),
            encryptedCode: 'MF-SYNC-V1:TEST_PAYLOAD_$lang',
            clinicianProfile: profile,
          );
          final text = latin1.decode(localized.pdfBytes);
          expect(text.startsWith('%PDF-1.4'), isTrue);
          expect(text.trimRight().endsWith('%%EOF'), isTrue);
          expect(localized.pageCount, greaterThanOrEqualTo(2));
        }
      },
    );

    test(
      '3. PatientWelcomeCardPdfService generates valid printable A5 vector PDFs in EN, FR, and AR',
      () async {
        const service = PatientWelcomeCardPdfService();
        for (final lang in const ['en', 'fr', 'ar']) {
          final bytes = await service.generateWelcomeCardPdf(
            provision: _buildSampleProvision(lang: lang),
          );
          final pdfText = latin1.decode(bytes);
          expect(pdfText.startsWith('%PDF-1.4'), isTrue);
          expect(pdfText.trimRight().endsWith('%%EOF'), isTrue);
          expect(pdfText, matches(RegExp(r'/MediaBox\s*\[0 0 420 595\]')));
          expect(pdfText, matches(RegExp(r'/Type\s*/Font')));
          expect(bytes.length, greaterThan(2000));
        }
      },
    );

    testWidgets(
      '4. ClinicalBriefPreviewSheet supports Save, Print, notes toggle, and explicit error feedback',
      (tester) async {
        final fakeExporter = _FakeDocumentExporter();
        final record = _buildRichMultiPageRecord(DateTime(2026, 11, 25, 10, 0));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocaleProvider.overrideWithValue(const Locale('en')),
              documentExporterProvider.overrideWithValue(fakeExporter),
            ],
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: ClinicalBriefPreviewSheet(
                  record: record,
                  encryptedCode: 'MF-SYNC-V1:PREVIEW_TEST',
                ),
              ),
            ),
          ),
        );

        await _waitForRenderedImage(tester);

        expect(find.byKey(const ValueKey<String>('pdf-page-count-badge')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('pdf-include-notes-switch')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('pdf-save-btn')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('pdf-print-btn')), findsOneWidget);

        // Save PDF invokes DocumentExporter with clean sanitized filename
        final saveBtn = find.byKey(const ValueKey<String>('pdf-save-btn'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(fakeExporter.savedPdfNames, hasLength(1));
        expect(fakeExporter.savedPdfNames.first, startsWith('mindora_brief_'));
        expect(fakeExporter.savedPdfNames.first, endsWith('.pdf'));
        expect(
          latin1.decode(fakeExporter.savedPdfBytes.first).startsWith('%PDF-1.4'),
          isTrue,
        );

        // Print PDF invokes DocumentExporter.printPdf
        final printBtn = find.byKey(const ValueKey<String>('pdf-print-btn'));
        await tester.ensureVisible(printBtn);
        await tester.tap(printBtn);
        await tester.pumpAndSettle();
        expect(fakeExporter.printedNames, hasLength(1));

        // Toggle doctor notes switch cleanly re-renders
        final notesSwitch = find.byKey(const ValueKey<String>('pdf-include-notes-switch'));
        await tester.ensureVisible(notesSwitch);
        await tester.tap(notesSwitch);
        await _waitForRenderedImage(tester);
        expect(find.byKey(const ValueKey<String>('pdf-page-count-badge')), findsOneWidget);

        // Drain toast timer cleanly
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      '5. ClinicalBriefPreviewSheet surfaces explicit MindBanner on export failure',
      (tester) async {
        final failingExporter = _FakeDocumentExporter(throwOnSave: true);
        final record = _buildRichMultiPageRecord(DateTime(2026, 11, 25, 10, 0));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocaleProvider.overrideWithValue(const Locale('en')),
              documentExporterProvider.overrideWithValue(failingExporter),
            ],
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: ClinicalBriefPreviewSheet(record: record),
              ),
            ),
          ),
        );

        await _waitForRenderedImage(tester);

        final saveBtn = find.byKey(const ValueKey<String>('pdf-save-btn'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(find.byType(MindBanner), findsOneWidget);
        expect(
          find.text(const AppStrings('en').pdfExportFailedError),
          findsWidgets,
        );

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      '6. CreatePatientAccountSheet handover exports printable Welcome Card PDF',
      (tester) async {
        final fakeExporter = _FakeDocumentExporter();
        final provision = _buildSampleProvision(lang: 'fr');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocaleProvider.overrideWithValue(const Locale('en')),
              documentExporterProvider.overrideWithValue(fakeExporter),
            ],
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: CreatePatientAccountSheet(initialHandover: provision),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final welcomeBtn = find.byKey(
          const ValueKey<String>('admin-print-welcome-card-btn'),
        );
        expect(welcomeBtn, findsOneWidget);
        await tester.ensureVisible(welcomeBtn);
        await tester.tap(welcomeBtn);
        await tester.pumpAndSettle();

        expect(fakeExporter.savedPdfNames, hasLength(1));
        expect(fakeExporter.savedPdfNames.first, startsWith('mindora_welcome_'));
        expect(fakeExporter.savedPdfNames.first, endsWith('.pdf'));
        expect(
          latin1.decode(fakeExporter.savedPdfBytes.first).startsWith('%PDF-1.4'),
          isTrue,
        );

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      '7. MoodAuraPosterSheet routes Save Poster through DocumentExporter.savePng',
      (tester) async {
        final fakeExporter = _FakeDocumentExporter();
        final now = DateTime(2026, 11, 25, 10, 0);
        final traces = [
          MindTraceModel(
            id: 'aura_1',
            date: now,
            overallMood: 'calm',
            selectedEmotions: const ['calm', 'grounded'],
            moodIntensity: 6,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        const summary = DiscoveryMilestonesSummary(
          items: [
            DiscoveryMilestone(
              id: DiscoveryMilestoneId.firstTrace,
              title: 'First check-in',
              subtitle: 'Logged your first moment',
              icon: Icons.check_circle_outline,
              isUnlocked: true,
            ),
          ],
          distinctDays: 1,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocaleProvider.overrideWithValue(const Locale('en')),
              documentExporterProvider.overrideWithValue(fakeExporter),
            ],
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: MoodAuraPosterSheet(traces: traces, summary: summary),
              ),
            ),
          ),
        );

        await _waitForRenderedImage(tester);

        final saveBtn = find.text(const AppStrings('en').saveMoodAuraBtn);
        expect(saveBtn, findsOneWidget);
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(fakeExporter.savedPngNames, hasLength(1));
        expect(fakeExporter.savedPngNames.first, startsWith('mindora_mood_aura_'));
        expect(fakeExporter.savedPngNames.first, endsWith('.png'));

        await tester.pump(const Duration(seconds: 4));
      },
    );
  });
}
