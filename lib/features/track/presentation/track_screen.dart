import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mood_emblem.dart';
import '../../../core/widgets/organic_mood_orb.dart';
import '../../../core/widgets/quick_note_sparks_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/presentation/widgets/home_organic_exercise_art.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/check_in_micro_mirror.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/emotion_descriptors.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/daily_mind_trace_stepper.dart';
import '../../mind_trace/presentation/widgets/trace_investigation_sheet.dart';
import 'widgets/track_entry_detail_sheet.dart';
import 'widgets/track_month_calendar.dart';
import 'widgets/track_mood_picker.dart';
import 'widgets/track_mood_utils.dart';

/// Consolidated daily tracking workspace combining fast check-ins with an
/// interactive calendar & chronological history.
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({
    super.key,
    this.initialTab = 0,
    this.startNewMoment = false,
  });

  final int initialTab;
  final bool startNewMoment;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _triggerOptions = [
    'Work / Demands',
    'Sleep Disruption',
    'Studies',
    'Social',
    'Health',
    'Overload',
  ];

  static const List<String> _helpedOptions = [
    'Walk',
    'Quiet time',
    'Breathing',
    'Talked',
    'Rest',
  ];

  late TabController _tabController;
  late TextEditingController _noteController;

  // Tab 0: Check-In Today form state
  late int _activeTab;
  String _selectedMood = 'calm';
  double _moodIntensity = 5.0;
  double _energyLevel = 5.0;
  double _anxietyLevel = 3.0;
  double _sleepHours = 7.5;
  final Set<String> _selectedNuancedEmotions = {};
  bool _showAllNuancedEmotions = false;
  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedHelped = {};
  final Set<String> _selectedContextTags = {};
  bool _isComposingNewMoment = false;
  String? _editingTraceId;
  bool _isSaving = false;
  bool _savedConfirmed = false;
  int _saveBloomCount = 0;
  String? _hydratedTraceSignature;
  bool _hasHydratedInitial = false;
  bool _allowOrbMorph = false;
  bool _showOptionalContext = false;
  String _lastSavedNote = '';

  // Tab 1: History & Calendar state
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _isComposingNewMoment = widget.startNewMoment;
    _noteController = TextEditingController();
    _noteController.addListener(_onNoteChanged);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeTab,
    );
    _tabController.addListener(_handleTabControllerTick);
    if (_isComposingNewMoment) {
      _hasHydratedInitial = true;
    } else {
      final traceAsync = ref.read(mindTraceControllerProvider);
      if (traceAsync.hasValue) {
        _applyTraceFieldsSync(traceAsync.value?.todayTrace);
        _hasHydratedInitial = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant TrackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitial = widget.initialTab.clamp(0, 1);
    if (oldWidget.initialTab != widget.initialTab &&
        nextInitial != _tabController.index) {
      _tabController.animateTo(nextInitial);
    }
    if (widget.startNewMoment && !oldWidget.startNewMoment) {
      _enterNewMomentMode();
    }
  }

  void _handleTabControllerTick() {
    if (!mounted) return;
    if (_tabController.index != _activeTab) {
      setState(() => _activeTab = _tabController.index);
    }
  }

  void _onNoteChanged() {
    if (_savedConfirmed &&
        _noteController.text.trim() != _lastSavedNote &&
        mounted) {
      setState(() => _savedConfirmed = false);
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _tabController.removeListener(_handleTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  String _traceSignature(MindTraceModel trace) =>
      '${trace.id}_${trace.updatedAt.millisecondsSinceEpoch}';

  void _applyTraceFieldsSync(MindTraceModel? trace) {
    if (trace == null) {
      _hydratedTraceSignature = null;
      _editingTraceId = null;
      _lastSavedNote = '';
      _selectedMood = 'calm';
      _moodIntensity = 5.0;
      _energyLevel = 5.0;
      _anxietyLevel = 3.0;
      _sleepHours = 7.5;
      _noteController.clear();
      _selectedNuancedEmotions.clear();
      _selectedTriggers.clear();
      _selectedHelped.clear();
      _selectedContextTags.clear();
      _savedConfirmed = false;
      return;
    }

    _hydratedTraceSignature = _traceSignature(trace);
    _editingTraceId = trace.id;
    final hydratedNote = trace.journalText ?? '';
    _lastSavedNote = hydratedNote.trim();
    _selectedMood = EmotionDescriptor.canonicalKey(
      trace.overallMood,
    ).toLowerCase();
    _moodIntensity = trace.moodIntensity.toDouble().clamp(1, 10);
    _energyLevel = (trace.energyLevel ?? 5).toDouble().clamp(1, 10);
    _anxietyLevel = (trace.anxietyLevel ?? 3).toDouble().clamp(0, 10);
    _sleepHours = (trace.sleepHours ?? 7.5).clamp(2, 14);
    if (_noteController.text != hydratedNote) {
      _noteController.text = hydratedNote;
    }

    _selectedNuancedEmotions
      ..clear()
      ..addAll(trace.nuancedEmotions);

    _selectedTriggers.clear();
    if (trace.situation != null && trace.situation!.trim().isNotEmpty) {
      _selectedTriggers.addAll(
        trace.situation!
            .split(',')
            .map((s) => s.trim())
            .where((p) => p.isNotEmpty),
      );
    }

    _selectedHelped.clear();
    if (trace.behavioralResponse != null &&
        trace.behavioralResponse!.trim().isNotEmpty) {
      _selectedHelped.addAll(
        trace.behavioralResponse!
            .split(',')
            .map((s) => s.trim())
            .where((p) => p.isNotEmpty),
      );
    }

    _selectedContextTags
      ..clear()
      ..addAll(trace.contextTags);
  }

  void _hydrateFromTrace(
    MindTraceModel? trace, {
    bool force = false,
    bool snapOrb = false,
  }) {
    if (trace == null) {
      if (_hydratedTraceSignature == null && !force) return;
      setState(() {
        if (snapOrb) _allowOrbMorph = false;
        _isComposingNewMoment = false;
        _applyTraceFieldsSync(null);
      });
      return;
    }

    final sig = _traceSignature(trace);
    if (!force && _hydratedTraceSignature == sig) return;
    setState(() {
      if (snapOrb) _allowOrbMorph = false;
      _isComposingNewMoment = false;
      _applyTraceFieldsSync(trace);
    });
  }

  void _enterNewMomentMode() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    setState(() {
      _isComposingNewMoment = true;
      _editingTraceId = null;
      _allowOrbMorph = true;
      _selectedMood = 'calm';
      _moodIntensity = 5.0;
      _energyLevel = 5.0;
      _anxietyLevel = 3.0;
      _sleepHours = 7.5;
      _noteController.clear();
      _lastSavedNote = '';
      _selectedNuancedEmotions.clear();
      _selectedTriggers.clear();
      _selectedHelped.clear();
      _selectedContextTags.clear();
      _savedConfirmed = false;
      if (_tabController.index != 0) {
        _tabController.animateTo(0);
      }
    });
  }

  void _selectExistingMomentForEdit(MindTraceModel moment) {
    HapticFeedback.selectionClick();
    setState(() {
      _isComposingNewMoment = false;
      _allowOrbMorph = true;
      _savedConfirmed = false;
      _applyTraceFieldsSync(moment);
    });
  }

  Future<void> _promptCustomFeelingSheet(
    MindTokens tokens,
    AppStrings strings,
  ) async {
    final controller = TextEditingController();
    final customLabel = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sTokens = sheetCtx.tokens;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: sTokens.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(sTokens.sheetRadius),
              ),
              border: Border(top: BorderSide(color: sTokens.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sTokens.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.customFeelingSheetTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: sTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (val) => Navigator.of(sheetCtx).pop(val.trim()),
                    decoration: InputDecoration(
                      hintText: strings.customFeelingHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  MindButton(
                    text: strings.confirmAction,
                    isFullWidth: true,
                    onPressed: () =>
                        Navigator.of(sheetCtx).pop(controller.text.trim()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (!mounted || customLabel == null || customLabel.isEmpty) return;

    final safetyLevel = CrisisKeywords.evaluateText(customLabel);
    if (safetyLevel == 2) {
      SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

    setState(() {
      _selectedNuancedEmotions.add(customLabel);
      _savedConfirmed = false;
    });
  }

  Future<void> _saveQuickCheckIn() async {
    final strings = ref.read(appStringsProvider);
    final tokens = context.tokens;

    if (_selectedMood.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          content: Text(
            strings.pickHowYouFeelFirst,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final todayList = ref.read(todayTracesProvider);
      final MindTraceModel? editingTarget;
      if (_isComposingNewMoment) {
        editingTarget = null;
      } else if (_editingTraceId != null) {
        editingTarget =
            todayList.where((t) => t.id == _editingTraceId).firstOrNull ??
            ref.read(todayTraceProvider);
      } else {
        editingTarget = ref.read(todayTraceProvider);
      }
      final authUser = ref.read(authControllerProvider).user;
      final userId = authUser?.id ?? 'local_user';

      final situationStr = _selectedTriggers.isNotEmpty
          ? _selectedTriggers.join(', ')
          : null;
      final helpedStr = _selectedHelped.isNotEmpty
          ? _selectedHelped.join(', ')
          : null;
      final noteText = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null;

      // Preserve Level 2 crisis pre-scan safeguard before saving any text.
      var safetyLevel = noteText != null
          ? CrisisKeywords.evaluateText(noteText)
          : 0;
      for (final emotionText in _selectedNuancedEmotions) {
        final eLevel = CrisisKeywords.evaluateText(emotionText);
        if (eLevel > safetyLevel) safetyLevel = eLevel;
      }
      if (safetyLevel == 2) {
        setState(() => _isSaving = false);
        if (mounted) {
          SafetyInterceptor.showCrisisPauseDialog(context);
        }
        return;
      }

      final combinedEmotions = <String>[_selectedMood];
      final seenEmotions = <String>{_selectedMood.toLowerCase()};
      for (final e in _selectedNuancedEmotions) {
        final clean = e.trim();
        if (clean.isNotEmpty && seenEmotions.add(clean.toLowerCase())) {
          combinedEmotions.add(clean);
        }
      }

      final trace = editingTarget != null
          ? editingTarget.copyWith(
              overallMood: _selectedMood,
              selectedEmotions: combinedEmotions,
              moodIntensity: _moodIntensity.round(),
              energyLevel: _energyLevel.round(),
              anxietyLevel: _anxietyLevel.round(),
              sleepHours: _sleepHours,
              situation: situationStr,
              clearSituation: situationStr == null,
              behavioralResponse: helpedStr,
              clearBehavioralResponse: helpedStr == null,
              journalText: noteText,
              clearJournalText: noteText == null,
              contextTags: _selectedContextTags.toList(growable: false),
              updatedAt: now,
            )
          : MindTraceModel(
              id: 'trace_${now.millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 6)}',
              userId: userId,
              date: now,
              overallMood: _selectedMood,
              selectedEmotions: combinedEmotions,
              moodIntensity: _moodIntensity.round(),
              energyLevel: _energyLevel.round(),
              anxietyLevel: _anxietyLevel.round(),
              sleepHours: _sleepHours,
              situation: situationStr,
              behavioralResponse: helpedStr,
              journalText: noteText,
              contextTags: _selectedContextTags.toList(growable: false),
              createdAt: now,
              updatedAt: now,
            );

      _isComposingNewMoment = false;
      _editingTraceId = trace.id;
      _hydratedTraceSignature = _traceSignature(trace);
      _lastSavedNote = noteText ?? '';
      await ref
          .read(mindTraceControllerProvider.notifier)
          .recordCheckIn(trace, generateAi: false);
      ref.read(activeMoodProvider.notifier).setMoodByKey(trace.overallMood);

      if (mounted) {
        setState(() {
          _savedConfirmed = true;
          _saveBloomCount++;
          _selectedDateKey = trace.dateKey;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: tokens.surface2,
            content: Text(
              safetyLevel == 1
                  ? '${strings.checkInSavedSnackbar} ${strings.needSupportBtn}'
                  : strings.checkInSavedSnackbar,
              style: TextStyle(color: tokens.ink, fontSize: 13),
            ),
            action: safetyLevel == 1
                ? SnackBarAction(
                    label: strings.supportTitle,
                    onPressed: () {
                      if (mounted) SupportModalSheet.show(context);
                    },
                  )
                : SnackBarAction(
                    label: strings.isArabic
                        ? 'عرض السجل'
                        : (strings.isFrench
                              ? 'Voir calendrier'
                              : 'View Calendar'),
                    textColor: tokens.m1,
                    onPressed: () {
                      if (mounted) _tabController.animateTo(1);
                    },
                  ),
            duration: Duration(seconds: safetyLevel == 1 ? 4 : 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openGuidedCheckInSheet(MindTraceModel? todayTrace) {
    final tokens = context.tokens;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.cardRadius),
              ),
              border: Border.all(color: tokens.line),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: DailyMindTraceStepper(
                    initialTrace: todayTrace,
                    onViewConstellation: () {
                      Navigator.of(sheetCtx).pop();
                      if (mounted) _tabController.animateTo(1);
                    },
                    onReturnHome: () {
                      Navigator.of(sheetCtx).pop();
                      if (mounted) {
                        GoRouter.maybeOf(context)?.go(AppRouter.home);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleInspectTrace(MindTraceModel trace, AppStrings strings) {
    final today = ref.read(todayTraceProvider);
    final isTodayTrace =
        today != null &&
        (trace.id == today.id || trace.dateKey == today.dateKey);

    TrackEntryDetailSheet.show(
      context,
      trace: trace,
      onEdit: () {
        if (isTodayTrace) {
          _selectExistingMomentForEdit(trace);
          _tabController.animateTo(0);
        } else {
          EditPastTraceSheet.show(context, trace);
        }
      },
      onExploreWithAi: () async {
        final moodText = trackMoodLabel(trace.overallMood, strings);
        final note = trace.journalText?.trim() ?? '';
        final notePart = note.isNotEmpty ? ' — "$note"' : '';
        final handoffPrompt =
            '${strings.exploreMoodContextPrefix} $moodText (${trace.moodIntensity}/10)$notePart';

        final controller = ref.read(activeCaseControllerProvider.notifier);
        await controller.startNewCase(
          handoffPrompt,
          mode: ConversationMode.understandEmotion,
        );
        unawaited(controller.requestAiReply());
        if (!mounted) return;
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go(AppRouter.companion);
        } else {
          TraceInvestigationSheet.show(context, trace);
        }
      },
      onDeleted: () {
        if (_selectedDateKey == trace.dateKey && mounted) {
          setState(() => _selectedDateKey = null);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final traceAsync = ref.watch(mindTraceControllerProvider);
    final todayTraces = ref.watch(todayTracesProvider);
    final todayTrace = todayTraces.isNotEmpty ? todayTraces.last : null;

    if (!_hasHydratedInitial && traceAsync.hasValue) {
      if (!_isComposingNewMoment) {
        _applyTraceFieldsSync(todayTrace);
      }
      _hasHydratedInitial = true;
    }

    ref.listen<int>(trackNewMomentSignalProvider, (prev, next) {
      if (prev != next && mounted) {
        _enterNewMomentMode();
      }
    });

    ref.listen<MindTraceModel?>(todayTraceProvider, (_, next) {
      if (_isComposingNewMoment) {
        if (next == null && ref.read(todayTracesProvider).isEmpty && mounted) {
          _hydrateFromTrace(null, snapOrb: true);
        }
        return;
      }
      final nextSig = next != null ? _traceSignature(next) : null;
      if (nextSig != _hydratedTraceSignature) {
        final shouldSnap = !_hasHydratedInitial;
        _hasHydratedInitial = true;
        _hydrateFromTrace(next, snapOrb: shouldSnap);
      }
    });

    return AmbientScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeaderAndSegmented(tokens, strings),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  (!_hasHydratedInitial && traceAsync.isLoading)
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _buildCheckInTodayTab(
                          tokens,
                          strings,
                          todayTrace,
                          todayTraces,
                          traceAsync.value ?? const [],
                        ),
                  _buildHistoryAndCalendarTab(tokens, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderAndSegmented(MindTokens tokens, AppStrings strings) {
    final canPop = Navigator.of(context).canPop();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (canPop) ...[
                IconButton(
                  tooltip: strings.backBtn,
                  icon: Icon(
                    isRtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    color: tokens.ink,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  strings.trackPageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: tokens.ink,
                ),
                tooltip: strings.fullCalendarTooltip,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_tabController.index == 0) {
                    _tabController.animateTo(1);
                  } else {
                    _tabController.animateTo(0);
                  }
                },
              ),
              const SupportButton(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          MindSegmented(
            index: _activeTab,
            labels: [strings.checkInTodayTab, strings.historyAndCalendarTab],
            onChanged: (idx) {
              HapticFeedback.selectionClick();
              _tabController.animateTo(idx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInTodayTab(
    MindTokens tokens,
    AppStrings strings,
    MindTraceModel? todayTrace,
    List<MindTraceModel> todayTraces,
    List<MindTraceModel> allTraces,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final activeMoodColor = MindTokens.moodColor(
      AppMood.fromKey(_selectedMood),
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.howFeelingRightNow,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                    letterSpacing: strings.isArabic ? 0 : -0.3,
                  ),
                ),
                if (todayTraces.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildTodaysMomentsStrip(tokens, strings, todayTraces),
                ],
                const SizedBox(height: 10),
                Center(
                  child: OrganicMoodOrb(
                    moodKey: _selectedMood,
                    intensity: _moodIntensity.round(),
                    color: activeMoodColor,
                    size: 84,
                    celebrationRevision: _saveBloomCount,
                    animateChanges: _allowOrbMorph,
                    semanticLabel: trackMoodLabel(_selectedMood, strings),
                    onTap: () {
                      final len = trackCoreMoods.length;
                      final idx = trackCoreMoods.indexWhere(
                        (m) => m.key == _selectedMood,
                      );
                      final nextIdx = ((idx == -1 ? 0 : idx) + 1) % len;
                      setState(() {
                        _allowOrbMorph = true;
                        _selectedMood = trackCoreMoods[nextIdx].key;
                        _savedConfirmed = false;
                      });
                    },
                    onIntensityChanged: (next) {
                      setState(() {
                        _allowOrbMorph = true;
                        _moodIntensity = next.toDouble();
                        _savedConfirmed = false;
                      });
                    },
                    onMoodStep: (delta) {
                      final len = trackCoreMoods.length;
                      final idx = trackCoreMoods.indexWhere(
                        (m) => m.key == _selectedMood,
                      );
                      final base = idx == -1 ? 0 : idx;
                      final nextIdx = ((base + delta) % len + len) % len;
                      setState(() {
                        _allowOrbMorph = true;
                        _selectedMood = trackCoreMoods[nextIdx].key;
                        _savedConfirmed = false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    strings.orbTouchHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: tokens.ink3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    strings.todaysCoreState,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.ink2,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: strings.isArabic ? 0 : 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TrackMoodPicker(
                  selectedMoodKey: _selectedMood,
                  strings: strings,
                  onSelect: (key) {
                    setState(() {
                      _allowOrbMorph = true;
                      _selectedMood = key;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildNuancedFeelingsSection(tokens, strings, reduceMotion),
                const SizedBox(height: 16),
                TrackIntensitySlider(
                  value: _moodIntensity,
                  moodColor: activeMoodColor,
                  strings: strings,
                  onChanged: (v) {
                    setState(() {
                      _allowOrbMorph = true;
                      _moodIntensity = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: tokens.line),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.45,
                      color: tokens.ink,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: strings.whatsOnYourMindHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: tokens.ink3,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                QuickNoteSparksBar(
                  moodKey: _selectedMood,
                  controller: _noteController,
                  strings: strings,
                  onChanged: () => setState(() => _savedConfirmed = false),
                ),
                const SizedBox(height: 14),
                MindCard(
                  padding: EdgeInsets.zero,
                  child: MindPressable(
                    semanticLabel: strings.addContextOptionalTitle,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    onPressed: () {
                      setState(
                        () => _showOptionalContext = !_showOptionalContext,
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        14,
                        12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_outlined, size: 18, color: tokens.m1),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  strings.addContextOptionalTitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.addContextOptionalSub,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: tokens.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showOptionalContext
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: tokens.ink2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _showOptionalContext
                      ? _buildOptionalContextSection(tokens, strings)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: MindPressable(
                    semanticLabel: strings.preferStepByStepLabel,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => _openGuidedCheckInSheet(todayTrace),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 16,
                            color: tokens.m1,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              strings.preferStepByStepLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tokens.m1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPinnedSaveFooter(
          tokens,
          strings,
          todayTrace,
          todayTraces,
          allTraces,
          reduceMotion,
        ),
      ],
    );
  }

  Widget _buildPinnedSaveFooter(
    MindTokens tokens,
    AppStrings strings,
    MindTraceModel? todayTrace,
    List<MindTraceModel> todayTraces,
    List<MindTraceModel> allTraces,
    bool reduceMotion,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.line, width: 1.0)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              child: _savedConfirmed
                  ? Padding(
                      key: const ValueKey('saved-pill'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: tokens.m1,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                strings.savedBadgeLabel,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.m1,
                                ),
                              ),
                            ],
                          ),
                          if (todayTrace != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              CheckInMicroMirror.build(
                                latestToday: todayTrace,
                                todayTraces: todayTraces.isNotEmpty
                                    ? todayTraces
                                    : [todayTrace],
                                allTraces: allTraces,
                                strings: strings,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          MindPressable(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _tabController.animateTo(1);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    strings.isArabic
                                        ? 'عرض في السجل والتقويم'
                                        : (strings.isFrench
                                              ? 'Voir dans le calendrier'
                                              : 'View in Calendar & History'),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.ink,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: tokens.ink,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('not-saved-pill')),
            ),
            MindButton(
              text: _isComposingNewMoment
                  ? strings.logNewMomentBtn
                  : ((_editingTraceId != null || todayTrace != null)
                        ? strings.updateTodaysEntryAction
                        : strings.saveCheckInAction),
              isFullWidth: true,
              isLoading: _isSaving,
              leadingIcon: _savedConfirmed
                  ? Icons.check_rounded
                  : Icons.check_circle_outline,
              onPressed: _saveQuickCheckIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMomentsStrip(
    MindTokens tokens,
    AppStrings strings,
    List<MindTraceModel> todayTraces,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.todaysMomentsHeader,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < todayTraces.length; i++) ...[
                Builder(
                  builder: (context) {
                    final m = todayTraces[i];
                    final mColor = trackMoodOptionFor(m.overallMood).color;
                    final mLabel = trackMoodLabel(m.overallMood, strings);
                    final isSelected =
                        !_isComposingNewMoment &&
                        (_editingTraceId == m.id ||
                            (_editingTraceId == null &&
                                i == todayTraces.length - 1));
                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: '${m.formattedTime} $mLabel ${m.moodIntensity}/10',
                      child: MindPressable(
                        onPressed: () => _selectExistingMomentForEdit(m),
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tokens.selectedTintFor(mColor)
                                  : tokens.surface2,
                              borderRadius: BorderRadius.circular(
                                tokens.chipRadius,
                              ),
                              border: Border.all(
                                color: isSelected ? mColor : tokens.line,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: mColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${m.formattedTime} · $mLabel ${m.moodIntensity}/10',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: tokens.ink,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              Semantics(
                button: true,
                selected: _isComposingNewMoment,
                label: strings.newMomentChipLabel,
                child: MindPressable(
                  onPressed: _enterNewMomentMode,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _isComposingNewMoment
                            ? tokens.ink
                            : tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(
                          color: _isComposingNewMoment
                              ? tokens.ink
                              : tokens.line,
                        ),
                      ),
                      child: Text(
                        strings.newMomentChipLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isComposingNewMoment ? tokens.bg : tokens.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNuancedFeelingsSection(
    MindTokens tokens,
    AppStrings strings,
    bool reduceMotion,
  ) {
    final prioritized = AffectTaxonomy.prioritizedForCore(_selectedMood);
    final selectedLower = _selectedNuancedEmotions
        .map((e) => e.toLowerCase())
        .toSet();

    final List<NuancedFeeling> shownLibrary = _showAllNuancedEmotions
        ? prioritized
        : [
            ...prioritized.take(6),
            ...prioritized.skip(6).where(
              (f) => selectedLower.contains(f.key.toLowerCase()),
            ),
          ];

    final customKeys = _selectedNuancedEmotions
        .where((key) => AffectTaxonomy.byKey(key) == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.alsoFeelingOptionalLabel,
          style: TextStyle(
            fontFamily: 'Inter',
            color: tokens.ink2,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final feeling in shownLibrary)
                MindPill(
                  label: feeling.localized(strings),
                  icon: feeling.icon,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  isSelected: selectedLower.contains(feeling.key.toLowerCase()),
                  onTap: () {
                    setState(() {
                      final existing = _selectedNuancedEmotions
                          .where(
                            (e) => e.toLowerCase() == feeling.key.toLowerCase(),
                          )
                          .toList();
                      if (existing.isNotEmpty) {
                        _selectedNuancedEmotions.removeAll(existing);
                      } else {
                        _selectedNuancedEmotions.add(feeling.key);
                      }
                      _savedConfirmed = false;
                    });
                  },
                ),
              for (final custom in customKeys)
                MindPill(
                  label: custom,
                  icon: Icons.bubble_chart_outlined,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  isSelected: true,
                  onTap: () {
                    setState(() {
                      _selectedNuancedEmotions.remove(custom);
                      _savedConfirmed = false;
                    });
                  },
                ),
              MindPill(
                label: _showAllNuancedEmotions
                    ? strings.showFewerFeelingsBtn
                    : strings.showMoreFeelingsBtn,
                icon: _showAllNuancedEmotions
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                isSelected: false,
                onTap: () {
                  setState(() {
                    _showAllNuancedEmotions = !_showAllNuancedEmotions;
                  });
                },
              ),
              MindPill(
                label: strings.addCustomFeelingBtn,
                icon: Icons.add_rounded,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                isSelected: false,
                onTap: () => _promptCustomFeelingSheet(tokens, strings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalContextSection(MindTokens tokens, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.whatsInfluencingMood,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.triggersContextHeader,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.ink2,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _triggerOptions.map((trig) {
              final isSel = _selectedTriggers.contains(trig);
              return MindPill(
                label: strings.trackTriggerDisplay(trig),
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _savedConfirmed = false;
                    if (isSel) {
                      _selectedTriggers.remove(trig);
                    } else {
                      _selectedTriggers.add(trig);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            strings.whatHelpedTodayLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              color: tokens.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _helpedOptions.map((item) {
              final isSel = _selectedHelped.contains(item);
              return MindPill(
                label: strings.trackHelpedDisplay(item),
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _savedConfirmed = false;
                    if (isSel) {
                      _selectedHelped.remove(item);
                    } else {
                      _selectedHelped.add(item);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            strings.dailyContextTagsLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              color: tokens.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DailyContextTags.all.map((tag) {
              final isSel = _selectedContextTags.contains(tag.key);
              return MindPill(
                icon: tag.icon,
                label: tag.localized(strings),
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _savedConfirmed = false;
                    if (isSel) {
                      _selectedContextTags.remove(tag.key);
                    } else {
                      _selectedContextTags.add(tag.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSliderRow(
                  label: strings.sleepTrackingLabel,
                  value: _sleepHours,
                  min: 4,
                  max: 11,
                  divisions: 14,
                  step: 0.5,
                  unit: 'h',
                  keyPrefix: 'sleep',
                  strings: strings,
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _sleepHours = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final preset in [
                      (key: '5_5', hours: 5.5, label: strings.sleepPresetShortLabel),
                      (key: '7', hours: 7.0, label: strings.sleepPreset7hLabel),
                      (key: '8', hours: 8.0, label: strings.sleepPreset8hLabel),
                      (key: '9', hours: 9.0, label: strings.sleepPreset9hLabel),
                    ])
                      MindPill(
                        key: ValueKey<String>('sleep-preset-${preset.key}'),
                        label: preset.label,
                        fontSize: 11.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        isSelected: (_sleepHours - preset.hours).abs() < 0.05,
                        onTap: () {
                          setState(() {
                            _sleepHours = preset.hours;
                            _savedConfirmed = false;
                          });
                        },
                      ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.5),
                _buildSliderRow(
                  label: strings.energyTrackingLabel,
                  value: _energyLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  step: 1.0,
                  unit: '/10',
                  keyPrefix: 'energy',
                  strings: strings,
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _energyLevel = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const Divider(height: 20, thickness: 0.5),
                _buildSliderRow(
                  label: strings.anxietyTrackingLabel,
                  value: _anxietyLevel,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  step: 1.0,
                  unit: '/10',
                  keyPrefix: 'anxiety',
                  strings: strings,
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _anxietyLevel = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required double step,
    required String unit,
    required String keyPrefix,
    required AppStrings strings,
    required MindTokens tokens,
    required ValueChanged<double> onChanged,
  }) {
    final formatted = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );
    final canDecrease = value > min + 0.001;
    final canIncrease = value < max - 0.001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: tokens.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$formatted$unit',
              style: TextStyle(
                fontFamily: 'Inter',
                color: tokens.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            MindPressable(
              key: ValueKey<String>('${keyPrefix}_dec'),
              enabled: canDecrease,
              semanticLabel: strings.sliderDecreaseLabel(label),
              borderRadius: BorderRadius.circular(14),
              onPressed: canDecrease
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged((value - step).clamp(min, max).toDouble());
                    }
                  : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.line),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove_rounded,
                  size: 18,
                  color: canDecrease ? tokens.ink : tokens.ink3,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: tokens.ink,
                  inactiveTrackColor: tokens.line,
                  thumbColor: tokens.ink,
                  overlayColor: tokens.ink.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    onChanged(v);
                  },
                ),
              ),
            ),
            MindPressable(
              key: ValueKey<String>('${keyPrefix}_inc'),
              enabled: canIncrease,
              semanticLabel: strings.sliderIncreaseLabel(label),
              borderRadius: BorderRadius.circular(14),
              onPressed: canIncrease
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged((value + step).clamp(min, max).toDouble());
                    }
                  : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.line),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: canIncrease ? tokens.ink : tokens.ink3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryAndCalendarTab(MindTokens tokens, AppStrings strings) {
    final traces = ref.watch(mindTraceControllerProvider).value ?? const [];
    final cases = ref.watch(savedCasesProvider).value ?? const [];
    final now = DateTime.now();
    final nextMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
    final canGoNext = nextMonth.isBefore(DateTime(now.year, now.month + 1));

    final visibleTraces =
        (_selectedDateKey != null
              ? traces.where((t) => t.dateKey == _selectedDateKey).toList()
              : List<MindTraceModel>.from(traces))
          ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrackMonthCalendar(
            month: _calendarMonth,
            traces: traces,
            selectedDateKey: _selectedDateKey,
            strings: strings,
            canGoNextMonth: canGoNext,
            onPreviousMonth: () {
              setState(() {
                _calendarMonth = DateTime(
                  _calendarMonth.year,
                  _calendarMonth.month - 1,
                );
                _selectedDateKey = null;
              });
            },
            onNextMonth: () {
              if (!canGoNext) return;
              setState(() {
                _calendarMonth = nextMonth;
                _selectedDateKey = null;
              });
            },
            onSelectDateKey: (dayKey) {
              setState(() => _selectedDateKey = dayKey);
            },
            onInspectTrace: (trace) => _handleInspectTrace(trace, strings),
          ),
          const SizedBox(height: 18),
          if (traces.isEmpty && cases.isEmpty)
            MindCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  const HomeOrganicExerciseArt(size: 72),
                  const SizedBox(height: 14),
                  Text(
                    strings.timelineBuildsTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MindButton(
                    text: strings.logTodayBtn,
                    leadingIcon: Icons.add_rounded,
                    onPressed: () => _tabController.animateTo(0),
                  ),
                ],
              ),
            )
          else ...[
            if (visibleTraces.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10),
                child: Text(
                  strings.timelineOverline,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.ink2,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.6,
                  ),
                ),
              ),
            ],
            if (visibleTraces.isEmpty && _selectedDateKey != null)
              MindCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.noEntriesForDayNote,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: tokens.ink2,
                  ),
                ),
              ),
            for (var i = 0; i < visibleTraces.take(20).length; i++)
              _buildTraceCard(
                visibleTraces[i],
                tokens,
                strings,
                isLast: i == visibleTraces.take(20).length - 1,
              ),
            if (_selectedDateKey == null && cases.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                strings.recentCasesSection,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: tokens.ink2,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: strings.isArabic ? 0 : 0.6,
                ),
              ),
              const SizedBox(height: 8),
              ...cases.take(4).map((c) => _buildCaseCard(c, tokens, strings)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTraceCard(
    MindTraceModel t,
    MindTokens tokens,
    AppStrings strings, {
    bool isLast = false,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final moodColor = trackMoodOptionFor(t.overallMood).color;
    final moodSoft = tokens.selectedTintFor(moodColor);
    final moodText = trackMoodLabel(t.overallMood, strings);
    final triggers = (t.situation ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: moodSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: moodColor, width: 2.2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 6),
                      color: tokens.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: MindCard(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
                onTap: () => _handleInspectTrace(t, strings),
                semanticLabel: '${t.dateKey} $moodText ${t.moodIntensity}/10',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${t.date.day}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            strings.shortMonthName(t.date.month),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: strings.isArabic ? 0 : 0.3,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MoodEmblem(
                                moodKey: t.overallMood,
                                size: 17,
                                color: moodColor,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  '$moodText · ${t.moodIntensity}/10',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.surface2,
                                  borderRadius: BorderRadius.circular(
                                    tokens.chipRadius,
                                  ),
                                  border: Border.all(color: tokens.line),
                                ),
                                child: Text(
                                  t.formattedTime,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.ink2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (t.nuancedEmotions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final feelingKey
                                    in t.nuancedEmotions.take(3))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: moodSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: moodColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      AffectTaxonomy.localizedLabel(
                                        feelingKey,
                                        strings,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.ink,
                                      ),
                                    ),
                                  ),
                                if (t.nuancedEmotions.length > 3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tokens.surface2,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: tokens.line),
                                    ),
                                    child: Text(
                                      '+${t.nuancedEmotions.length - 3}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.ink2,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (triggers.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: triggers
                                  .map(
                                    (trig) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tokens.surface2,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: tokens.line),
                                      ),
                                      child: Text(
                                        strings.trackTriggerDisplay(trig),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          color: tokens.ink2,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (t.journalText != null &&
                              t.journalText!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              t.journalText!.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: tokens.ink2,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(
                        isRtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: tokens.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c, MindTokens tokens, AppStrings strings) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MindCard(
        padding: const EdgeInsets.all(12),
        onTap: () => GoRouter.maybeOf(context)?.push('/case/${c.id}'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.cardTint,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 16,
                color: tokens.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.incidentDescription.isNotEmpty
                        ? c.incidentDescription
                        : strings.newInvestigation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.isCompleted
                        ? (strings.isArabic
                              ? 'مكتمل'
                              : (strings.isFrench
                                    ? 'Recadrage résolu'
                                    : 'Resolved Reframe'))
                        : (strings.isArabic
                              ? 'قيد البحث'
                              : (strings.isFrench
                                    ? 'En cours'
                                    : 'In Progress')),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.ink2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: tokens.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
