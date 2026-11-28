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
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../../clinician/controllers/clinician_providers.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/emotion_descriptors.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../onboarding/domain/app_personalization_engine.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../support/presentation/contextual_support_sheet.dart';
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
    String? note,
    bool isPrivate = false,
  }) async {
    final trimmedNote = note?.trim();
    if (trimmedNote != null &&
        trimmedNote.isNotEmpty &&
        CrisisKeywords.evaluateText(trimmedNote) == 2) {
      if (mounted) SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

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
        journalText: (trimmedNote != null && trimmedNote.isNotEmpty)
            ? trimmedNote
            : todayTrace.journalText,
        isPrivate: isPrivate ? true : todayTrace.isPrivate,
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
        journalText: (trimmedNote != null && trimmedNote.isNotEmpty)
            ? trimmedNote
            : null,
        isPrivate: isPrivate,
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

  Widget _buildQuietSyncPill(
    MindTokens tokens,
    AppStrings strings,
    ClinicSyncStatus syncStatus,
  ) {
    final bool isSynced = syncStatus.phase == ClinicSyncPhase.synced ||
        (syncStatus.phase == ClinicSyncPhase.idle &&
            syncStatus.lastSyncedAt != null);
    final bool isSyncing = syncStatus.phase == ClinicSyncPhase.syncing;
    final bool isPaused = syncStatus.phase == ClinicSyncPhase.pausedOrError;

    final IconData icon = isPaused
        ? Icons.pause_circle_outline_rounded
        : isSyncing
        ? Icons.sync_rounded
        : isSynced
        ? Icons.cloud_done_outlined
        : Icons.check_circle_outline_rounded;
    final Color iconColor = isPaused
        ? tokens.safety
        : isSynced
        ? tokens.m1
        : tokens.ink2;
    final String label = isPaused
        ? strings.syncPausedQuietLabel
        : isSyncing
        ? strings.syncingQuietLabel
        : isSynced
        ? strings.syncedQuietLabel
        : strings.savedOnPhoneLabel;

    final pill = Container(
      key: const ValueKey('home-quiet-sync-pill'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaused ? tokens.safetySoft : tokens.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaused ? tokens.safety.withValues(alpha: 0.4) : tokens.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LabTheme.textStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: isPaused ? tokens.safety : tokens.ink2,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isPaused) return pill;
    return MindPressable(
      semanticLabel: label,
      borderRadius: BorderRadius.circular(12),
      onPressed: () {
        HapticFeedback.selectionClick();
        showMindToast(context, strings.syncPausedHelpToast);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(widthFactor: 1.0, child: pill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final preferredName = ref.watch(
      profileControllerProvider.select((p) => p.value?.preferredName),
    );
    final rawName = (preferredName ?? '').trim();
    final greetingText = rawName.isNotEmpty
        ? '${_getLocalizedGreeting(strings)}${strings.isArabic ? '،' : ','} $rawName'
        : _getLocalizedGreeting(strings);

    final activeFocusPlan = ref.watch(postVisitFocusControllerProvider).value;
    final profile = ref.watch(profileControllerProvider).value;
    final authUser = ref.watch(authControllerProvider).user;
    final syncStatus = ref.watch(clinicSyncStatusProvider);
    final plan = ref.watch(appPersonalizationPlanProvider);
    final traceAsync = ref.watch(mindTraceControllerProvider);
    final traces = traceAsync.value ?? [];
    final todayTraces = traces.todayTraces;
    final todayTrace = todayTraces.isNotEmpty ? todayTraces.last : null;
    final weekCutoff = DateTime.now().subtract(const Duration(days: 6));
    final weekDaysLogged = {
      for (final t in traces)
        if (!t.date.isBefore(
          DateTime(weekCutoff.year, weekCutoff.month, weekCutoff.day),
        ))
          t.dateKey,
    }.length;

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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mindora',
                                style: LabTheme.textStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.primary,
                                ),
                              ),
                              if (authUser?.isClinicAccount == true) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _buildQuietSyncPill(
                                    tokens,
                                    strings,
                                    syncStatus,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            greetingText,
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
                  isClinicAccount: authUser?.isClinicAccount == true,
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
                  onQuickSave: (
                    moodKey,
                    intensity, {
                    createNew = false,
                    note,
                    isPrivate = false,
                  }) => _saveQuickCheckIn(
                    moodKey,
                    intensity,
                    createNew: createNew,
                    note: note,
                    isPrivate: isPrivate,
                  ),
                  getMoodLabel: _getMoodLabel,
                  getMoodColor: _getMoodColor,
                  onBreatheTap: () => ContextualSupportSheet.show(
                    context,
                    initialChoice: SupportChoice.settle,
                  ),
                  onTalkAboutIt: (trace) =>
                      _openCompanionForTrace(trace, strings),
                ),

                // 2. Active Doctor's Focus Plan (elevated directly beneath Check-In when active)
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
                  ),
                ],

                const SizedBox(height: 14),

                // 3. Playful, condition-aware Daily Ritual (collapsed softly before mood check-in)
                HomeClinicalPulseCard(
                  tokens: tokens,
                  strings: strings,
                  plan: plan,
                  profile: profile,
                  loggedDaysThisWeek: weekDaysLogged,
                  todayTrace: todayTrace,
                  initiallyCollapsed: todayTrace == null,
                  onUpdateTrace: _updateTodayClinicalPulse,
                ),

                const SizedBox(height: 14),

                // 4. Gentle 7-Day Colored MoodFace Strip (taps jump directly to that day in My days)
                HomeWeeklyRhythmCard(
                  traces: traces,
                  tokens: tokens,
                  strings: strings,
                  isDark: isDark,
                  getMoodColor: _getMoodColor,
                  getMoodLabel: _getMoodLabel,
                  onDayTap: (day, _) {
                    final dateKey =
                        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    GoRouter.maybeOf(
                      context,
                    )?.go('${AppRouter.track}?date=$dateKey');
                  },
                ),

                const SizedBox(height: 14),

                // 4. Calm Support Card (opens direct breathing before check-in; full calming toolkit after)
                MindCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ContextualSupportSheet.show(
                      context,
                      initialChoice: todayTrace == null
                          ? SupportChoice.settle
                          : null,
                    );
                  },
                  semanticLabel: todayTrace == null
                      ? strings.takeOneMinuteBreather
                      : strings.contextualSupportTitle,
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
                              todayTrace == null
                                  ? strings.takeOneMinuteBreather
                                  : strings.contextualSupportTitle,
                              style: LabTheme.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              todayTrace == null
                                  ? strings.breathingTitle
                                  : strings.homeSupportCardSub,
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
                const SizedBox(height: 16),
                const Center(child: EmergencyHelpLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
