import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/icon_blob.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/case_stage.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/emotion_descriptors.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import 'widgets/home_active_case_card.dart';
import 'widgets/home_daily_check_in_card.dart';
import 'widgets/home_organic_exercise_art.dart';
import 'widgets/home_weekly_rhythm_card.dart';

/// The calm, uncluttered Home screen for v1.0:
/// Greeting, Daily Check-In, Active/Recent Investigations, and a single Breathing Reset shortcut.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedMoodIndex = 0;
  double _moodIntensity = 5.0;
  List<CaseModel> _recentCases = [];
  bool _isLoading = true;
  String? _hydratedTraceSignature;
  final TextEditingController _todayNoteController = TextEditingController();

  final List<({String key, IconData icon})> _moodOptions = const [
    (key: 'calm', icon: Icons.spa_outlined),
    (key: 'anxious', icon: Icons.bolt_outlined),
    (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    (key: 'heavy', icon: Icons.grain_outlined),
    (key: 'restless', icon: Icons.air_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRecentCases();
      final today = ref.read(todayTraceProvider);
      _syncFromTraceIfNeeded(today);
    });
  }

  String _traceSignature(MindTraceModel trace) =>
      '${trace.id}_${trace.updatedAt.millisecondsSinceEpoch}';

  void _syncFromTraceIfNeeded(MindTraceModel? trace) {
    if (trace == null) {
      if (_hydratedTraceSignature == null) return;
      setState(() {
        _hydratedTraceSignature = null;
        _selectedMoodIndex = 0;
        _moodIntensity = 5.0;
        _todayNoteController.clear();
      });
      return;
    }

    final sig = _traceSignature(trace);
    if (_hydratedTraceSignature == sig) return;
    setState(() {
      _hydratedTraceSignature = sig;
      final canonicalMood = EmotionDescriptor.canonicalKey(
        trace.overallMood,
      ).toLowerCase();
      final moodIdx = _moodOptions.indexWhere((m) => m.key == canonicalMood);
      if (moodIdx != -1) _selectedMoodIndex = moodIdx;
      _moodIntensity = trace.moodIntensity.toDouble().clamp(1, 10);
      final note = trace.journalText ?? '';
      if (_todayNoteController.text != note) {
        _todayNoteController.text = note;
      }
    });
  }

  @override
  void dispose() {
    _todayNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCases() async {
    final repo = ref.read(caseRepositoryProvider);
    final all = await repo.getAllCases();

    if (mounted) {
      setState(() {
        _recentCases = all.take(2).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDailyCheckIn() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final activeMood = _moodOptions[_selectedMoodIndex].key;
    final intensity = _moodIntensity.toInt();
    final todayTrace = ref.read(todayTraceProvider);
    final strings = ref.read(appStringsProvider);
    final noteText = _todayNoteController.text.trim().isNotEmpty
        ? _todayNoteController.text.trim()
        : null;

    // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
    final safetyLevel = noteText != null
        ? CrisisKeywords.evaluateText(noteText)
        : 0;
    if (safetyLevel == 2) {
      SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

    late final MindTraceModel savedTrace;
    if (todayTrace != null) {
      // 1. Update existing trace for today without erasing multi-emotion arrays
      final existingEmotions = todayTrace.selectedEmotions;
      final mergedEmotions = existingEmotions.isEmpty
          ? [activeMood]
          : <String>[
              activeMood,
              ...existingEmotions.where(
                (e) =>
                    EmotionDescriptor.canonicalKey(e).toLowerCase() !=
                    activeMood,
              ),
            ];
      savedTrace = todayTrace.copyWith(
        overallMood: activeMood,
        moodIntensity: intensity,
        selectedEmotions: mergedEmotions,
        journalText: noteText,
        clearJournalText: noteText == null,
        updatedAt: now,
      );
      _hydratedTraceSignature = _traceSignature(savedTrace);
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(savedTrace);
    } else {
      // 2. Create new options-first trace for today (unrecorded sliders stay null)
      savedTrace = MindTraceModel(
        id: 'trace_${now.millisecondsSinceEpoch}',
        userId: ref.read(authControllerProvider).user?.id ?? 'local_user',
        date: now,
        overallMood: activeMood,
        moodIntensity: intensity,
        energyLevel: null,
        selectedEmotions: [activeMood],
        journalText: noteText,
        createdAt: now,
        updatedAt: now,
      );
      _hydratedTraceSignature = _traceSignature(savedTrace);
      await ref
          .read(mindTraceControllerProvider.notifier)
          .recordCheckIn(savedTrace, generateAi: false);
    }

    // 3. Keep cache synchronized with authenticated encryption at rest
    final prefs = await SharedPreferences.getInstance();
    final keyManager = ref.read(secureKeyManagerProvider);
    final authState = ref.read(authControllerProvider);
    final cipher = await keyManager.getCipherForUser(authState.user?.id);
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: 'mf_last_checkin_cache_v1',
      plaintext: jsonEncode({
        'mood': activeMood,
        'intensity': intensity,
        'timestamp': now.toIso8601String(),
      }),
      cipher: cipher,
    );
    await prefs.remove('mf_last_checkin_mood');
    await prefs.remove('mf_last_checkin_intensity');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.tokens.ink,
          content: Text(
            safetyLevel == 1
                ? '${strings.checkInSavedSnackbar} ${strings.needSupportBtn}'
                : strings.checkInSavedSnackbar,
            style: TextStyle(
              color: context.tokens.bg,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          action: safetyLevel == 1
              ? SnackBarAction(
                  label: strings.supportTitle,
                  textColor: context.tokens.bg,
                  onPressed: () {
                    if (mounted) SupportModalSheet.show(context);
                  },
                )
              : null,
          duration: Duration(seconds: safetyLevel == 1 ? 4 : 2),
        ),
      );
    }
  }

  String _getLocalizedGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.greetingMorning;
    if (hour < 18) return strings.greetingAfternoon;
    return strings.greetingEvening;
  }

  String _getMoodLabel(String key, AppStrings strings) {
    switch (EmotionDescriptor.canonicalKey(key).toLowerCase()) {
      case 'calm':
        return strings.moodCalm;
      case 'anxious':
        return strings.moodAnxious;
      case 'frustrated':
        return strings.moodFrustrated;
      case 'heavy':
        return strings.moodHeavy;
      case 'restless':
        return strings.moodRestless;
      default:
        return EmotionDescriptor.localizedLabel(key, strings);
    }
  }

  Color _getMoodColor(String key) {
    return MindTokens.moodColor(AppMood.fromKey(key));
  }

  ConversationMode _recommendedModeForTrace(MindTraceModel trace) {
    final moodKey = EmotionDescriptor.canonicalKey(
      trace.overallMood,
    ).toLowerCase();
    if (trace.moodIntensity >= 8) {
      return ConversationMode.grounding;
    }
    switch (moodKey) {
      case 'frustrated':
      case 'heavy':
        return ConversationMode.understandEmotion;
      case 'anxious':
      case 'restless':
        return ConversationMode.exploreThought;
      case 'calm':
      default:
        return ConversationMode.guidedReflection;
    }
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
      if (mounted) {
        SafetyInterceptor.showCrisisPauseDialog(context);
      }
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
      context.go(AppRouter.companion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = ref.watch(profileControllerProvider).value;
    final userName = profile?.preferredName.isNotEmpty == true
        ? profile!.preferredName
        : (strings.isArabic ? 'صديقي' : (strings.isFrench ? 'Ami' : 'Friend'));

    final activeCase = ref.watch(activeCaseControllerProvider).value;
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];
    final todayTrace = traces.todayTrace;
    final headerMoodKey =
        todayTrace?.overallMood ??
        _moodOptions[_selectedMoodIndex.clamp(0, _moodOptions.length - 1)].key;
    final headerAvatarColor = _getMoodColor(headerMoodKey);
    final headerAvatarFg = tokens.onMood;
    final todayDateOverline = strings.formattedDateOverline(DateTime.now());

    final nextSig = todayTrace != null ? _traceSignature(todayTrace) : null;
    if (nextSig != _hydratedTraceSignature) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncFromTraceIfNeeded(todayTrace);
      });
    }

    return AmbientScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadRecentCases();
            ref.invalidate(mindTraceControllerProvider);
          },
          color: tokens.m1,
          backgroundColor: tokens.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Header Row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.selectedTintFor(tokens.m1),
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(color: tokens.line),
                      ),
                      alignment: Alignment.center,
                      child: FingerprintThreadSignature(
                        size: 18,
                        animated: false,
                        primaryColor: tokens.m1,
                        accentColor: tokens.ink2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mind Forensics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SupportButton(compact: true),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. TOP GREETING ROW (Crisp single greeting + Calendar & Avatar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayDateOverline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: strings.isArabic ? 0 : 0.8,
                              color: tokens.ink3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.dearUserGreeting(userName),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: tokens.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getLocalizedGreeting(strings),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MindPressable(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.go('${AppRouter.track}?tab=1');
                          },
                          semanticLabel: strings.quickCalendarTitle,
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.surface,
                                  border: Border.all(
                                    color: tokens.line,
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                  color: tokens.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        MindPressable(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.go(AppRouter.profile);
                          },
                          semanticLabel: strings.navProfile,
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: headerAvatarColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: headerAvatarColor.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child:
                                    (profile?.preferredName.isNotEmpty ==
                                            true &&
                                        profile!.preferredName != 'Friend')
                                    ? Text(
                                        profile.preferredName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: headerAvatarFg,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_outline_rounded,
                                        size: 19,
                                        color: headerAvatarFg,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 2. DAILY CHECK-IN SANCTUARY + WEEKLY CONTINUITY STRIP
                _buildDailyCheckInCard(
                  tokens,
                  strings,
                  isDark,
                  todayTrace,
                  traces,
                ),
                const SizedBox(height: 14),
                HomeWeeklyRhythmCard(
                  traces: traces,
                  tokens: tokens,
                  strings: strings,
                  isDark: isDark,
                  getMoodColor: _getMoodColor,
                  getMoodLabel: _getMoodLabel,
                  onDayTap: (day, trace) {
                    if (trace != null) {
                      context.go('${AppRouter.track}?tab=1');
                    } else {
                      context.go(AppRouter.track);
                    }
                  },
                ),

                const SizedBox(height: 20),

                // 3. ACTIVE CASE OR START INVESTIGATION CARD
                if (activeCase != null && !activeCase.isCompleted)
                  _buildActiveCaseCard(activeCase, tokens, strings, isDark)
                else
                  _buildStartInvestigationCard(tokens, strings, isDark),

                const SizedBox(height: 20),

                // 4. GROUNDING & EXERCISES CARD (Single Clean Breathing Entry)
                _buildExercisesForYouCard(tokens, strings, isDark),

                const SizedBox(height: 22),

                // 5. RECENT INVESTIGATIONS SECTION (Up to 2 items)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.recentCasesSection,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tokens.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ref.read(companionHubSignalProvider.notifier).trigger();
                        context.go('${AppRouter.companion}?view=hub');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          strings.viewAll.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_recentCases.isEmpty)
                  _buildNoCasesCard(tokens, strings)
                else
                  ..._recentCases.map(
                    (c) => _buildRecentCaseTile(c, tokens, strings, isDark),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  Widget _buildExercisesForYouCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.exercisesForYou,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 12),
        MindCard(
          onTap: () {
            HapticFeedback.mediumImpact();
            ContextualSupportSheet.show(
              context,
              initialChoice: SupportChoice.settle,
            );
          },
          semanticLabel: strings.relieveStress,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Calming Organic Vector Art (ZERO emojis)
              const HomeOrganicExerciseArt(size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.relieveStress,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.breathingPractice,
                      style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty_rounded,
                          size: 13,
                          color: tokens.ink2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.duration5Min,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: tokens.ink2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCheckInCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
    MindTraceModel? todayTrace,
    List<MindTraceModel> traces,
  ) {
    return HomeDailyCheckInCard(
      tokens: tokens,
      strings: strings,
      isDark: isDark,
      todayTrace: todayTrace,
      traces: traces,
      selectedMoodIndex: _selectedMoodIndex,
      moodIntensity: _moodIntensity,
      todayNoteController: _todayNoteController,
      moodOptions: _moodOptions,
      onMoodSelected: (idx) => setState(() => _selectedMoodIndex = idx),
      onIntensityChanged: (val) => setState(() => _moodIntensity = val),
      onSave: _saveDailyCheckIn,
      getMoodLabel: _getMoodLabel,
      getMoodColor: _getMoodColor,
      onBreatheTap: () => ContextualSupportSheet.show(
        context,
        initialChoice: SupportChoice.settle,
      ),
      onTalkAboutIt: (trace) => _openCompanionForTrace(trace, strings),
    );
  }

  Widget _buildActiveCaseCard(
    CaseModel c,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return HomeActiveCaseCard(
      caseModel: c,
      tokens: tokens,
      strings: strings,
      isDark: isDark,
      onResume: () {
        context.go(AppRouter.companion);
      },
    );
  }

  Widget _buildStartInvestigationCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBlob(icon: Icons.bolt_rounded, color: tokens.m1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.startInvestigation,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.startInvestigationSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.ink2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MindButton(
            text: strings.newInvestigation,
            leadingIcon: Icons.add_rounded,
            variant: MindButtonVariant.primary,
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go(AppRouter.companion);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickCatalystPill(
                label: strings.catalystUnanswered,
                icon: Icons.mark_email_unread_outlined,
                tokens: tokens,
              ),
              _buildQuickCatalystPill(
                label: strings.catalystCritique,
                icon: Icons.chat_bubble_outline_rounded,
                tokens: tokens,
              ),
              _buildQuickCatalystPill(
                label: strings.catalystOverload,
                icon: Icons.timer_outlined,
                tokens: tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCatalystPill({
    required String label,
    required IconData icon,
    required MindTokens tokens,
  }) {
    return MindPressable(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        await ref
            .read(activeCaseControllerProvider.notifier)
            .startNewCase(label);
        await ref
            .read(activeCaseControllerProvider.notifier)
            .advanceStage(CaseStage.evidence);
        if (mounted) {
          context.go(AppRouter.companion);
        }
      },
      semanticLabel: label,
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            border: Border.all(color: tokens.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tokens.ink2),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoCasesCard(MindTokens tokens, AppStrings strings) {
    return MindCard(
      variant: MindCardVariant.flat,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          strings.noCasesOnFile,
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
            color: tokens.ink3,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCaseTile(
    CaseModel c,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: MindCard(
        onTap: () async {
          HapticFeedback.lightImpact();
          if (c.isCompleted) {
            await context.push('/case/${c.id}');
          } else {
            ref.read(activeCaseControllerProvider.notifier).resumeCase(c);
            context.go(AppRouter.companion);
          }
          _loadRecentCases();
        },
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconBlob(
              icon: c.isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.pending_outlined,
              color: c.isCompleted ? tokens.m1 : tokens.ink3,
              size: 36,
              iconSize: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.formatSessionNumber(c.caseNumber)}  •  ${strings.stageNumberLabel(c.currentStage.stepNumber)}',
                    style: TextStyle(fontSize: 11, color: tokens.ink2),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tokens.ink2),
          ],
        ),
      ),
    );
  }
}
