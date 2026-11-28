import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_chip.dart';
import '../../../core/widgets/mind_sheet.dart';
import '../../../core/widgets/mind_strength_picker.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../../core/widgets/mood_face.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import 'widgets/progressive_details_sheet.dart';
import 'widgets/track_entry_detail_sheet.dart';
import 'widgets/track_month_calendar.dart';

/// Single-job `My days` screen: visual Month Calendar & Day Timeline ONLY.
///
/// The duplicate check-in form tab has been retired so users immediately see
/// their colorful mood history. Tapping `+ Log` or an empty day opens a quick
/// 2-tap MoodFace + strength sheet (with optional `ProgressiveDetailsSheet`).
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({
    super.key,
    this.initialTab = 0,
    this.startNewMoment = false,
    this.initialDateKey,
  });

  /// Retained for router backward-compatibility.
  final int initialTab;

  /// When true, opens the quick 2-tap mood sheet right away.
  final bool startNewMoment;

  /// Optional `YYYY-MM-DD` date key jumped to from Home's 7-day strip.
  final String? initialDateKey;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedDateKey;
  bool _openedInitialNewMoment = false;
  int _showAllLimit = 15;
  bool _privateOnlyFilter = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateKey = _formatDateKey(now);
    _applyInitialDateKey(widget.initialDateKey);
    if (widget.startNewMoment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_openedInitialNewMoment) {
          _openedInitialNewMoment = true;
          _openQuickLogSheet(forDate: DateTime.now());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TrackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDateKey != null &&
        widget.initialDateKey != oldWidget.initialDateKey) {
      setState(() {
        _applyInitialDateKey(widget.initialDateKey);
      });
    }
  }

  void _applyInitialDateKey(String? rawKey) {
    if (rawKey == null || rawKey.trim().isEmpty) return;
    final parts = rawKey.trim().split('-');
    if (parts.length != 3) return;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return;
    final normalized = _formatDateKey(DateTime(y, m, d));
    _selectedDateKey = normalized;
    _calendarMonth = DateTime(y, m);
  }

  String _formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        final now = DateTime.now();
        return DateTime(y, m, d, now.hour, now.minute);
      }
    }
    return DateTime.now();
  }

  Future<void> _openQuickLogSheet({required DateTime forDate}) async {
    final strings = ref.read(appStringsProvider);
    AppMood? chosenMood;

    await showMindSheet<void>(
      context: context,
      showCloseButton: true,
      title: strings.howAreYouRightNow,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final tokens = ctx.tokens;
            final textScale = MediaQuery.textScalerOf(ctx).scale(16.0) / 16.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols =
                        (constraints.maxWidth < 318 || textScale > 1.25)
                        ? 2
                        : 3;
                    final tileWidth =
                        (constraints.maxWidth - (cols - 1) * 10) / cols;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final mood in AppMood.values)
                          SizedBox(
                            width: tileWidth,
                            child: MoodFaceTile(
                              mood: mood,
                              label: strings.plainMoodLabel(mood.key),
                              isSelected: chosenMood == mood,
                              onTap: () =>
                                  setSheetState(() => chosenMood = mood),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (chosenMood != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    strings.howStrongQuestion,
                    style: LabTheme.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MindStrengthPicker(
                    selectedIntensity: null,
                    aLittleLabel: strings.strengthALittle,
                    mediumLabel: strings.strengthMedium,
                    aLotLabel: strings.strengthALot,
                    accentColor: MindTokens.moodColor(chosenMood!),
                    onSelected: (intensity) async {
                      final now = DateTime.now();
                      final trace = MindTraceModel(
                        id: 'trace_${now.millisecondsSinceEpoch}',
                        userId:
                            ref.read(authControllerProvider).user?.id ??
                            'local_user',
                        date: forDate,
                        overallMood: chosenMood!.key,
                        moodIntensity: intensity,
                        selectedEmotions: [chosenMood!.key],
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref
                          .read(mindTraceControllerProvider.notifier)
                          .recordCheckIn(trace, generateAi: false);
                      ref
                          .read(activeMoodProvider.notifier)
                          .setMood(chosenMood!);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        setState(() {
                          _selectedDateKey = trace.dateKey;
                          _calendarMonth = DateTime(forDate.year, forDate.month);
                        });
                        showMindToast(context, strings.checkInSavedSnackbar);
                      }
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exploreTraceInTalk(
    MindTraceModel trace,
    AppStrings strings,
  ) async {
    final mode = trace.moodIntensity >= 8
        ? ConversationMode.grounding
        : ConversationMode.exploreThought;
    ref.read(currentConversationModeProvider.notifier).setMode(mode);
    final seedPrompt = strings.talkAboutMoodPrompt(
      strings.plainMoodLabel(trace.overallMood),
      trace.moodIntensity,
      trace.journalText,
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
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];
    final now = DateTime.now();

    final canGoNextMonth =
        _calendarMonth.year < now.year ||
        (_calendarMonth.year == now.year && _calendarMonth.month < now.month);

    final hasPrivateEntries = traces.any((t) => t.isPrivate);
    final filteredBase = _privateOnlyFilter
        ? traces.where((t) => t.isPrivate).toList()
        : traces;
    final sortedAll = [...filteredBase]
      ..sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));

    final dayEntries = _selectedDateKey != null
        ? sortedAll.where((t) => t.dateKey == _selectedDateKey).toList()
        : sortedAll.take(_showAllLimit).toList();
    final hasMoreAllEntries =
        _selectedDateKey == null && sortedAll.length > _showAllLimit;

    return AmbientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Single-Job Header (Wraps gracefully at 320px 2.0x textScale)
              Text(
                strings.navMyDays,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LabTheme.textStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MindButton(
                  text: strings.logNewMomentLink,
                  variant: MindButtonVariant.soft,
                  onPressed: () => _openQuickLogSheet(
                    forDate: _selectedDateKey != null
                        ? _parseDateKey(_selectedDateKey!)
                        : DateTime.now(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Vivid Month Calendar (Opens Immediately!)
              TrackMonthCalendar(
                month: _calendarMonth,
                traces: traces,
                selectedDateKey: _selectedDateKey,
                strings: strings,
                canGoNextMonth: canGoNextMonth,
                onPreviousMonth: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month - 1,
                    );
                  });
                },
                onNextMonth: () {
                  if (!canGoNextMonth) return;
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month + 1,
                    );
                  });
                },
                onSelectDateKey: (key) => setState(() {
                  _selectedDateKey = key;
                  if (key == null) _showAllLimit = 15;
                }),
                onInspectTrace: (trace) => _inspectTrace(trace, strings),
              ),

              const SizedBox(height: 18),

              // 2. Selected Day Timeline (when Show-all is active, anchor with clear title + optional private filter)
              if (_selectedDateKey == null || hasPrivateEntries) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_selectedDateKey == null)
                      Text(
                        strings.allRecentEntriesTitle,
                        style: LabTheme.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tokens.ink,
                        ),
                      ),
                    if (hasPrivateEntries)
                      MindChip(
                        key: const ValueKey('track-private-filter-chip'),
                        label: strings.privateOnlyFilterLabel,
                        leadingIcon: Icons.lock_outline_rounded,
                        selected: _privateOnlyFilter,
                        onTap: () => setState(
                          () => _privateOnlyFilter = !_privateOnlyFilter,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              if (dayEntries.isEmpty)
                MindCard(
                  variant: MindCardVariant.flat,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const MoodFace(mood: AppMood.calm, size: 52),
                      const SizedBox(height: 12),
                      Text(
                        strings.thoughtTraceQuote,
                        textAlign: TextAlign.center,
                        style: LabTheme.textStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        text: strings.addCheckInForDayBtn,
                        isFullWidth: true,
                        onPressed: () => _openQuickLogSheet(
                          forDate: _selectedDateKey != null
                              ? _parseDateKey(_selectedDateKey!)
                              : DateTime.now(),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                for (final entry in dayEntries) ...[
                  _buildTimelineEntryCard(entry, tokens, strings),
                  const SizedBox(height: 10),
                ],
                if (hasMoreAllEntries) ...[
                  const SizedBox(height: 4),
                  MindButton(
                    key: const ValueKey('track-load-older-btn'),
                    text: strings.loadOlderEntriesBtn,
                    variant: MindButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () => setState(() => _showAllLimit += 20),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _inspectTrace(MindTraceModel trace, AppStrings strings) {
    TrackEntryDetailSheet.show(
      context,
      trace: trace,
      onEdit: () => ProgressiveDetailsSheet.show(context, trace: trace),
      onExploreWithAi: () => _exploreTraceInTalk(trace, strings),
    );
  }

  Widget _buildTimelineEntryCard(
    MindTraceModel trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final mood = AppMood.fromKey(trace.overallMood);
    final moodLabel = strings.plainMoodLabel(trace.overallMood);
    final strengthLabel = strings.strengthWordForIntensity(trace.moodIntensity);
    final ts = trace.effectiveTimestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    final subtitleText = _selectedDateKey == null
        ? '${strings.formatHumanDate(ts)} · $strengthLabel · $timeStr'
        : '$strengthLabel · $timeStr';

    final detailPills = <String>[
      if (trace.sleepHours != null)
        '${strings.sleepTrackingLabel} ${MindFormatters.hours(trace.sleepHours!, strings)}',
      if (trace.energyLevel != null)
        '${strings.energyTrackingLabel} ${trace.energyLevel}/10',
      if (trace.physicalTension != null)
        '${strings.physicalTensionLabel} ${trace.physicalTension}/10',
      ...trace.contextTags
          .take(3)
          .map((tag) => DailyContextTags.localizedLabel(tag, strings)),
      if (trace.behavioralResponse != null &&
          trace.behavioralResponse!.trim().isNotEmpty)
        ...trace.behavioralResponse!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .map(strings.localizedWhatHelped),
    ];

    return MindCard(
      onTap: () {
        HapticFeedback.selectionClick();
        _inspectTrace(trace, strings);
      },
      semanticLabel: '$moodLabel · $subtitleText',
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodFace(mood: mood, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        moodLabel,
                        style: LabTheme.textStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    if (trace.isPrivate) ...[
                      const SizedBox(width: 6),
                      Semantics(
                        label: strings.keepJustForMeLabel,
                        child: Tooltip(
                          message: strings.keepJustForMeLabel,
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: tokens.ink2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: LabTheme.textStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
                if (trace.journalText != null &&
                    trace.journalText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trace.journalText!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LabTheme.textStyle(
                      fontSize: 14.0,
                      height: 1.4,
                      color: tokens.ink2,
                    ),
                  ),
                ],
                if (detailPills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final pill in detailPills)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.line),
                          ),
                          child: Text(
                            pill,
                            style: LabTheme.textStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: tokens.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
