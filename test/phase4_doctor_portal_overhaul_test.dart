import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinical_brief_pdf_service.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/compose_post_visit_focus_sheet.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppEditionConfig.setMainEdition(MindoraEdition.patient);
  });

  tearDown(() {
    AppEditionConfig.setMainEdition(MindoraEdition.patient);
  });

  group('Phase 4: Doctor Portal Clinical Dossier, Clinical Queue & Audit Log', () {
    test(
      '1. ClinicianClinicalRecord serializes cleanly, stays backward-compatible, and flows into EHR & Vector PDF',
      () async {
        final now = DateTime(2026, 11, 28, 9, 0);
        final record = DemoClinicalCohort.buildRecords(referenceNow: now).first;

        final clinical = ClinicianClinicalRecord(
          clinicFileNumber: 'TUN-2026-084',
          phone: '+216 22 111 222',
          diagnoses: [
            ClinicianDiagnosisEntry(
              id: 'dx_1',
              code: '6A60',
              label: 'Bipolar I Disorder',
              certainty: DiagnosisCertainty.confirmed,
              status: DiagnosisStatus.active,
              documentedAt: now,
              documentedByDoctorName: 'Dr. Salma Ben Amor',
            ),
          ],
          medications: [
            ClinicianMedicationEntry(
              id: 'med_1',
              name: 'Lithium Carbonate',
              dosage: '600 mg',
              frequency: 'Evening',
              startedAt: now,
              status: MedicationStatus.active,
            ),
          ],
          allergies: const [
            ClinicianAllergyEntry(
              id: 'alg_1',
              substance: 'Penicillin',
              reaction: 'Rash',
              severity: AllergySeverity.moderate,
            ),
          ],
          psychiatricHistory: 'Prior hypomanic episode in 2024.',
          nextAppointmentAt: now.add(const Duration(days: 14)),
        );

        final updated = record.copyWith(clinicalRecord: clinical);
        final roundtripped = ClinicianPatientRecord.fromJson(updated.toJson());
        expect(roundtripped.clinicalRecord.clinicFileNumber, 'TUN-2026-084');
        expect(roundtripped.clinicalRecord.diagnoses, hasLength(1));
        expect(
          roundtripped.clinicalRecord.diagnoses.first.label,
          'Bipolar I Disorder',
        );
        expect(
          roundtripped.clinicalRecord.medications.first.name,
          'Lithium Carbonate',
        );
        expect(roundtripped.clinicalRecord.allergies.first.substance, 'Penicillin');

        // Backward compatibility: legacy JSON missing clinicalRecord deserializes cleanly
        final legacyJson = Map<String, dynamic>.from(updated.toJson())
          ..remove('clinicalRecord');
        final fromLegacy = ClinicianPatientRecord.fromJson(legacyJson);
        expect(fromLegacy.clinicalRecord.isEmpty, isTrue);

        // EHR summary & Vector PDF include clinician-documented diagnoses/meds/allergies
        const sync = ClinicianSyncService();
        final ehr = sync.generateEhrClinicalNote(
          roundtripped,
          const AppStrings('en'),
        );
        expect(ehr, contains('Bipolar I Disorder'));
        expect(ehr, contains('Lithium Carbonate'));
        expect(ehr, contains('Penicillin'));

        const pdf = ClinicalBriefPdfService();
        final rendered = await pdf.renderConsultationBrief(
          record: roundtripped,
          strings: const AppStrings('en'),
        );
        expect(rendered.isVectorPdf, isTrue);
        expect(rendered.pdfBytes.length, greaterThan(1500));
      },
    );

    testWidgets(
      '2. ClinicianPatientDetailScreen documents Diagnosis, Medication, Allergy, edits/appends SOAP notes, and separates self-reported profile',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Import a real patient with a consented self-reported profile + safety-paused reflection
        final now = DateTime(2026, 11, 28, 9, 30);
        final packet = ClinicianSyncPacket(
          packetId: 'pkt_phase4_dossier',
          generatedAt: now,
          patientDisplayName: 'Amine K.',
          patientAnonymousId: 'pat_amine_p4',
          consentScope: const ClinicalConsentScope(
            includePsychologicalProfile: true,
            includeSharedCases: true,
            includeSymptomReports: false,
            includePreVisitAgenda: true,
          ),
          profileSnapshot: PsychologicalProfileModel(
            preferredName: 'Amine K.',
            conditions: const [
              UserConditionEntry(
                condition: ConditionType.generalizedAnxiety,
                status: DiagnosticStatus.selfIdentifiedExploring,
              ),
            ],
            currentTreatment: 'Monthly psychotherapy',
            personalTriggers: 'Late deadlines',
            updatedAt: now,
          ),
          sharedCases: [
            CaseModel(
              id: 'safe_case_1',
              caseNumber: 'SESSION 01',
              title: 'Overwhelmed after midnight',
              createdAt: now,
              updatedAt: now,
              currentStage: CaseStage.conclusion,
              incidentDescription: 'Felt overwhelmed late at night.',
              findingsSummary: 'AI summary text.',
              userConclusion: 'My own patient takeaway.',
              isPausedForSafety: true,
              isPrivate: false,
            ),
          ],
          preVisitAgenda: PreVisitAgenda(
            selectedTopics: const ['Sleep rhythm'],
            patientQuestion: 'Can we adjust evening routine?',
            focusPlanFeedback: 'Completed 2 of 3 check-in goals',
            updatedAt: now,
          ),
        );
        await container.read(clinicianRosterProvider.notifier).importPacket(packet);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const ClinicianPatientDetailScreen(patientId: 'pat_amine_p4'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');

        // Safety pause alert surfaces immediately in pinned header & Overview banner
        expect(
          find.byKey(const ValueKey<String>('dossier-safety-pause-alert')),
          findsOneWidget,
        );
        expect(find.textContaining('Completed 2 of 3 check-in goals'), findsOneWidget);

        // Add clinician-documented diagnosis via modal sheet
        final addDxBtn = find.byKey(const ValueKey<String>('dossier-add-dx-btn'));
        await tester.ensureVisible(addDxBtn);
        await tester.tap(addDxBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey<String>('dx-label-field')),
          'Bipolar II Disorder',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('dx-code-field')),
          '6A61',
        );
        await tester.tap(find.byKey(const ValueKey<String>('dx-certainty-confirmed')));
        await tester.ensureVisible(find.byKey(const ValueKey<String>('dx-save-btn')));
        await tester.tap(find.byKey(const ValueKey<String>('dx-save-btn')));
        await tester.pumpAndSettle();

        expect(find.textContaining('6A61 · Bipolar II Disorder'), findsWidgets);

        // Add medication
        final addMedBtn = find.byKey(const ValueKey<String>('dossier-add-med-btn'));
        await tester.ensureVisible(addMedBtn);
        await tester.tap(addMedBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey<String>('med-name-field')),
          'Lamotrigine',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('med-dosage-field')),
          '100 mg',
        );
        await tester.ensureVisible(find.byKey(const ValueKey<String>('med-save-btn')));
        await tester.tap(find.byKey(const ValueKey<String>('med-save-btn')));
        await tester.pumpAndSettle();
        expect(find.text('Lamotrigine'), findsOneWidget);

        // Add allergy
        final addAlgBtn =
            find.byKey(const ValueKey<String>('dossier-add-allergy-btn'));
        await tester.ensureVisible(addAlgBtn);
        await tester.tap(addAlgBtn);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey<String>('allergy-substance-field')),
          'Sulfa drugs',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('allergy-save-btn')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('allergy-save-btn')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Sulfa drugs'), findsWidgets);

        // Patient Self-Reported Profile stays strictly separated
        final selfProfileCard = find.byKey(
          const ValueKey<String>('dossier-self-reported-profile-card'),
        );
        await tester.scrollUntilVisible(
          selfProfileCard,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(selfProfileCard, findsOneWidget);
        expect(find.text(en.patientSelfReportedBadge), findsOneWidget);

        // Switch to Cases/Reflections -> verifies separated AI Summary vs Patient Takeaway & consent-excluded symptoms
        await tester.tap(find.text(en.dossierTabCases));
        await tester.pumpAndSettle();
        expect(find.text(en.aiSummaryBoxLabel), findsOneWidget);
        expect(find.text(en.patientTakeawayBoxLabel), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(en.symptomsExcludedByConsentLabel),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(en.symptomsExcludedByConsentLabel), findsOneWidget);

        // Switch to Notes -> verify non-destructive SOAP template APPEND + edit + confirm delete
        await tester.tap(find.text(en.dossierTabNotes));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.addClinicianNoteBtn));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Initial impression:');
        await tester.tap(find.byKey(const ValueKey('soap-template-checkin')));
        await tester.pumpAndSettle();
        // Existing typed text must NOT be wiped by tapping template pill!
        expect(find.textContaining('Initial impression:'), findsOneWidget);

        await tester.tap(find.text(en.saveNoteBtn));
        await tester.pumpAndSettle();
        expect(find.textContaining('Initial impression:'), findsOneWidget);

        // Edit the note cleanly
        final editNoteIcon = find.byIcon(Icons.edit_outlined).first;
        await tester.ensureVisible(editNoteIcon);
        await tester.tap(editNoteIcon);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Updated clinical note.');
        await tester.tap(find.text(en.saveChangesBtn));
        await tester.pumpAndSettle();
        expect(find.text('Updated clinical note.'), findsOneWidget);

        // Delete requires confirmation dialog
        final deleteNoteIcon = find.byIcon(Icons.delete_outline_rounded).first;
        await tester.ensureVisible(deleteNoteIcon);
        await tester.tap(deleteNoteIcon);
        await tester.pumpAndSettle();
        expect(find.text(en.deleteNoteConfirmTitle), findsOneWidget);
        await tester.tap(find.text(en.deleteEntryBtn).last);
        await tester.pumpAndSettle();
        expect(find.text('Updated clinical note.'), findsNothing);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      '3. Desktop split view does NOT passively wipe unreviewed status, Clinical Queue shows alerts/follow-ups, and Practice opens Audit Log + saves licenseRef',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 820);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Create a real clinic patient -> generates audit log entry & pending login status,
        // plus simulate a fresh synced check-in snapshot so Meriem Z. has an unreviewed update.
        final authRepo = container.read(clinicAuthRepositoryProvider);
        final created = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis',
          doctorName: 'Dr. Salma Ben Amor',
          clinicName: 'Tunis Mindora Practice',
          displayName: 'Meriem Z.',
          loginIdentifier: '55123456',
          ageRange: '25-44',
          preferredLanguage: 'fr',
        );
        await container.read(clinicSyncRepositoryProvider).syncPatientSnapshot(
              patientId: created.account.patientId,
              traces: const [],
              cases: const [],
              symptomReports: const [],
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Passive desktop mount must NOT have silently marked Meriem Z. reviewed
        final rosterBeforeClick = await container.read(clinicianRosterProvider.future);
        final meriemBefore = rosterBeforeClick.firstWhere(
          (r) => r.patientId == created.account.patientId,
        );
        expect(meriemBefore.hasUnreviewedUpdate, isTrue);

        // Explicitly tapping Mark reviewed in embedded dossier marks reviewed
        final markBtn =
            find.byKey(const ValueKey<String>('dossier-mark-reviewed-btn'));
        expect(markBtn, findsOneWidget);
        await tester.tap(markBtn);
        await tester.pumpAndSettle();

        final rosterAfterClick = await container.read(clinicianRosterProvider.future);
        final meriemAfter = rosterAfterClick.firstWhere(
          (r) => r.patientId == created.account.patientId,
        );
        expect(meriemAfter.hasUnreviewedUpdate, isFalse);

        // Switch to Overview (Clinical Queue Dashboard)
        const en = AppStrings('en');
        await tester.tap(find.text(en.clinicianTabOverview).first);
        await tester.pumpAndSettle();
        expect(find.text(en.clinicalQueueTitle), findsOneWidget);
        expect(find.text(en.queueOnboardingWatchTitle), findsOneWidget);
        expect(find.text('Meriem Z.'), findsWidgets);

        // Switch to Practice tab -> verify licenseRef editing & Audit Log viewer
        await tester.tap(find.text(en.clinicianTabPractice));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('clinician-practice-profile-card')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey<String>('practice-license-ref-field')),
          'CNOM-9981',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('practice-profile-save-btn')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('CNOM-9981'), findsOneWidget);

        // Open Audit Log sheet -> confirms createdAccount event is listed
        final auditBtn =
            find.byKey(const ValueKey<String>('clinician-audit-log-btn'));
        await tester.ensureVisible(auditBtn);
        await tester.tap(auditBtn);
        await tester.pumpAndSettle();
        expect(find.text(en.localizedAuditAction('createdAccount')), findsWidgets);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      '4. Doctor Edition ComposePostVisitFocusSheet pushes to clinic inbox without overwriting unrelated local patient vault',
      (tester) async {
        AppEditionConfig.setMainEdition(MindoraEdition.clinician);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authRepo = container.read(clinicAuthRepositoryProvider);
        final created = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis',
          doctorName: 'Dr. Salma Ben Amor',
          clinicName: 'Tunis Mindora Practice',
          displayName: 'Sami R.',
          loginIdentifier: '55998877',
          ageRange: '25-44',
          preferredLanguage: 'en',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: ComposePostVisitFocusSheet(
                  patientDisplayName: 'Sami R.',
                  patientId: created.account.patientId,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        final deliverBtn = find.text(en.sendFocusToPatientDeviceBtn);
        await tester.ensureVisible(deliverBtn);
        await tester.tap(deliverBtn);
        await tester.pumpAndSettle();

        // Patient's clinic inbox received the Focus Plan
        final inbox = await container
            .read(clinicSyncRepositoryProvider)
            .pullPatientInbox(created.account.patientId);
        expect(inbox?.activeFocusPlan, isNotNull);

        // Unrelated local patient vault was NOT overwritten in Doctor Edition
        final localVaultPlan =
            await container.read(carePlanRepositoryProvider).loadActivePlan();
        expect(localVaultPlan, isNull);

        await tester.pump(const Duration(seconds: 4));
      },
    );
  });
}
