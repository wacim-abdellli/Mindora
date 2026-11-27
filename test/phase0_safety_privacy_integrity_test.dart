import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/case_file/data/clinical_export_service.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinician_auth_service.dart';
import 'package:mind_forensics/features/clinician/data/local_clinician_repository.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_auth_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_clinical_pulse_card.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/onboarding/domain/app_personalization_engine.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    AppEditionConfig.configureForTesting(null);
    ClinicianAuthService.setUnlockedForTesting(false);
  });

  group('Phase 0 — AI Provenance, Privacy Leaks & Compact Zero-PII QR', () {
    test('AI speaker & listening preference labels never impersonate a medical specialist', () {
      for (final lang in ['en', 'fr', 'ar']) {
        final s = AppStrings(lang);
        expect(s.talkConsultSpeaker.toLowerCase(), isNot(contains('specialist')));
        expect(s.talkConsultSpeaker.toLowerCase(), isNot(contains('spécialiste')));
        expect(s.talkConsultSpeaker, isNot(contains('مستشار المتابعة')));
        expect(s.listeningPrefsLabel, isNot(contains('الاستشارة الطبية')));
        expect(s.listeningPrefsLabel.toLowerCase(), isNot(contains('consultation')));
      }
    });

    test('bookmarkTakeaway stores AI summary in findingsSummary without overwriting userConclusion', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Racing thoughts before bed');
      await notifier.bookmarkTakeaway('AI draft takeaway text');

      final updated = container.read(activeCaseControllerProvider).value!;
      expect(updated.findingsSummary, 'AI draft takeaway text');
      expect(updated.userConclusion, isNull);
    });

    test('ClinicalExportService excludes t.isPrivate traces and separates AI summary from patient words', () {
      final now = DateTime.now();
      final c = CaseModel(
        id: 'case_1',
        caseNumber: 'SESSION 01',
        title: 'Evening reflection',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.findings,
        incidentDescription: 'Felt tense after work',
        findingsSummary: 'AI summary text only',
        userConclusion: null,
      );
      final publicTrace = MindTraceModel(
        id: 't_pub',
        date: now,
        overallMood: 'anxious',
        moodIntensity: 7,
        journalText: 'PUBLIC_NOTE_VISIBLE',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );
      final privateTrace = MindTraceModel(
        id: 't_priv',
        date: now,
        overallMood: 'heavy',
        moodIntensity: 9,
        journalText: 'SECRET_PRIVATE_DIARY_MUST_NOT_LEAK',
        isPrivate: true,
        createdAt: now,
        updatedAt: now,
      );

      final brief = ClinicalExportService.generateSessionBrief(
        cases: [c],
        traces: [publicTrace, privateTrace],
        strings: const AppStrings('en'),
      );

      expect(brief, contains('AI-GENERATED REFLECTION SUMMARY'));
      expect(brief, contains('AI summary text only'));
      expect(brief, contains('No conclusion anchored yet.'));
      expect(brief, isNot(contains('SECRET_PRIVATE_DIARY_MUST_NOT_LEAK')));
    });

    test('ClinicInvitePayload encodes compact v2 QR with ZERO personal data and signs in via token lookup', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(clinicAuthRepositoryProvider);
      final result = await repo.createPatientAccount(
        doctorId: 'doc_1',
        clinicId: 'cln_1',
        doctorName: 'Dr. Salma Ben Amor',
        clinicName: 'Tunis Mindora Practice',
        displayName: 'Samira Khelifi',
        loginIdentifier: '22998877',
        ageRange: '65+',
        preferredLanguage: 'ar',
      );

      expect(result.qrPayload.startsWith(ClinicInvitePayload.qrPrefix), isTrue);
      // Decode raw base64 JSON and verify ZERO PII fields are embedded
      final rawJson = utf8.decode(
        base64Url.decode(
          result.qrPayload.substring(ClinicInvitePayload.qrPrefix.length),
        ),
      );
      expect(rawJson, isNot(contains('Samira')));
      expect(rawJson, isNot(contains('22998877')));
      expect(rawJson, isNot(contains('Salma')));
      expect(rawJson, isNot(contains('Tunis')));
      expect(rawJson.length, lessThan(110));

      final signedIn = await repo.signInWithInviteQr(
        qrPayload: result.qrPayload,
      );
      expect(signedIn.displayName, 'Samira Khelifi');
      expect(signedIn.loginIdentifier, '22998877');
    });
  });

  group('Phase 0 — Doctor Auth Gate, Role Isolation & Auth Lifecycle', () {
    test('ClinicianAuthService hashes PIN with PBKDF2 and verifies unlock/lock lifecycle', () async {
      final service = ClinicianAuthService();
      expect(await service.isPinConfigured(), isFalse);
      expect(ClinicianAuthService.isSessionUnlocked, isFalse);

      await service.setupPin('4829');
      expect(await service.isPinConfigured(), isTrue);
      expect(ClinicianAuthService.isSessionUnlocked, isTrue);

      ClinicianAuthService.lockSession();
      expect(ClinicianAuthService.isSessionUnlocked, isFalse);

      expect(await service.verifyAndUnlock('0000'), isFalse);
      expect(ClinicianAuthService.isSessionUnlocked, isFalse);

      expect(await service.verifyAndUnlock('4829'), isTrue);
      expect(ClinicianAuthService.isSessionUnlocked, isTrue);
    });

    test('AuthController.signOut clears state.user completely', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(clinicAuthRepositoryProvider);
      final provision = await repo.createPatientAccount(
        doctorId: 'doc_1',
        clinicId: 'cln_1',
        doctorName: 'Dr. Test',
        clinicName: 'Clinic',
        displayName: 'Nadia',
        loginIdentifier: '55112233',
        ageRange: '25-44',
        preferredLanguage: 'en',
      );

      final ok = await container
          .read(authControllerProvider.notifier)
          .signInWithClinicQr(provision.qrPayload);
      expect(ok, isTrue);
      expect(container.read(authControllerProvider).user, isNotNull);

      await container.read(authControllerProvider.notifier).signOut();
      expect(container.read(authControllerProvider).user, isNull);
    });

    testWidgets('ClinicianAuthScreen sets up PIN cleanly on first launch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const ClinicianAuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('clinician-auth-pin-field')),
        '2468',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('clinician-auth-confirm-pin-field')),
        '2468',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('clinician-auth-submit-btn')),
      );
      await tester.pumpAndSettle();

      expect(ClinicianAuthService.isSessionUnlocked, isTrue);
    });
  });

  group('Phase 0 — Clinical Data Integrity & Zero-Log Honesty', () {
    test('Deleting the last clinician note persists as empty after reload', () async {
      final keyManager = SecureKeyManager();
      final repo = LocalClinicianRepository(keyManager: keyManager);
      final now = DateTime.now();
      final record = ClinicianPatientRecord(
        patientId: 'pat_imported_1',
        displayName: 'Karim',
        isDemoCase: false,
        importedAt: now,
        lastSyncedAt: now,
        latestPacket: ClinicianSyncPacket(
          packetId: 'pkt_1',
          generatedAt: now,
          patientDisplayName: 'Karim',
          patientAnonymousId: 'pat_imported_1',
          consentScope: const ClinicalConsentScope(),
        ),
        clinicianNotes: [
          ClinicianSessionNote(
            id: 'note_1',
            createdAt: now,
            updatedAt: now,
            content: 'Initial assessment note',
          ),
        ],
      );

      await repo.upsertPatient(record, overwriteNotes: true);
      final loaded1 = await repo.loadImportedPatients();
      expect(loaded1.single.clinicianNotes.length, 1);

      // Delete the only note
      await repo.upsertPatient(
        record.copyWith(clinicianNotes: const []),
        overwriteNotes: true,
      );
      final loaded2 = await repo.loadImportedPatients();
      expect(loaded2.single.clinicianNotes, isEmpty);
    });

    testWidgets('HomeClinicalPulseCard logs sleep without fabricating Calm mood on HomeDailyCheckInCard', (tester) async {
      MindTraceModel? latestTrace;
      const strings = AppStrings('en');
      final plan = AppPersonalizationEngine.resolve(
        PsychologicalProfileModel(
          careContext: 'regular_doctor',
          focusAreas: const ['sleep'],
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (ctx, setState) => Column(
                  children: [
                    HomeDailyCheckInCard(
                      tokens: MindTokens.light,
                      strings: strings,
                      isDark: false,
                      todayTrace: latestTrace,
                      traces: latestTrace != null ? [latestTrace!] : const [],
                      todayTraces:
                          latestTrace != null ? [latestTrace!] : const [],
                      selectedMoodIndex: 1,
                      moodIntensity: 6,
                      todayNoteController: TextEditingController(),
                      moodOptions: const [
                        (key: 'good', icon: Icons.wb_sunny_outlined),
                        (key: 'calm', icon: Icons.spa_outlined),
                      ],
                      onMoodSelected: (_) {},
                      onIntensityChanged: (_) {},
                      onSave: () {},
                      getMoodLabel: (k, s) => s.plainMoodLabel(k),
                      getMoodColor: (k) => MindTokens.moodColorByKey(k),
                    ),
                    HomeClinicalPulseCard(
                      tokens: MindTokens.light,
                      strings: strings,
                      plan: plan,
                      todayTrace: latestTrace,
                      overrideHour: 9,
                      onUpdateTrace: (updater) async {
                        setState(() => latestTrace = updater(latestTrace));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pulse-sleep-7to8')));
      await tester.pumpAndSettle();

      expect(latestTrace?.sleepHours, 7.5);
      expect(latestTrace?.hasExplicitMood, isFalse);
      // Hero card must still ask how the user feels, NOT claim "Calm"
      expect(find.text(strings.howAreYouRightNow), findsOneWidget);
    });

    testWidgets('ClinicianShellScreen shows honest awaiting status for 0-log provisioned patient', (tester) async {
      AppEditionConfig.configureForTesting(MindoraEdition.clinician);
      ClinicianAuthService.setUnlockedForTesting(true);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Disable demo cohort so only our newly provisioned 0-log patient appears
      await container.read(clinicianDemoEnabledProvider.notifier).setEnabled(false);
      await container.read(clinicAuthRepositoryProvider).createPatientAccount(
            doctorId: 'doc_mindora_primary',
            clinicId: 'MIND-SBA-10',
            doctorName: 'Dr. Salma Ben Amor',
            clinicName: 'Tunis Mindora Practice',
            displayName: 'Youssef Newly Added',
            loginIdentifier: '99887766',
            ageRange: '45-64',
            preferredLanguage: 'en',
          );
      container.invalidate(clinicianRosterProvider);

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

      const strings = AppStrings('en');
      expect(find.text('Youssef Newly Added'), findsOneWidget);
      expect(find.text(strings.connectedNoCheckInsLabel), findsOneWidget);
      expect(find.text(strings.awaitingFirstLoginBadge), findsOneWidget);
      // Must NEVER hallucinate Calm or Baseline steady or show dead invite code button
      expect(find.text(strings.baselineSteadyBadge), findsNothing);
      expect(find.byKey(const ValueKey('clinician-invite-patient-btn')), findsNothing);
    });
  });
}
