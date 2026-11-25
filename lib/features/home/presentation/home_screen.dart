import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../clinician/controllers/clinician_providers.dart';
import '../../clinician/presentation/widgets/pre_visit_brief_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/emotion_descriptors.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../onboarding/domain/app_personalization_engine.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import '../../track/presentation/widgets/progressive_details_sheet.dart';
import 'widgets/home_clinical_pulse_card.dart';
import 'widgets/home_daily_check_in_card.dart';
import 'widgets/home_organic_exercise_art.dart';
import 'widgets/home_post_visit_focus_card.dart';
import 'widgets/home_weekly_rhythm_card.dart';

/// Single-job `Today` screen:
/// 1. Warm greeting
/// 2. 2-tap MoodFace + strength check-in (`<= 32 words` above the fold)
/// 3. Non-punitive 7-day colored MoodFace strip
/// 4. Optional active Doctor's Plan (only when present)
/// 5. One calm 1-minute breather shortcut
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedMoodIndex = 1; // Default Calm
  double _moodIntensity = 6.0;
  final TextEditingController _todayNoteController = TextEditingController();

  final List<({String key, IconData icon})> _moodOptions = const [
    (key: 'good', icon: Icons.wb_sunny_outlined),
    (key: 'calm', icon: Icons.spa_outlined),
    (key: 'anxious', icon: Icons.bolt_outlined),
    (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    (key: 'heavy', icon: Icons.grain_outlined),
    (key: 'restless', icon: Icons.air_outlined),
  ];

  @override
  void dispose() {
    _todayNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickCheckIn(
    String moodKey,
    int intensity, {
    bool createNew = false,
  }) async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final todayTrace = ref.read(todayTraceProvider);
    final strings = ref.read(appStringsProvider);

    late final MindTraceModel savedTrace;
    if (todayTrace != null && !createNew) {
      savedTrace = todayTrace.copyWith(
        overallMood: moodKey,
        moodIntensity: intensity,
        selectedEmotions: <String>[
          moodKey,
          ...todayTrace.selectedEmotions.where(
            (e) =>
                EmotionDescriptor.canonicalKey(e).toLowerCase() != moodKey,
          ),
        ],
        updatedAt: now,
      );
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(savedTrace);
    } else {
      savedTrace = MindTraceModel(
        id: 'trace_${now.millisecondsSinceEpoch}',
        userId: ref.read(authControllerProvider).user?.id ?? 'local_user',
        date: now,
        overallMood: moodKey,
        moodIntensity: intensity,
        energyLevel: null,
        selectedEmotions: [moodKey],
        createdAt: now,
        updatedAt: now,
      );
      await ref
          .read(mindTraceControllerProvider.notifier)
          .recordCheckIn(savedTrace, generateAi: false);
    }

    ref.read(activeMoodProvider.notifier).setMoodByKey(savedTrace.overallMood);

    // Sync encrypted lightweight local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyManager = ref.read(secureKeyManagerProvider);
      final authState = ref.read(authControllerProvider);
      final cipher = await keyManager.getCipherForUser(authState.user?.id);
      await EncryptedStorageHelper.writeEncrypted(
        prefs: prefs,
        key: 'mf_last_checkin_cache_v1',
        plaintext: jsonEncode({
          'mood': moodKey,
          'intensity': intensity,
          'timestamp': now.toIso8601String(),
        }),
        cipher: cipher,
      );
    } catch (_) {}

    if (mounted) {
      showMindToast(context, strings.checkInSavedSnackbar);
    }
  }

  Future<void> _updateTodayClinicalPulse(
    MindTraceModel Function(MindTraceModel? existing) updater,
  ) async {
    final todayTrace = ref.read(todayTraceProvider);
    final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
    final updated = updater(todayTrace).copyWith(userId: userId);
    final notifier = ref.read(mindTraceControllerProvider.notifier);
    if (todayTrace != null) {
      await notifier.updateCheckIn(updated);
    } else {
      await notifier.recordCheckIn(updated, generateAi: false);
    }
  }

  String _getLocalizedGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.greetingMorning;
    if (hour < 18) return strings.greetingAfternoon;
    return strings.greetingEvening;
  }

  String _getMoodLabel(String key, AppStrings strings) =>
      strings.plainMoodLabel(key);

  Color _getMoodColor(String key) => MindTokens.moodColor(AppMood.fromKey(key));

  ConversationMode _recommendedModeForTrace(MindTraceModel trace) {
    final moodKey = EmotionDescriptor.canonicalKey(
      trace.overallMood,
    ).toLowerCase();
    if (trace.moodIntensity >= 8) return ConversationMode.grounding;
    return switch (moodKey) {
      'frustrated' || 'heavy' => ConversationMode.understandEmotion,
      'anxious' || 'restless' => ConversationMode.exploreThought,
      _ => ConversationMode.guidedReflection,
    };
  }

  Future<void> _openCompanionForTrace(
    MindTraceModel trace,
    AppStrings strings,
  ) async {
    HapticFeedback.mediumImpact();
    final noteText = trace.journalText?.trim();
    if (noteText != null &&
        noteText.isNotEmpty &&
        CrisisKeywords.evaluateText(noteText) == 2) {
      if (mounted) SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

    final mode = _recommendedModeForTrace(trace);
    ref.read(currentConversationModeProvider.notifier).setMode(mode);
    final moodLabel = _getMoodLabel(trace.overallMood, strings);
    final seedPrompt = strings.talkAboutMoodPrompt(
      moodLabel,
      trace.moodIntensity,
      noteText,
    );

    final controller = ref.read(activeCaseControllerProvider.notifier);
    await controller.startNewCase(seedPrompt, mode: mode);
    unawaited(controller.requestAiReply());
    if (mounted) {
      GoRouter.maybeOf(context)?.go(AppRouter.companion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final preferredName = ref.watch(
      profileControllerProvider.select((p) => p.value?.preferredName),
    );
    final userName = (preferredName != null && preferredName.isNotEmpty)
        ? preferredName
        : strings.defaultFriendName;

    final activeFocusPlan = ref.watch(postVisitFocusControllerProvider).value;
    final plan = ref.watch(appPersonalizationPlanProvider);
    final traceAsync = ref.watch(mindTraceControllerProvider);
    final traces = traceAsync.value ?? [];
    final todayTraces = traces.todayTraces;
    final todayTrace = todayTraces.isNotEmpty ? todayTraces.last : null;
    final distinctLoggedDays = {for (final t in traces) t.dateKey}.length;

    return AmbientScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mindTraceControllerProvider);
          },
          color: tokens.primary,
          backgroundColor: tokens.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clean Single Header Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mindora',
                            style: LabTheme.textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tokens.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_getLocalizedGreeting(strings)}${strings.isArabic ? '،' : ','} $userName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: LabTheme.textStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SupportButton(),
                  ],
                ),

                const SizedBox(height: 16),

                // 1. HERO: 2-Tap MoodFace Check-In Card (Single Job!)
                HomeDailyCheckInCard(
                  tokens: tokens,
                  strings: strings,
                  isDark: isDark,
                  todayTrace: todayTrace,
                  traces: traces,
                  todayTraces: todayTraces,
                  selectedMoodIndex: _selectedMoodIndex,
                  moodIntensity: _moodIntensity,
                  todayNoteController: _todayNoteController,
                  moodOptions: _moodOptions,
                  onMoodSelected: (idx) =>
                      setState(() => _selectedMoodIndex = idx),
                  onIntensityChanged: (val) =>
                      setState(() => _moodIntensity = val),
                  onSave: () => _saveQuickCheckIn(
                    _moodOptions[_selectedMoodIndex].key,
                    _moodIntensity.round(),
                  ),
                  onQuickSave: (moodKey, intensity, {createNew = false}) =>
                      _saveQuickCheckIn(
                        moodKey,
                        intensity,
                        createNew: createNew,
                      ),
                  onAddDetails: (trace) =>
                      ProgressiveDetailsSheet.show(context, trace: trace),
                  getMoodLabel: _getMoodLabel,
                  getMoodColor: _getMoodColor,
                  onBreatheTap: () => ContextualSupportSheet.show(
                    context,
                    initialChoice: SupportChoice.settle,
                  ),
                  onTalkAboutIt: (trace) =>
                      _openCompanionForTrace(trace, strings),
                ),

                const SizedBox(height: 14),

                // 2. Clinically High-Value Adaptive Daily Pulse (Morning Sleep/Energy or Evening Stress/Helpers)
                HomeClinicalPulseCard(
                  tokens: tokens,
                  strings: strings,
                  plan: plan,
                  todayTrace: todayTrace,
                  onUpdateTrace: _updateTodayClinicalPulse,
                ),

                if (plan.isDoctorFollowed) ...[
                  const SizedBox(height: 14),
                  MindCard(
                    key: const ValueKey('home-doctor-readiness-card'),
                    variant: MindCardVariant.tint,
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      PreVisitBriefSheet.show(context);
                    },
                    semanticLabel: strings.doctorVisitReadyTitle(
                      distinctLoggedDays,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tokens.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.medical_information_outlined,
                            size: 22,
                            color: tokens.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.doctorVisitReadyTitle(
                                  distinctLoggedDays,
                                ),
                                style: LabTheme.textStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.doctorVisitReadySub,
                                style: LabTheme.textStyle(
                                  fontSize: 13,
                                  color: tokens.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: tokens.ink2,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 3. Gentle 7-Day Colored MoodFace Strip
                HomeWeeklyRhythmCard(
                  traces: traces,
                  tokens: tokens,
                  strings: strings,
                  isDark: isDark,
                  getMoodColor: _getMoodColor,
                  getMoodLabel: _getMoodLabel,
                  onDayTap: (_, _) {
                    GoRouter.maybeOf(context)?.go(AppRouter.track);
                  },
                ),

                // 3. Optional Doctor's Plan (only shown when active)
                if (activeFocusPlan != null &&
                    !activeFocusPlan.isDismissed) ...[
                  const SizedBox(height: 14),
                  HomePostVisitFocusCard(
                    plan: activeFocusPlan,
                    onToggleItem: (itemId) => ref
                        .read(postVisitFocusControllerProvider.notifier)
                        .toggleGoalItem(itemId),
                    onDismiss: () => ref
                        .read(postVisitFocusControllerProvider.notifier)
                        .dismissPlan(),
                    onPrepareVisit: () => PreVisitBriefSheet.show(context),
                  ),
                ],

                const SizedBox(height: 14),

                // 4. One Calm Quick-Breather Card
                MindCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ContextualSupportSheet.show(
                      context,
                      initialChoice: SupportChoice.settle,
                    );
                  },
                  semanticLabel: strings.takeOneMinuteBreather,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const HomeOrganicExerciseArt(size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.takeOneMinuteBreather,
                              style: LabTheme.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              strings.breathingTitle,
                              style: LabTheme.textStyle(
                                fontSize: 13.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: tokens.ink2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
