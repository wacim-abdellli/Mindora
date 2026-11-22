import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/case_stage.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../investigation/domain/forensic_chain.dart';
import '../../investigation/domain/label_type.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/condition_type.dart';
import '../../profile/domain/diagnostic_status.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/clinician_models.dart';
import 'clinician_sync_service.dart';

/// Deterministic fictional demo patient cohort (`isDemoCase: true`) for evaluating
/// the Psychiatrist Workspace out of the box without exposing any real user data.
abstract final class DemoClinicalCohort {
  static List<ClinicianPatientRecord> buildRecords({
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const syncService = ClinicianSyncService();

    // -------------------------------------------------------------------------
    // Patient 1: Nadia B. (Recent evening anxiety escalation + sleep drop)
    // -------------------------------------------------------------------------
    final nadiaTraces = <MindTraceModel>[];
    for (var d = 17; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      final isRecentShift = d <= 3;

      final morningTs = DateTime(day.year, day.month, day.day, 8, 30);
      final isCoolingBaselineDay = d == 6;
      nadiaTraces.add(
        MindTraceModel(
          id: 'demo_nadia_m_$d',
          userId: 'demo_nadia_b',
          date: morningTs,
          overallMood: isRecentShift || isCoolingBaselineDay ? 'restless' : 'calm',
          selectedEmotions: isRecentShift
              ? const ['restless', 'on_edge', 'focused']
              : (isCoolingBaselineDay
                    ? const ['restless', 'focused']
                    : const ['calm', 'focused', 'content']),
          moodIntensity: isRecentShift ? 6 : (isCoolingBaselineDay ? 6 : 4),
          energyLevel: isRecentShift ? 5 : 7,
          anxietyLevel: isRecentShift ? 6 : 3,
          sleepHours: isRecentShift ? 5.1 : 7.6,
          situation: isRecentShift
              ? 'Early deadline notifications before breakfast'
              : 'Morning routine and espresso',
          behavioralResponse: isCoolingBaselineDay
              ? 'Walk'
              : 'Brief breathing pause before opening messages',
          journalText: isRecentShift
              ? 'Woke up before dawn with chest tightness; trying to pace the morning.'
              : 'Slept steadily and started work calmly.',
          contextTags: isRecentShift
              ? const ['high_workload', 'late_caffeine_screens']
              : (isCoolingBaselineDay
                    ? const ['physical_movement', 'routine_kept']
                    : const ['routine_kept', 'sleep_consistent']),
          createdAt: morningTs,
          updatedAt: morningTs,
        ),
      );

      if (d <= 6) {
        final eveningTs = DateTime(day.year, day.month, day.day, 20, 15);
        nadiaTraces.add(
          MindTraceModel(
            id: 'demo_nadia_e_$d',
            userId: 'demo_nadia_b',
            date: eveningTs,
            overallMood: isRecentShift ? 'anxious' : (isCoolingBaselineDay ? 'calm' : 'restless'),
            selectedEmotions: isRecentShift
                ? const ['anxious', 'overwhelmed', 'exhausted']
                : (isCoolingBaselineDay
                      ? const ['calm', 'relieved']
                      : const ['restless', 'wired']),
            moodIntensity: isRecentShift ? 8 : (isCoolingBaselineDay ? 4 : 5),
            energyLevel: isRecentShift ? 3 : 5,
            anxietyLevel: isRecentShift ? 8 : 4,
            sleepHours: isRecentShift ? 5.1 : 7.4,
            situation: 'Reviewing tomorrow’s schedule late evening',
            behavioralResponse: isCoolingBaselineDay
                ? 'Walk'
                : 'Turned off notifications after 21:00',
            journalText: isRecentShift
                ? 'Mind keeps looping on worst-case timelines when the house gets quiet.'
                : 'Slightly wired after finishing emails.',
            contextTags: isRecentShift
                ? const ['late_caffeine_screens', 'high_workload']
                : (isCoolingBaselineDay
                      ? const ['physical_movement', 'routine_kept']
                      : const ['physical_movement']),
            createdAt: eveningTs,
            updatedAt: eveningTs,
          ),
        );
      }
    }

    final nadiaCase = CaseModel(
      id: 'demo_nadia_case_1',
      userId: 'demo_nadia_b',
      caseNumber: 'SESSION 01',
      title: 'Evening rumination before team presentation',
      conversationMode: ConversationMode.exploreThought,
      createdAt: today.subtract(const Duration(days: 2)),
      updatedAt: today.subtract(const Duration(days: 1)),
      currentStage: CaseStage.conclusion,
      incidentDescription:
          'Noticed my chest tighten at 20:00 while re-reading slides I already checked twice.',
      chain: const ForensicChain(
        trigger: 'Re-reading tomorrow’s slides after dinner',
        thought: 'If I pause on one question, everyone will think I am unprepared.',
        thoughtLabel: LabelType.assumption,
        emotion: 'Anxious / Overwhelmed',
        emotionIntensity: 8,
        behavior: 'Stayed up past midnight rewriting notes instead of resting',
      ),
      findingsSummary:
          'Fact: Slides are complete and two colleagues signed off. Assumption: One imperfect Q&A erases preparation.',
      userConclusion:
          'Preparation needs a clear stopping point by 20:00 so sleep stays protected.',
      emotionTags: const ['anxious', 'overwhelmed'],
      isCompleted: true,
      isPrivate: false,
    );

    final nadiaSymptoms = [
      SymptomReport(
        id: 'demo_nadia_sym_1',
        symptomIds: const ['sym_constant_apprehension', 'sym_intrusive_loops'],
        intensity: 8,
        onset: 'few_days',
        somaticLocation: 'chest',
        contextTrigger: 'work_academic',
        copingStrategiesTried: const ['Offline walk', 'Scheduled worry break'],
        stabilizingStrategy: 'Closing screens 60 minutes prior to sleep window',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];

    final nadiaProfile = PsychologicalProfileModel(
      userId: 'demo_nadia_b',
      preferredName: 'Nadia B.',
      ageRange: '25-34',
      conditions: const [
        UserConditionEntry(
          condition: ConditionType.generalizedAnxiety,
          status: DiagnosticStatus.professionallyDiagnosed,
        ),
        UserConditionEntry(
          condition: ConditionType.sleepDifficulties,
          status: DiagnosticStatus.selfIdentifiedExploring,
        ),
      ],
      selectedGoals: const [
        'Protect evening sleep consistency',
        'Interrupt catastrophic thought loops earlier',
      ],
      communicationTone: 'calm_analytical',
      updatedAt: today,
    );

    final nadiaPacket = syncService.buildPatientPacket(
      packetId: 'demo_pkt_nadia_v1',
      referenceNow: now,
      patientDisplayName: 'Nadia B.',
      patientAnonymousId: 'demo_nadia_b',
      consentScope: const ClinicalConsentScope(
        windowDays: 30,
        includeMoodMetrics: true,
        includeSleepEnergyAnxiety: true,
        includePersonalNotes: true,
        includeSharedCases: true,
        includeSymptomReports: true,
        includePsychologicalProfile: true,
        includePreVisitAgenda: true,
      ),
      traces: nadiaTraces,
      cases: [nadiaCase],
      symptomReports: nadiaSymptoms,
      profile: nadiaProfile,
      preVisitAgenda: PreVisitAgenda(
        selectedTopics: const ['Sleep shifts', 'Evening dips'],
        patientQuestion:
            'Why does my apprehension spike after 19:00 even when the daytime felt manageable?',
        whatHelpedRecently: '20-minute offline walk after leaving the desk',
        updatedAt: today,
      ),
    );

    // -------------------------------------------------------------------------
    // Patient 2: Karim M. (Diurnal morning heaviness -> calmer evening shift)
    // -------------------------------------------------------------------------
    final karimTraces = <MindTraceModel>[];
    for (var d = 15; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      final morningTs = DateTime(day.year, day.month, day.day, 9, 10);
      karimTraces.add(
        MindTraceModel(
          id: 'demo_karim_m_$d',
          userId: 'demo_karim_m',
          date: morningTs,
          overallMood: 'heavy',
          selectedEmotions: const ['heavy', 'numb', 'exhausted'],
          moodIntensity: d <= 4 ? 7 : 6,
          energyLevel: 3,
          anxietyLevel: 4,
          sleepHours: 8.3,
          situation: 'Waking up with slow inertia despite long sleep',
          journalText: 'Mornings feel weighted; hard to start small tasks before noon.',
          createdAt: morningTs,
          updatedAt: morningTs,
        ),
      );

      final eveningTs = DateTime(day.year, day.month, day.day, 19, 45);
      karimTraces.add(
        MindTraceModel(
          id: 'demo_karim_e_$d',
          userId: 'demo_karim_m',
          date: eveningTs,
          overallMood: 'calm',
          selectedEmotions: const ['calm', 'relieved', 'hopeful'],
          moodIntensity: 3,
          energyLevel: 6,
          anxietyLevel: 2,
          sleepHours: 8.3,
          behavioralResponse: 'Brief tea & sunlight walk at 17:00',
          journalText: 'By early evening the heaviness lifts and focus returns.',
          contextTags: const ['physical_movement', 'social_connection'],
          createdAt: eveningTs,
          updatedAt: eveningTs,
        ),
      );
    }

    final karimCase = CaseModel(
      id: 'demo_karim_case_1',
      userId: 'demo_karim_m',
      caseNumber: 'SESSION 01',
      title: 'All-or-nothing self-evaluation on slow mornings',
      conversationMode: ConversationMode.exploreThought,
      createdAt: today.subtract(const Duration(days: 4)),
      updatedAt: today.subtract(const Duration(days: 2)),
      currentStage: CaseStage.findings,
      incidentDescription:
          'Missed my 09:00 study target and felt the entire day was wasted.',
      chain: const ForensicChain(
        trigger: 'Not finishing morning reading block by 10:00',
        thought: 'If the morning starts slow, the whole day will amount to nothing.',
        thoughtLabel: LabelType.interpretation,
        emotion: 'Heavy / Sad',
        emotionIntensity: 7,
        behavior: 'Withdrew until 16:30 before re-engaging',
      ),
      findingsSummary:
          'Afternoon and evening logs consistently show recovery by 19:00.',
      userConclusion: 'Slow mornings do not erase afternoon capacity.',
      emotionTags: const ['heavy', 'sad'],
      isCompleted: true,
      isPrivate: false,
    );

    final karimPacket = syncService.buildPatientPacket(
      packetId: 'demo_pkt_karim_v1',
      referenceNow: now,
      patientDisplayName: 'Karim M.',
      patientAnonymousId: 'demo_karim_m',
      consentScope: const ClinicalConsentScope(
        windowDays: 30,
        includeMoodMetrics: true,
        includeSleepEnergyAnxiety: true,
        includePersonalNotes: true,
        includeSharedCases: true,
        includeSymptomReports: true,
        includePsychologicalProfile: false,
        includePreVisitAgenda: true,
      ),
      traces: karimTraces,
      cases: [karimCase],
      symptomReports: [
        SymptomReport(
          id: 'demo_karim_sym_1',
          symptomIds: const ['sym_persistent_heaviness', 'sym_anhedonia'],
          intensity: 6,
          onset: 'chronic',
          somaticLocation: 'general_fatigue',
          contextTrigger: 'solitude',
          copingStrategiesTried: const ['Late-afternoon sunlight walk'],
          createdAt: today.subtract(const Duration(days: 3)),
        ),
      ],
      preVisitAgenda: PreVisitAgenda(
        selectedTopics: const ['Review what helped', 'Follow-up & medication questions'],
        patientQuestion:
            'Evenings feel noticeably steadier — should I structure harder work after 16:00?',
        whatHelpedRecently: 'Starting with one 10-minute task after lunch without pressure',
        updatedAt: today.subtract(const Duration(days: 1)),
      ),
    );

    // -------------------------------------------------------------------------
    // Patient 3: Lina S. (Steady euthymic baseline for triage contrast)
    // -------------------------------------------------------------------------
    final linaTraces = <MindTraceModel>[];
    for (var d = 13; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      final ts = DateTime(day.year, day.month, day.day, 18, 20);
      linaTraces.add(
        MindTraceModel(
          id: 'demo_lina_$d',
          userId: 'demo_lina_s',
          date: ts,
          overallMood: 'calm',
          selectedEmotions: const ['calm', 'content', 'grateful'],
          moodIntensity: d.isEven ? 3 : 4,
          energyLevel: 7,
          anxietyLevel: 2,
          sleepHours: 7.5,
          contextTags: const ['routine_kept', 'sleep_consistent'],
          createdAt: ts,
          updatedAt: ts,
        ),
      );
    }

    final linaPacket = syncService.buildPatientPacket(
      packetId: 'demo_pkt_lina_v1',
      referenceNow: now,
      patientDisplayName: 'Lina S.',
      patientAnonymousId: 'demo_lina_s',
      consentScope: const ClinicalConsentScope(
        windowDays: 30,
        includeMoodMetrics: true,
        includeSleepEnergyAnxiety: true,
        includePersonalNotes: false,
        includeSharedCases: false,
        includeSymptomReports: false,
        includePsychologicalProfile: false,
        includePreVisitAgenda: false,
      ),
      traces: linaTraces,
      cases: const [],
      symptomReports: const [],
    );

    return [
      ClinicianPatientRecord(
        patientId: 'demo_nadia_b',
        displayName: 'Nadia B.',
        isDemoCase: true,
        importedAt: today.subtract(const Duration(days: 14)),
        lastSyncedAt: now.subtract(const Duration(hours: 2)),
        latestPacket: nadiaPacket,
        clinicianNotes: [
          ClinicianSessionNote(
            id: 'demo_note_nadia_1',
            createdAt: today.subtract(const Duration(days: 14)),
            updatedAt: today.subtract(const Duration(days: 14)),
            category: ClinicianNoteCategory.plan,
            content:
                'Track sleep window vs late-evening cognitive activation across next 2 weeks before follow-up.',
          ),
        ],
      ),
      ClinicianPatientRecord(
        patientId: 'demo_karim_m',
        displayName: 'Karim M.',
        isDemoCase: true,
        importedAt: today.subtract(const Duration(days: 12)),
        lastSyncedAt: today.subtract(const Duration(days: 1)),
        latestPacket: karimPacket,
        reviewedAt: today.subtract(const Duration(days: 2)),
        clinicianNotes: [
          ClinicianSessionNote(
            id: 'demo_note_karim_1',
            createdAt: today.subtract(const Duration(days: 10)),
            updatedAt: today.subtract(const Duration(days: 10)),
            category: ClinicianNoteCategory.objective,
            content:
                'Clear diurnal gradient noted: morning inertia/heaviness easing significantly toward late afternoon.',
          ),
        ],
      ),
      ClinicianPatientRecord(
        patientId: 'demo_lina_s',
        displayName: 'Lina S.',
        isDemoCase: true,
        importedAt: today.subtract(const Duration(days: 10)),
        lastSyncedAt: today.subtract(const Duration(days: 3)),
        latestPacket: linaPacket,
        reviewedAt: today.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
