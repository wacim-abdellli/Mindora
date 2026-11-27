import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_switch.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/domain/auth_state.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_entry_detail_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
  });

  group('Phase 3 Patient Minimalism & Privacy Lock', () {
    testWidgets(
      'HomeScreen removes doctor-visit-ready card and shows quiet clinic sync status pill',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(profileControllerProvider.future);
        await container
            .read(profileControllerProvider.notifier)
            .updateAboutMe(preferredName: 'Salma');
        await container
            .read(profileControllerProvider.notifier)
            .updateProfessionalSupport('Followed by psychiatrist');

        // Authenticate clinic patient via provisioning + QR flow
        final authRepo = container.read(clinicAuthRepositoryProvider);
        final provision = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis_01',
          doctorName: 'Dr. Amine',
          clinicName: 'Cabinet Amine',
          displayName: 'Salma',
          loginIdentifier: '22111222',
          ageRange: '25-44',
          preferredLanguage: 'en',
        );
        final signedIn = await container
            .read(authControllerProvider.notifier)
            .signInWithClinicQr(provision.qrPayload);
        expect(signedIn, isTrue, reason: 'QR sign-in failed: ${container.read(authControllerProvider).errorMessage}');
        expect(container.read(authControllerProvider).user?.isClinicAccount, isTrue);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('home-doctor-readiness-card')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('home-quiet-sync-pill')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TrackEntryDetailSheet exposes Keep just for me switch and persists privacy lock',
      (tester) async {
        final now = DateTime.now();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final trace = MindTraceModel(
          id: 'trace_lock_1',
          date: now,
          overallMood: 'anxious',
          moodIntensity: 6,
          journalText: 'Long day at the office',
          createdAt: now,
          updatedAt: now,
        );
        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(trace, generateAi: false);

        const en = AppStrings('en');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: Scaffold(
                body: TrackEntryDetailSheet(
                  trace: trace,
                  onEdit: () {},
                  onExploreWithAi: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(en.keepJustForMeLabel), findsOneWidget);
        expect(find.text(en.sharedWithDoctorStatus), findsOneWidget);

        await tester.tap(find.byType(MindSwitch));
        await tester.pumpAndSettle();

        expect(find.text(en.keepJustForMeDesc), findsOneWidget);
        final updated = container
            .read(mindTraceControllerProvider)
            .value
            ?.firstWhere((t) => t.id == trace.id);
        expect(updated?.isPrivate, isTrue);
      },
    );

    testWidgets(
      'SettingsScreen hides JSON/clinician items and signs out clinic user after confirmation',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authRepo = container.read(clinicAuthRepositoryProvider);
        final provision = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis_01',
          doctorName: 'Dr. Amine',
          clinicName: 'Cabinet Amine',
          displayName: 'Hedi',
          loginIdentifier: '55444333',
          ageRange: '65+',
          preferredLanguage: 'en',
        );
        await container
            .read(authControllerProvider.notifier)
            .signInWithClinicQr(provision.qrPayload);

        const en = AppStrings('en');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(en.connectedToDoctorBadge('Dr. Amine')),
          findsOneWidget,
        );
        expect(find.text(en.backupNowBtn), findsNothing);
        expect(find.text(en.exportVaultBtn), findsNothing);
        expect(find.text(en.doctorVisitSection), findsNothing);

        final changePinFinder = find.text(en.changePinBtn);
        await tester.ensureVisible(changePinFinder);
        expect(changePinFinder, findsOneWidget);

        final logOutFinder = find.text(en.logOutBtn);
        await tester.ensureVisible(logOutFinder);
        await tester.tap(logOutFinder);
        await tester.pumpAndSettle();

        expect(find.text(en.logOutConfirmTitle), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, en.logOutBtn));
        await tester.pumpAndSettle();

        expect(
          container.read(authControllerProvider).status,
          AuthStatus.unauthenticated,
        );
      },
    );
  });
}
