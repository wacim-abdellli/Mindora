import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/data/clinician_sync_service.dart';
import 'package:mind_forensics/features/clinician/data/demo_clinical_cohort.dart';
import 'package:mind_forensics/features/clinician/domain/clinician_models.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/clinician/domain/visit_diff_model.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/pre_visit_brief_sheet.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/share_with_psychiatrist_sheet.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 5.2: Visit-to-Visit Clinical Diff & 2-Minute Pre-Visit Brief', () {
    test(
      '1. Re-importing archives previousPackets, persists JSON roundtrip, and computes consent-aware VisitComparisonDiff',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final tPrev = DateTime(2026, 11, 1, 10, 0);
        final tCur = DateTime(2026, 11, 15, 10, 0);

        final prevPacket = syncService.buildPatientPacket(
          packetId: 'pkt_v1',
          referenceNow: tPrev,
          patientDisplayName: 'Samira K.',
          patientAnonymousId: 'p_samira',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: true,
          ),
          traces: [
            MindTraceModel(
              id: 'p1',
              date: DateTime(2026, 10, 30, 9, 0),
              overallMood: 'calm',
              moodIntensity: 4,
              energyLevel: 7,
              anxietyLevel: 3,
              sleepHours: 7.5,
              contextTags: const ['routine_kept'],
              createdAt: tPrev,
              updatedAt: tPrev,
            ),
            MindTraceModel(
              id: 'p2',
              date: DateTime(2026, 10, 31, 20, 0),
              overallMood: 'calm',
              moodIntensity: 5,
              energyLevel: 6,
              anxietyLevel: 3,
              sleepHours: 7.5,
              contextTags: const ['routine_kept'],
              createdAt: tPrev,
              updatedAt: tPrev,
            ),
          ],
          cases: const [],
          symptomReports: const [],
        );

        final curPacketFull = syncService.buildPatientPacket(
          packetId: 'pkt_v2',
          referenceNow: tCur,
          patientDisplayName: 'Samira K.',
          patientAnonymousId: 'p_samira',
          consentScope: const ClinicalConsentScope(
            windowDays: 30,
            includeMoodMetrics: true,
            includeSleepEnergyAnxiety: true,
          ),
          traces: [
            MindTraceModel(
              id: 'c1',
              date: DateTime(2026, 11, 14, 9, 0),
              overallMood: 'anxious',
              moodIntensity: 7,
              energyLevel: 4,
              anxietyLevel: 7,
              sleepHours: 5.5,
              contextTags: const ['high_workload'],
              createdAt: tCur,
              updatedAt: tCur,
            ),
            MindTraceModel(
              id: 'c2',
              date: DateTime(2026, 11, 15, 20, 0),
              overallMood: 'anxious',
              moodIntensity: 8,
              energyLevel: 4,
              anxietyLevel: 7,
              sleepHours: 5.5,
              contextTags: const ['high_workload'],
              createdAt: tCur,
              updatedAt: tCur,
            ),
          ],
          cases: const [],
          symptomReports: const [],
          preVisitAgenda: PreVisitAgenda(
            selectedTopics: const ['Sleep shifts'],
            focusPlanFeedback: 'Felt helpful',
            updatedAt: tCur,
          ),
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(clinicianRosterProvider.notifier)
            .importPacket(prevPacket);
        final updated = await container
            .read(clinicianRosterProvider.notifier)
            .importPacket(curPacketFull);

        expect(updated.previousPackets.length, equals(1));
        expect(updated.previousPackets.first.packetId, equals('pkt_v1'));

        // JSON persistence roundtrip
        final roundtripped = ClinicianPatientRecord.fromJson(updated.toJson());
        final diff = roundtripped.visitDiff;
        expect(diff, isNotNull);
        expect(diff!.daysBetween, equals(14));
        expect(diff.moodDelta, equals(3.0)); // 7.5 - 4.5
        expect(diff.sleepDelta, equals(-2.0)); // 5.5 - 7.5
        expect(diff.eveningIntensityDelta, equals(3.0)); // 8.0 - 5.0
        expect(diff.addedContextTags, contains('high_workload'));
        expect(diff.reducedContextTags, contains('routine_kept'));
        expect(diff.focusPlanFeedback, equals('Felt helpful'));

        // Consent gate check: somatic toggle off must suppress sleep/energy/anxiety & tag diffs
        final restrictedCur = curPacketFull.copyWith(
          consentScope: curPacketFull.consentScope.copyWith(
            includeSleepEnergyAnxiety: false,
          ),
        );
        final restrictedDiff =
            VisitComparisonDiff.compute(prevPacket, restrictedCur);
        expect(restrictedDiff.moodDelta, isNotNull);
        expect(restrictedDiff.sleepDelta, isNull);
        expect(restrictedDiff.energyDelta, isNull);
        expect(restrictedDiff.anxietyDelta, isNull);
        expect(restrictedDiff.addedContextTags, isEmpty);
        expect(restrictedDiff.reducedContextTags, isEmpty);
      },
    );

    test(
      '2. PreVisitAgenda.focusPlanFeedback survives MF-CLINIC-V1 encryption and renders in EHR summary with Since Last Visit diff',
      () async {
        const syncService = ClinicianSyncService(defaultPbkdf2Iterations: 2000);
        final now = DateTime(2026, 11, 22, 9, 0);
        final packet = syncService.buildPatientPacket(
          referenceNow: now,
          patientDisplayName: 'Yasmine R.',
          patientAnonymousId: 'p_yasmine',
          consentScope: const ClinicalConsentScope(),
          traces: [
            MindTraceModel(
              id: 'ty1',
              date: now,
              overallMood: 'calm',
              moodIntensity: 4,
              sleepHours: 7.5,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          cases: const [],
          symptomReports: const [],
          preVisitAgenda: PreVisitAgenda(
            selectedTopics: const ['Coping review'],
            focusPlanFeedback: 'Too heavy right now',
            updatedAt: now,
          ),
        );

        final code = await syncService.encryptPacketToShareCode(
          packet,
          'visit-brief-2026',
          pbkdf2Iterations: 2000,
        );
        final decrypted = await syncService.decryptShareCode(
          code,
          'visit-brief-2026',
        );
        expect(
          decrypted.preVisitAgenda?.focusPlanFeedback,
          equals('Too heavy right now'),
        );

        final nadia = DemoClinicalCohort.buildRecords(referenceNow: now).first;
        final ehr = syncService.generateEhrClinicalNote(
          nadia,
          const AppStrings('en'),
        );
        expect(ehr, contains('[2b] SINCE LAST VISIT COMPARISON'));
        expect(ehr, contains('Between-session focus feedback: Felt helpful'));
        expect(ehr.toLowerCase(), isNot(contains('cbt treatment')));
        expect(ehr.toLowerCase(), isNot(contains('relapse')));
      },
    );

    testWidgets(
      '3. PreVisitBriefSheet hands off feedback + topics to ShareWithPsychiatristSheet, and Dossier Since Last Visit renders cleanly at 320px AR RTL',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'pb_t1',
                date: now,
                overallMood: 'anxious',
                moodIntensity: 7,
                sleepHours: 6.0,
                behavioralResponse: 'Breathing',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container.read(mindTraceControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.notifier).savePlan(
              PostVisitFocusPlan(
                planId: 'pb_plan_1',
                clinicianName: 'Dr. Amira Ben Salem',
                createdAt: now,
                focusItems: const [
                  FocusGoalItem(
                    id: 'g1',
                    title: 'Protect wind-down window',
                    isCompleted: true,
                  ),
                  FocusGoalItem(
                    id: 'g2',
                    title: 'Log evening mood once',
                  ),
                ],
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('brief_host'),
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: ElevatedButton(
                      onPressed: () => PreVisitBriefSheet.show(context),
                      child: const Text('Open Brief'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Brief'));
        await tester.pumpAndSettle();

        expect(find.text('2-Minute Visit Brief'), findsOneWidget);
        expect(find.text('1 of 2 completed'), findsOneWidget);

        await tester.ensureVisible(find.text('Felt helpful'));
        await tester.tap(find.text('Felt helpful'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Sleep shifts'));
        await tester.tap(find.text('Sleep shifts'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text('Continue to Share with Psychiatrist'),
        );
        await tester.tap(find.text('Continue to Share with Psychiatrist'));
        await tester.pumpAndSettle();

        expect(find.byType(ShareWithPsychiatristSheet), findsOneWidget);
        expect(find.textContaining('Felt helpful'), findsOneWidget);

        // Verify ClinicianPatientDetailScreen Since Last Visit card at 320px + 1.35x Arabic RTL
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        const arStrings = AppStrings('ar');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: const ValueKey('dossier_diff_ar_320'),
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.35),
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: ClinicianPatientDetailScreen(
                      patientId: 'demo_nadia_b',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text(arStrings.sinceLastVisitTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(arStrings.sinceLastVisitTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
