import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/domain/auth_state.dart';
import 'package:mind_forensics/features/auth/domain/auth_user.dart';
import 'package:mind_forensics/features/case_file/presentation/case_report_screen.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_weekly_rhythm_card.dart';
import 'package:mind_forensics/features/insights/data/pattern_awareness_service.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:mind_forensics/features/profile/presentation/widgets/edit_about_me_sheet.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/progressive_details_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_month_calendar.dart';

class _StubAuthController extends AuthController {
  _StubAuthController(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

class _StubTraceNotifier extends MindTraceNotifier {
  _StubTraceNotifier(this._initial);
  List<MindTraceModel> _initial;

  @override
  Future<List<MindTraceModel>> build() async => _initial;

  @override
  Future<void> recordCheckIn(
    MindTraceModel trace, {
    bool generateAi = true,
  }) async {
    _initial = [..._initial, trace];
    state = AsyncData(_initial);
  }

  @override
  Future<void> updateCheckIn(MindTraceModel trace) async {
    _initial = [
      for (final t in _initial) t.id == trace.id ? trace : t,
    ];
    state = AsyncData(_initial);
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _initial = _initial.where((t) => t.id != id).toList();
    state = AsyncData(_initial);
  }

  @override
  Future<void> toggleTracePrivacy(String traceId) async {
    _initial = [
      for (final t in _initial)
        t.id == traceId ? t.copyWith(isPrivate: !t.isPrivate) : t,
    ];
    state = AsyncData(_initial);
  }
}

class _StubProfileNotifier extends ProfileNotifier {
  _StubProfileNotifier(this._profile);
  PsychologicalProfileModel _profile;

  @override
  Future<PsychologicalProfileModel> build() async => _profile;

  @override
  Future<void> updateAboutMe({
    String? preferredName,
    String? ageRange,
    String? biologicalSex,
    String? preferredLanguage,
    String? personalIntroduction,
    String? additionalContext,
  }) async {
    _profile = _profile.copyWith(
      preferredName: preferredName ?? _profile.preferredName,
      ageRange: ageRange ?? _profile.ageRange,
      preferredLanguage: preferredLanguage ?? _profile.preferredLanguage,
      personalIntroduction:
          personalIntroduction ?? _profile.personalIntroduction,
      additionalContext: additionalContext ?? _profile.additionalContext,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(_profile);
  }
}

class _StubFocusNotifier extends PostVisitFocusNotifier {
  _StubFocusNotifier(this._plan);
  final PostVisitFocusPlan? _plan;

  @override
  Future<PostVisitFocusPlan?> build() async => _plan;
}

class _StubClinicSyncNotifier extends ClinicSyncStatusNotifier {
  _StubClinicSyncNotifier(this._status);
  final ClinicSyncStatus _status;

  @override
  ClinicSyncStatus build() => _status;
}

AuthUser _clinicPatientUser({
  String id = 'pat_phase5',
  String name = 'Amira',
  String doctorName = 'Dr. Amine',
  String clinicName = 'Clinique El Amen',
}) {
  return AuthUser(
    id: id,
    codename: name,
    authType: AuthType.clinicPin,
    clinicId: 'clinic_1',
    doctorId: 'doc_1',
    doctorName: doctorName,
    clinicName: clinicName,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  const en = AppStrings('en');
  final lightTheme = buildMindTheme(Brightness.light);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 5 — Today (HomeScreen)', () {
    testWidgets(
      'Check-in card supports optional note + pre-sync privacy lock and honest paused sync pill',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final clinicUser = _clinicPatientUser();

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: clinicUser,
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
            mindTraceControllerProvider.overrideWith(
              () => _StubTraceNotifier(const []),
            ),
            clinicSyncStatusProvider.overrideWith(
              () => _StubClinicSyncNotifier(
                ClinicSyncStatus(
                  phase: ClinicSyncPhase.pausedOrError,
                  lastSyncedAt: DateTime(2026, 11, 1),
                ),
              ),
            ),
            postVisitFocusControllerProvider.overrideWith(
              () => _StubFocusNotifier(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Honest sync pill must show "Sync paused" even when lastSyncedAt != null
        expect(find.text(en.syncPausedQuietLabel), findsOneWidget);
        expect(find.text(en.syncedQuietLabel), findsNothing);

        // Tap mood tile -> reveals optional note chip & pre-sync privacy toggle
        await tester.tap(find.text(en.plainMoodLabel('calm')).first);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('today-add-note-toggle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('today-keep-private-toggle')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('today-add-note-toggle')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('today-quick-note-field')),
          'Walked by the sea before lunch.',
        );

        await tester.tap(
          find.byKey(const ValueKey('today-keep-private-toggle')),
        );
        await tester.pumpAndSettle();

        // Tap Medium strength to auto-save with note + isPrivate already set
        await tester.tap(find.text(en.strengthMedium));
        await tester.pumpAndSettle();

        final saved = container.read(mindTraceControllerProvider).value ?? [];
        expect(saved.length, 1);
        expect(saved.first.journalText, 'Walked by the sea before lunch.');
        expect(saved.first.isPrivate, isTrue);

        // Let toast dismiss cleanly
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'Active Focus Plan is elevated directly under Check-In above Weekly Rhythm',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final focusPlan = PostVisitFocusPlan(
          planId: 'plan_1',
          clinicianName: 'Dr. Amine',
          createdAt: DateTime.now(),
          observationCue: 'Notice morning restfulness',
          focusItems: const [
            FocusGoalItem(id: 'g1', title: '15-minute daylight walk'),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mindTraceControllerProvider.overrideWith(
                () => _StubTraceNotifier(const []),
              ),
              postVisitFocusControllerProvider.overrideWith(
                () => _StubFocusNotifier(focusPlan),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkInTop = tester.getTopLeft(find.text(en.howAreYouRightNow)).dy;
        final focusTop =
            tester.getTopLeft(find.text('15-minute daylight walk')).dy;
        final rhythmTop =
            tester.getTopLeft(find.byType(HomeWeeklyRhythmCard)).dy;

        expect(focusTop, greaterThan(checkInTop));
        expect(focusTop, lessThan(rhythmTop));
      },
    );
  });

  group('Phase 5 — My days (TrackScreen & TrackMonthCalendar)', () {
    testWidgets(
      'Supports initialDateKey jump, disables future days, shows detail pills, and canonicalizes What Helped',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final twoDaysAgo = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2));
        final twoDaysKey =
            '${twoDaysAgo.year.toString().padLeft(4, '0')}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';

        final trace = MindTraceModel(
          id: 'tr_rich',
          date: twoDaysAgo.add(const Duration(hours: 9)),
          overallMood: 'calm',
          moodIntensity: 6,
          sleepHours: 7.5,
          energyLevel: 7,
          contextTags: const ['physical_movement'],
          behavioralResponse: 'help_walk, help_breathing',
          journalText: 'Steady morning routine.',
          createdAt: twoDaysAgo,
          updatedAt: twoDaysAgo,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mindTraceControllerProvider.overrideWith(
                () => _StubTraceNotifier([trace]),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: TrackScreen(initialDateKey: twoDaysKey),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Jumped straight to twoDaysKey and shows scannable pills
        expect(find.text('Steady morning routine.'), findsOneWidget);
        expect(find.textContaining('7.5h'), findsOneWidget);
        expect(find.textContaining('7/10'), findsOneWidget);
        expect(find.text('Walk'), findsOneWidget);
        expect(find.text('Breathing'), findsOneWidget);

        // Future calendar day is non-interactive when present in current month
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        if (now.day < daysInMonth) {
          String? tapped;
          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme,
              home: Scaffold(
                body: TrackMonthCalendar(
                  month: DateTime(now.year, now.month),
                  traces: const [],
                  selectedDateKey: null,
                  strings: en,
                  onPreviousMonth: () {},
                  onNextMonth: () {},
                  canGoNextMonth: false,
                  onSelectDateKey: (k) => tapped = k,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('${now.day + 1}').first);
          await tester.pumpAndSettle();
          expect(tapped, isNull);
        }
      },
    );

    testWidgets(
      'ProgressiveDetailsSheet lets user edit mood on Card 1 and saves canonical What Helped keys',
      (tester) async {
        tester.view.physicalSize = const Size(430, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final trace = MindTraceModel(
          id: 'tr_edit',
          date: now,
          overallMood: 'calm',
          moodIntensity: 5,
          behavioralResponse: 'Walk',
          createdAt: now,
          updatedAt: now,
        );
        final stubTraces = _StubTraceNotifier([trace]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mindTraceControllerProvider.overrideWith(() => stubTraces),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ProgressiveDetailsSheet(trace: trace),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Update mood to Good on Card 1
        await tester.tap(find.byKey(const ValueKey('progressive-mood-good')));
        await tester.pumpAndSettle();

        // Advance to Card 3 (Context & What Helped)
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.skipBtn));
        await tester.pumpAndSettle();

        // Tap Breathing chip
        await tester.tap(find.text('Breathing'));
        await tester.pumpAndSettle();

        // Save via Done button
        await tester.tap(
          find.byKey(const ValueKey('progressive-sheet-done-btn')),
        );
        await tester.pumpAndSettle();

        final updated = stubTraces._initial.first;
        expect(updated.overallMood, 'good');
        expect(updated.behavioralResponse, contains('help_walk'));
        expect(updated.behavioralResponse, contains('help_breathing'));
        await tester.pump(const Duration(seconds: 4));
      },
    );
  });

  group('Phase 5 — Talk & CaseReportScreen', () {
    testWidgets(
      'FlashCaseScreen renders 1-tap privacy pill and AI companion disclaimer bar',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: lightTheme,
              home: const FlashCaseScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('talk-header-privacy-pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('talk-companion-disclaimer-bar')),
          findsOneWidget,
        );
        expect(find.text(en.talkSharedShortPill), findsOneWidget);

        // Tap 1-tap privacy pill -> flips to Private immediately
        await tester.tap(find.byKey(const ValueKey('talk-header-privacy-pill')));
        await tester.pumpAndSettle();
        expect(find.text(en.talkPrivateShortPill), findsOneWidget);
        expect(
          find.byKey(const ValueKey('talk-private-lock-badge')),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'AiCompanionHubView supports searching past talks and exposes View summary chip',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final cases = [
          CaseModel(
            id: 'c_work',
            caseNumber: 'CASE-001',
            title: 'Work pressure reflection',
            incidentDescription: 'Tough deadline',
            findingsSummary: 'Pacing helped.',
            conversationMode: ConversationMode.exploreThought,
            currentStage: CaseStage.conclusion,
            createdAt: now,
            updatedAt: now,
          ),
          CaseModel(
            id: 'c_sleep',
            caseNumber: 'CASE-002',
            title: 'Late night thoughts',
            incidentDescription: 'Hard to unwind',
            conversationMode: ConversationMode.grounding,
            currentStage: CaseStage.incident,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              savedCasesProvider.overrideWith((ref) async => cases),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const Scaffold(body: AiCompanionHubView()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('hub-summary-c_work')), findsOneWidget);
        expect(find.byKey(const ValueKey('hub-summary-c_sleep')), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('talk-history-search-field')),
          'Late night',
        );
        await tester.pumpAndSettle();

        expect(find.text('Late night thoughts'), findsOneWidget);
        expect(find.text('Work pressure reflection'), findsNothing);
      },
    );

    testWidgets(
      'CaseReportScreen renders Back to Talk button and non-forensic takeaway dialog',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = LocalCaseRepository(userId: 'local_user');
        final now = DateTime.now();
        await repo.saveCase(
          CaseModel(
            id: 'case_p5',
            caseNumber: 'CASE-009',
            title: 'Evening clarity note',
            currentStage: CaseStage.conclusion,
            incidentDescription: 'Felt rushed after dinner.',
            findingsSummary: 'A short walk calmed my mind.',
            statements: [
              Statement(
                id: 's1',
                speaker: StatementSpeaker.user,
                text: 'I felt rushed.',
                timestamp: now,
              ),
            ],
            createdAt: now,
            updatedAt: now,
          ),
        );

        final router = GoRouter(
          initialLocation: '/case/case_p5',
          routes: [
            GoRoute(
              path: '/case/:id',
              builder: (_, state) =>
                  CaseReportScreen(caseId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: AppRouter.companion,
              builder: (_, _) => const Scaffold(body: Text('TalkDest')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [caseRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp.router(
              theme: lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(en.backToTalkBtn), findsOneWidget);
        await tester.ensureVisible(find.text(en.editBtn));
        await tester.tap(find.text(en.editBtn));
        await tester.pumpAndSettle();

        expect(find.text(en.editMyTakeawayTitle), findsOneWidget);
        expect(find.text(en.saveTakeawayBtn), findsOneWidget);
      },
    );
  });

  group('Phase 5 — Patterns (InsightsScreen & PatternAwarenessService)', () {
    test('PatternAwarenessService ignores minor 6-minute (0.1h) sleep jitter', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 7.5,
        averageEnergyLevel: 6.0,
        averageMoodIntensity: 6.0,
        sleepObservationCount: 14,
        energyObservationCount: 14,
        moodObservationCount: 14,
      );

      final minorJitterTraces = [
        MindTraceModel(
          id: 'j1',
          date: now,
          sleepHours: 7.3,
          energyLevel: 6,
          moodIntensity: 6,
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 'j2',
          date: now.subtract(const Duration(days: 1)),
          sleepHours: 7.4,
          energyLevel: 5,
          moodIntensity: 6,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final divs = PatternAwarenessService.detectDivergences(
        traces: minorJitterTraces,
        baseline: baseline,
      );
      expect(divs, isEmpty);
    });

    testWidgets(
      'InsightsScreen computes true 7-day calendar count and shows valence mood distribution bar',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final traces = [
          MindTraceModel(
            id: 't_now1',
            date: now,
            overallMood: 'good',
            moodIntensity: 7,
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't_now2',
            date: now.subtract(const Duration(hours: 2)),
            overallMood: 'calm',
            moodIntensity: 6,
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't_old1',
            date: now.subtract(const Duration(days: 20)),
            overallMood: 'anxious',
            moodIntensity: 7,
            createdAt: now,
            updatedAt: now,
          ),
          MindTraceModel(
            id: 't_old2',
            date: now.subtract(const Duration(days: 22)),
            overallMood: 'heavy',
            moodIntensity: 6,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mindTraceControllerProvider.overrideWith(
                () => _StubTraceNotifier(traces),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const InsightsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must report 1 day this week (not 4 from allTraces.take(7).length!)
        expect(find.text(en.daysThisWeekCount(1)), findsOneWidget);
        expect(
          find.byKey(const ValueKey('insights-mood-distribution-bar')),
          findsOneWidget,
        );
        expect(find.text(en.moodBalanceTitle), findsOneWidget);
      },
    );
  });

  group('Phase 5 — Me, My Story & Settings', () {
    testWidgets(
      'My Story renders Care from my doctor card, localized goals, non-blank condition tracks, and no placebo Save button',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final clinicUser = _clinicPatientUser(
          id: 'pat_story',
          name: 'Nadia',
          doctorName: 'Dr. Leila Mansour',
          clinicName: 'Cabinet Carthage',
        );
        final profile = PsychologicalProfileModel(
          preferredName: 'Nadia',
          ageRange: '25-44',
          selectedTrackIds: const ['anxietyPanic'],
          selectedGoals: const ['track_mood_sleep', 'doctor_visits'],
          updatedAt: DateTime(2026, 11, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(
                () => _StubAuthController(
                  AuthState(
                    status: AuthStatus.authenticated,
                    user: clinicUser,
                    hasCompletedOnboarding: true,
                  ),
                ),
              ),
              profileControllerProvider.overrideWith(
                () => _StubProfileNotifier(profile),
              ),
              postVisitFocusControllerProvider.overrideWith(
                () => _StubFocusNotifier(null),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const PsychologicalProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('profile-clinic-connection-card')),
          findsOneWidget,
        );
        expect(find.text('Dr. Leila Mansour'), findsOneWidget);
        expect(find.text(en.connectedToClinicBadge), findsOneWidget);
        // No snake_case goal leaks
        expect(find.text('track_mood_sleep'), findsNothing);
        expect(find.text('Track mood & sleep'), findsOneWidget);
        expect(find.text('Prepare for doctor visits'), findsOneWidget);
        // Selected track renders even when legacy conditions list is empty
        expect(find.text('Worry, Tension & Panic'), findsWidgets);
        // Age range 25-44 displays cleanly
        expect(find.text('25-44'), findsOneWidget);
        // Retired fake Save button is gone
        expect(find.text(en.saveProfileBtn), findsNothing);
      },
    );

    testWidgets(
      'EditAboutMeSheet preserves clinic 25-44 age range without wiping to prefer_not_to_say',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final stubProfile = _StubProfileNotifier(
          PsychologicalProfileModel(
            preferredName: 'Sami',
            ageRange: '25-44',
            preferredLanguage: 'en',
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileControllerProvider.overrideWith(() => stubProfile),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: Scaffold(
                body: EditAboutMeSheet(profile: stubProfile._profile),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save changes'));
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        expect(stubProfile._profile.ageRange, '25-44');
      },
    );

    testWidgets(
      'SettingsScreen hides Log out for anonymous local users and shows it for clinic accounts',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Anonymous user -> Log out must be hidden
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(
                () => _StubAuthController(
                  AuthState(
                    status: AuthStatus.authenticated,
                    user: AuthUser(
                      id: 'anon_local',
                      codename: 'Guest',
                      authType: AuthType.anonymous,
                      createdAt: DateTime(2026, 1, 1),
                    ),
                    hasCompletedOnboarding: true,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(en.logOutBtn), findsNothing);

        // 2. Clinic patient -> Log out must be visible
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              authControllerProvider.overrideWith(
                () => _StubAuthController(
                  AuthState(
                    status: AuthStatus.authenticated,
                    user: _clinicPatientUser(id: 'pat_signed_in', name: 'Hedi'),
                    hasCompletedOnboarding: true,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(en.logOutBtn), findsOneWidget);
      },
    );
  });
}
