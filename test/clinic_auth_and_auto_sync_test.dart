import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/display_comfort_controller.dart';
import 'package:mind_forensics/app/theme/theme_controller.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
  });

  group('Phase 1 — Clinic Admin Provisioning, Security & Auto-Sync Engine', () {
    test('Doctor creates account without plaintext secrets; 1-scan QR works once and applies 65+ comfort settings', () async {
      final container = ProviderContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
          initialComfortModeProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final authRepo = container.read(clinicAuthRepositoryProvider);
      final provision = await authRepo.createPatientAccount(
        doctorId: 'doc_salma',
        clinicId: 'clinic_tunis_01',
        doctorName: 'Dr. Salma Ben Amor',
        clinicName: 'Tunis Mindora Practice',
        displayName: 'Khadija M.',
        loginIdentifier: '+216 22 444 555',
        ageRange: '65+',
        preferredLanguage: 'ar',
        assignedTrackIds: const ['sleep_wake', 'depressive_spectrum'],
        customTempPin: '619420',
      );

      // No plaintext temporary PIN or QR secret persisted anywhere in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final dumpedPrefs = prefs.getKeys().map((k) => '${prefs.get(k)}').join('\n');
      expect(dumpedPrefs.contains('619420'), isFalse);
      expect(provision.account.credentialHash.startsWith('pbkdf2_sha256\$'), isTrue);

      // Scan QR in clinic via AuthController
      final authCtrl = container.read(authControllerProvider.notifier);
      final ok = await authCtrl.signInWithClinicQr(provision.qrPayload);
      expect(ok, isTrue);

      final authState = container.read(authControllerProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.isClinicAccount, isTrue);
      expect(authState.user?.doctorId, 'doc_salma');

      // 65+ preference + Arabic locale auto-configured on first sign-in
      expect(container.read(localeControllerProvider).languageCode, 'ar');
      expect(container.read(displayComfortProvider), isTrue);
      expect(container.read(themeControllerProvider), ThemeMode.light);

      // Re-scanning the exact same single-use QR is strictly rejected
      await expectLater(
        authRepo.signInWithInviteQr(qrPayload: provision.qrPayload),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.inviteAlreadyUsed,
          ),
        ),
      );
    });

    test('Expired QR, revoked QR, wrong PIN, and paused account are cleanly rejected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authRepo = container.read(clinicAuthRepositoryProvider);
      final issuedAt = DateTime(2026, 11, 20, 10, 0);
      final provision = await authRepo.createPatientAccount(
        doctorId: 'doc_salma',
        clinicId: 'clinic_01',
        doctorName: 'Dr. Salma',
        clinicName: 'Clinic',
        displayName: 'Yassine B.',
        loginIdentifier: 'yassine.b',
        ageRange: '18-24',
        preferredLanguage: 'fr',
        customTempPin: '123456',
        inviteValidity: const Duration(hours: 24),
        now: issuedAt,
      );

      // Expired after 25 hours
      await expectLater(
        authRepo.signInWithInviteQr(
          qrPayload: provision.qrPayload,
          now: issuedAt.add(const Duration(hours: 25)),
        ),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.inviteExpired,
          ),
        ),
      );

      // Doctor resets access -> previous QR revoked, old PIN fails, new PIN works
      final reset = await authRepo.resetPatientAccess(
        doctorId: 'doc_salma',
        patientId: provision.account.patientId,
        customTempPin: '778899',
        now: issuedAt.add(const Duration(hours: 2)),
      );

      await expectLater(
        authRepo.signInWithInviteQr(
          qrPayload: provision.qrPayload,
          now: issuedAt.add(const Duration(hours: 3)),
        ),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.inviteRevoked,
          ),
        ),
      );

      await expectLater(
        authRepo.signInWithCredentials(
          identifier: 'YASSINE.B',
          pinOrPassword: '123456',
        ),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.invalidCredentials,
          ),
        ),
      );

      final loggedIn = await authRepo.signInWithCredentials(
        identifier: 'YASSINE.B',
        pinOrPassword: reset.temporaryPin,
      );
      expect(loggedIn.patientId, provision.account.patientId);

      // Pausing account immediately blocks further credential login
      await authRepo.setAccountStatus(
        doctorId: 'doc_salma',
        patientId: provision.account.patientId,
        status: ClinicAccountStatus.paused,
      );

      await expectLater(
        authRepo.signInWithCredentials(
          identifier: 'yassine.b',
          pinOrPassword: '778899',
        ),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.accountPaused,
          ),
        ),
      );
    });

    test('Multi-tenant clinic firewall isolates Doctor A from Doctor B', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authRepo = container.read(clinicAuthRepositoryProvider);
      final patA = await authRepo.createPatientAccount(
        doctorId: 'doc_a',
        clinicId: 'clinic_a',
        doctorName: 'Dr. A',
        clinicName: 'Clinic A',
        displayName: 'Patient A',
        loginIdentifier: '20111222',
        ageRange: '25-44',
        preferredLanguage: 'en',
        customTempPin: '111111',
      );
      await authRepo.createPatientAccount(
        doctorId: 'doc_b',
        clinicId: 'clinic_b',
        doctorName: 'Dr. B',
        clinicName: 'Clinic B',
        displayName: 'Patient B',
        loginIdentifier: '20333444',
        ageRange: '25-44',
        preferredLanguage: 'en',
        customTempPin: '222222',
      );

      final rosterA = await authRepo.listPatientsForDoctor('doc_a');
      final rosterB = await authRepo.listPatientsForDoctor('doc_b');
      expect(rosterA.map((p) => p.displayName), ['Patient A']);
      expect(rosterB.map((p) => p.displayName), ['Patient B']);

      // Doctor B cannot reset or alter Doctor A's patient
      await expectLater(
        authRepo.resetPatientAccess(
          doctorId: 'doc_b',
          patientId: patA.account.patientId,
        ),
        throwsA(
          isA<ClinicAuthException>().having(
            (e) => e.code,
            'code',
            ClinicAuthErrorCode.accountNotFound,
          ),
        ),
      );
    });

    test('Daily logs auto-sync to Doctor roster while Keep-just-for-me (isPrivate) stays hard-excluded', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Configure Doctor identity in roster
      await container
          .read(clinicianProfileProvider.notifier)
          .updateProfile(
            const ClinicianProfile(
              doctorId: 'doc_salma',
              displayName: 'Dr. Salma Ben Amor',
              clinicName: 'Tunis Mindora Practice',
            ),
          );

      final authRepo = container.read(clinicAuthRepositoryProvider);
      final provision = await authRepo.createPatientAccount(
        doctorId: 'doc_salma',
        clinicId: 'clinic_tunis_01',
        doctorName: 'Dr. Salma Ben Amor',
        clinicName: 'Tunis Mindora Practice',
        displayName: 'Sami T.',
        loginIdentifier: '21 900 800',
        ageRange: '25-44',
        preferredLanguage: 'en',
        customTempPin: '554433',
      );

      // Patient signs in with formatted phone spaces stripped cleanly
      final signedIn = await container
          .read(authControllerProvider.notifier)
          .signInWithClinicCredentials('21900800', '554433');
      expect(signedIn, isTrue);

      final now = DateTime.now();
      final traceCtrl = container.read(mindTraceControllerProvider.notifier);

      // 1. Save a normal shared daily check-in -> auto-syncs to Doctor
      await traceCtrl.recordCheckIn(
        MindTraceModel(
          id: 'tr_shared',
          userId: provision.account.patientId,
          date: now,
          overallMood: 'calm',
          moodIntensity: 4,
          sleepHours: 7.5,
          journalText: 'Slept better after evening walk',
          createdAt: now,
          updatedAt: now,
        ),
        generateAi: false,
      );

      // 2. Save a locked private moment + locked private Talk -> must NEVER sync to Doctor
      await traceCtrl.recordCheckIn(
        MindTraceModel(
          id: 'tr_private',
          userId: provision.account.patientId,
          date: now,
          overallMood: 'heavy',
          moodIntensity: 9,
          journalText: 'TOP SECRET PRIVATE JOURNAL NOTE',
          isPrivate: true,
          createdAt: now,
          updatedAt: now,
        ),
        generateAi: false,
      );

      final caseRepo = LocalCaseRepository(
        userId: provision.account.patientId,
        keyManager: container.read(secureKeyManagerProvider),
      );
      await caseRepo.saveCase(
        CaseModel(
          id: 'case_private',
          userId: provision.account.patientId,
          caseNumber: 'SESSION 01',
          title: 'CONFIDENTIAL FAMILY MATTER',
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Private reflection not for sharing',
          createdAt: now,
          updatedAt: now,
          isPrivate: true,
        ),
      );

      await container.read(clinicAutoSyncCoordinatorProvider).syncActivePatient();

      // Verify Doctor dossier contains ONLY shared trace, zero private data
      await container.read(clinicianDemoEnabledProvider.notifier).setEnabled(false);
      container.invalidate(clinicianRosterProvider);
      final roster = await container.read(clinicianRosterProvider.future);

      final samiRecord = roster.firstWhere(
        (r) => r.patientId == provision.account.patientId,
      );
      expect(samiRecord.latestPacket.traces.length, 1);
      expect(samiRecord.latestPacket.traces.first.id, 'tr_shared');
      expect(
        samiRecord.latestPacket.traces.any((t) => t.id == 'tr_private'),
        isFalse,
      );
      expect(samiRecord.latestPacket.sharedCases, isEmpty);

      // Doctor pushes between-visit Focus Plan -> Patient pulls automatically
      await container
          .read(clinicAutoSyncCoordinatorProvider)
          .pushDoctorFocusPlan(
            doctorId: 'doc_salma',
            patientId: provision.account.patientId,
            plan: PostVisitFocusPlan(
              planId: 'plan_1',
              clinicianName: 'Dr. Salma Ben Amor',
              createdAt: now,
              focusItems: const [
                FocusGoalItem(id: 'f1', title: 'Keep screens off 30m before sleep'),
              ],
            ),
          );

      await container.read(clinicAutoSyncCoordinatorProvider).pullInboxUpdates();
      container.invalidate(postVisitFocusControllerProvider);
      final pulledPlan = await container.read(
        postVisitFocusControllerProvider.future,
      );
      expect(pulledPlan?.clinicianName, 'Dr. Salma Ben Amor');
      expect(
        pulledPlan?.focusItems.first.title,
        'Keep screens off 30m before sleep',
      );
    });
  });
}
