import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_qr_code.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/compose_post_visit_focus_sheet.dart';
import 'package:mind_forensics/features/profile/domain/clinical_condition_catalog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    AppEditionConfig.setMainEdition(MindoraEdition.patient);
  });

  tearDown(() {
    AppEditionConfig.setMainEdition(MindoraEdition.patient);
  });

  group('Phase 4 Doctor Admin Provisioning, Access Controls & Focus Push', () {
    testWidgets(
      'Doctor taps + Add patient -> creates account -> displays single-use QR & PIN -> patient appears in roster',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final addBtn = find.byKey(const ValueKey('clinician-add-patient-btn'));
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('admin-create-name-field')),
          'Kamel B.',
        );
        await tester.enterText(
          find.byKey(const ValueKey('admin-create-identifier-field')),
          '98111222',
        );
        await tester.tap(find.text('65+'));
        await tester.tap(find.text('Français'));
        await tester.pumpAndSettle();

        final submitBtn = find.byKey(const ValueKey('admin-create-submit-btn'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        expect(find.text(en.patientAccessReadyTitle), findsOneWidget);
        expect(find.byType(MindQrCodeView), findsOneWidget);
        expect(
          find.byKey(const ValueKey('admin-handover-pin-text')),
          findsOneWidget,
        );

        await tester.tap(find.text(en.doneBtn));
        await tester.pumpAndSettle();

        expect(find.text('Kamel B.'), findsWidgets);
      },
    );

    testWidgets(
      'ClinicianPatientDetailScreen Pause/Resume, Reset PIN & QR, Edit Focus Areas, and Auto-Push Focus Plan work end-to-end',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authRepo = container.read(clinicAuthRepositoryProvider);
        final provision = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis_01',
          doctorName: 'Dr. Amine',
          clinicName: 'Cabinet Amine',
          displayName: 'Nour T.',
          loginIdentifier: '23999888',
          ageRange: '25-44',
          preferredLanguage: 'en',
          assignedTrackIds: [ClinicalTrack.sleepWake.id],
          customTempPin: '123456',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: ClinicianPatientDetailScreen(
                patientId: provision.account.patientId,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        // Navigate to Notes / Actions tab (4th segment)
        await tester.tap(find.text(en.dossierTabNotes));
        await tester.pumpAndSettle();

        final adminCard = find.byKey(
          const ValueKey('dossier-clinic-access-card'),
        );
        await tester.scrollUntilVisible(
          adminCard,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(adminCard, findsOneWidget);
        // Newly created account has not signed in yet -> must honestly display Pending status
        expect(find.text(en.awaitingFirstLoginBadge), findsWidgets);

        // 1. Pause access -> login must reject
        final pauseResumeBtn =
            find.byKey(const ValueKey('dossier-pause-resume-btn'));
        await tester.scrollUntilVisible(
          pauseResumeBtn,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(pauseResumeBtn);
        await tester.pumpAndSettle();
        expect(find.text(en.accountPausedBadge), findsWidgets);

        await expectLater(
          authRepo.signInWithCredentials(
            identifier: '23999888',
            pinOrPassword: '123456',
          ),
          throwsA(
            isA<ClinicAuthException>().having(
              (e) => e.code,
              'code',
              ClinicAuthErrorCode.accountPaused,
            ),
          ),
        );

        // 2. Resume access
        await tester.scrollUntilVisible(
          pauseResumeBtn,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(pauseResumeBtn);
        await tester.pumpAndSettle();
        expect(find.text(en.accountActiveBadge), findsWidgets);

        // 3. Reset PIN & new QR (now gated behind explicit confirmation dialog)
        final resetBtn = find.byKey(const ValueKey('dossier-reset-pin-qr-btn'));
        await tester.ensureVisible(resetBtn);
        await tester.tap(resetBtn);
        await tester.pumpAndSettle();
        expect(find.text(en.resetPinConfirmTitle), findsOneWidget);
        await tester.tap(find.text(en.resetPinAndQrBtn).last);
        await tester.pumpAndSettle();
        expect(find.byType(MindQrCodeView), findsOneWidget);
        final handoverDone = find.text(en.doneBtn);
        await tester.ensureVisible(handoverDone);
        await tester.tap(handoverDone);
        await tester.pumpAndSettle();

        // 4. Edit focus areas
        final editTracksBtn = find.byKey(
          const ValueKey('dossier-edit-tracks-btn'),
        );
        await tester.ensureVisible(editTracksBtn);
        await tester.tap(editTracksBtn);
        await tester.pumpAndSettle();
        final trackChoice = find.text(
          ClinicalTrack.depressiveSpectrum.localizedTitle(en),
        );
        await tester.ensureVisible(trackChoice);
        await tester.tap(trackChoice);
        await tester.tap(find.text(en.saveChangesBtn));
        await tester.pumpAndSettle();

        final updatedAccount = await authRepo.getPatientAccount(
          provision.account.patientId,
        );
        expect(
          updatedAccount?.assignedTrackIds,
          contains(ClinicalTrack.depressiveSpectrum.id),
        );
      },
    );

    testWidgets(
      'ComposePostVisitFocusSheet with patientId pushes focus plan automatically to ClinicSyncRepository inbox',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authRepo = container.read(clinicAuthRepositoryProvider);
        final provision = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis_01',
          doctorName: 'Dr. Amine',
          clinicName: 'Cabinet Amine',
          displayName: 'Youssef M.',
          loginIdentifier: '77666555',
          ageRange: '18-24',
          preferredLanguage: 'en',
        );

        const en = AppStrings('en');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: Scaffold(
                body: ComposePostVisitFocusSheet(
                  patientDisplayName: 'Youssef M.',
                  patientId: provision.account.patientId,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final deliverBtn = find.text(en.sendFocusToPatientDeviceBtn);
        await tester.ensureVisible(deliverBtn);
        await tester.tap(deliverBtn);
        await tester.pumpAndSettle();

        final inbox = await container
            .read(clinicSyncRepositoryProvider)
            .pullPatientInbox(provision.account.patientId);
        expect(inbox?.activeFocusPlan, isNotNull);
        expect(inbox?.activeFocusPlan?.focusItems, isNotEmpty);
      },
    );

    testWidgets(
      'Clinician Practice tab shows Preview as Patient (Demo) button in Clinician Edition debug mode',
      (tester) async {
        AppEditionConfig.setMainEdition(MindoraEdition.clinician);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        await tester.tap(find.text(en.clinicianTabPractice));
        await tester.pumpAndSettle();

        final demoBtn = find.byKey(
          const ValueKey('clinician-preview-patient-demo-btn'),
        );
        await tester.scrollUntilVisible(
          demoBtn,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(demoBtn, findsOneWidget);
      },
    );
  });
}
