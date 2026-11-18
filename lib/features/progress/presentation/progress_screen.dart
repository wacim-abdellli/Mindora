import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/trace_entry_detail_sheet.dart';
import '../../track/presentation/widgets/track_entry_detail_sheet.dart'
    show EditPastTraceSheet;
import '../data/progress_analytics_service.dart';
import '../domain/progress_analytics_model.dart';

/// My Progress: A clean, friendly personal psychological history.
///
/// Two tabs via MindSegmented:
///   - Overview: Key metrics, thought trace, emotional spectrum,
///     intensity timeline, somatic insights, patterns.
///   - Journal: Calendar heatmap, monthly entries, reflection archive,
///     milestones & journey.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _tabIndex = 0;
  final TextEditingController _reflectionSearchController =
      TextEditingController();

  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  MindTraceModel? _selectedCalendarTrace;

  @override
  void dispose() {
    _reflectionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final analytics = ref.watch(progressAnalyticsProvider);
    final selectedWindow = ref.watch(selectedTimeWindowProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Compact header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.progressTitle,
                        style: TextStyle(
                          fontFamily: LabTheme.fontFamily,
                          fontFamilyFallback: LabTheme.fontFallback,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    const SupportButton(),
                  ],
                ),
              ),
            ),

            // ── Subtitle quote ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  strings.progressQuote,
                  style: LabTheme.textStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: tokens.ink3,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // ── Time window pills ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TimeWindowRow(
                  selected: selectedWindow,
                  onChanged: (w) => ref
                      .read(selectedTimeWindowProvider.notifier)
                      .setWindow(w),
                  strings: strings,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Segmented tab switcher ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MindSegmented(
                  index: _tabIndex,
                  labels: [
                    strings.isArabic
                        ? 'نظرة عامة'
                        : (strings.isFrench ? 'Aperçu' : 'Overview'),
                    strings.isArabic
                        ? 'السجل'
                        : (strings.isFrench ? 'Journal' : 'Journal'),
                  ],
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Tab content ──
            if (_tabIndex == 0)
              ..._buildOverviewSlices(analytics, strings)
            else
              ..._buildJournalSlices(analytics, strings),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 0  —  OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildOverviewSlices(
    ProgressAnalyticsModel analytics,
    AppStrings strings,
  ) {
    final tokens = context.tokens;
    return [
      // ── Key Metrics ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MetricTile(
                label: strings.totalEntriesMetric,
                value: '${analytics.totalEntries}',
              ),
              const SizedBox(width: 10),
              _MetricTile(
                label: strings.uniqueDaysMetric,
                value: '${analytics.uniqueDaysCount}',
              ),
              const SizedBox(width: 10),
              _MetricTile(
                label: strings.emotionSelectionsMetric,
                value: '${analytics.totalEmotionSelections}',
              ),
            ],
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),

      // ── Thought Trace Summary ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ThoughtTraceCard(
            analytics: analytics,
            strings: strings,
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),

      // ── Emotional Spectrum ──
      if (analytics.emotionFrequencies.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _EmotionalSpectrumCard(
              analytics: analytics,
              strings: strings,
            ),
          ),
        ),

      if (analytics.emotionFrequencies.isNotEmpty)
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

      // ── Emotional Granularity ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MindCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.cardTint,
                    border: Border.all(
                      color: tokens.m1.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(Icons.palette_outlined,
                      size: 20, color: tokens.m1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.emotionalVarietyTitle,
                        style: TextStyle(
                          fontFamily: LabTheme.fontFamily,
                          fontFamilyFallback: LabTheme.fontFallback,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.distinctEmotionsCount(
                            analytics.emotionalVarietyCount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),

      // ── Intensity Timeline ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _IntensityTimelineCard(
            analytics: analytics,
            strings: strings,
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),

      // ── Somatic & Sleep ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SomaticSleepCard(
            analytics: analytics,
            strings: strings,
          ),
        ),
      ),

      // ── Patterns Worth Exploring ──
      if (analytics.insights.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PatternsSection(
              insights: analytics.insights,
              strings: strings,
              onDismiss: (id) =>
                  ref.read(dismissedInsightsProvider.notifier).dismiss(id),
            ),
          ),
        ),
      ],
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1  —  JOURNAL
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildJournalSlices(
    ProgressAnalyticsModel analytics,
    AppStrings strings,
  ) {
    final tokens = context.tokens;
    final allTraces =
        ref.watch(mindTraceControllerProvider).value ?? <MindTraceModel>[];
    final monthTraces = allTraces.where((t) {
      return t.date.year == _calendarMonth.year &&
          t.date.month == _calendarMonth.month;
    }).toList();

    final loggedMap = <String, MindTraceModel>{
      for (final t in allTraces) t.dateKey: t,
    };

    final daysInMonth = DateUtils.getDaysInMonth(
        _calendarMonth.year, _calendarMonth.month);
    final firstDayOffset =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday - 1;

    return [
      // ── Calendar Heatmap ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MindCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_getMonthName(_calendarMonth.month, strings)} ${_calendarMonth.year}',
                        style: TextStyle(
                          fontFamily: LabTheme.fontFamily,
                          fontFamilyFallback: LabTheme.fontFallback,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: strings.previousMonthTooltip,
                          icon: const Icon(Icons.chevron_left, size: 22),
                          color: tokens.ink2,
                          constraints: const BoxConstraints(
                              minWidth: 48, minHeight: 48),
                          onPressed: () {
                            setState(() {
                              _calendarMonth = DateTime(
                                  _calendarMonth.year,
                                  _calendarMonth.month - 1);
                              _selectedCalendarTrace = null;
                            });
                          },
                        ),
                        IconButton(
                          tooltip: strings.nextMonthTooltip,
                          icon: const Icon(Icons.chevron_right, size: 22),
                          color: tokens.ink2,
                          constraints: const BoxConstraints(
                              minWidth: 48, minHeight: 48),
                          onPressed: () {
                            final next = DateTime(_calendarMonth.year,
                                _calendarMonth.month + 1);
                            final now = DateTime.now();
                            if (next.isBefore(
                                DateTime(now.year, now.month + 1))) {
                              setState(() {
                                _calendarMonth = next;
                                _selectedCalendarTrace = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.calendarNoBreaksNote,
                  style: TextStyle(
                      fontSize: 12, color: tokens.ink3, height: 1.3),
                ),
                const SizedBox(height: 16),

                // Weekday labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink3,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Days grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: daysInMonth + firstDayOffset,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstDayOffset) {
                      return const SizedBox.shrink();
                    }
                    final day = index - firstDayOffset + 1;
                    final dayKey =
                        '${_calendarMonth.year.toString().padLeft(4, '0')}-${_calendarMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final matched = loggedMap[dayKey];
                    final isLogged = matched != null;
                    final now = DateTime.now();
                    final isToday = day == now.day &&
                        _calendarMonth.month == now.month &&
                        _calendarMonth.year == now.year;
                    final isSelected =
                        _selectedCalendarTrace?.dateKey == dayKey;

                    return MindPressable(
                      onPressed: isLogged
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _selectedCalendarTrace = matched);
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.ink
                              : (isLogged
                                  ? tokens.cardTint
                                  : tokens.surface2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday || isSelected
                                ? tokens.ink
                                : (isLogged
                                    ? tokens.m1.withValues(alpha: 0.35)
                                    : tokens.line),
                            width: isToday || isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLogged || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? tokens.bg
                                  : (isLogged
                                      ? tokens.ink
                                      : (isToday
                                          ? tokens.ink
                                          : tokens.ink3)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Selected day detail
                if (_selectedCalendarTrace != null) ...[
                  const SizedBox(height: 16),
                  _SelectedDayCard(
                    trace: _selectedCalendarTrace!,
                    strings: strings,
                    onDelete: () => _confirmDeleteTrace(
                        context, _selectedCalendarTrace!, strings),
                    onOpen: () {
                      TraceEntryDetailSheet.show(
                        context,
                        trace: _selectedCalendarTrace!,
                        onEdit: () => EditPastTraceSheet.show(
                            context, _selectedCalendarTrace!),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 20)),

      // ── Monthly Entries ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            strings.isArabic
                ? 'سجل هذا الشهر'
                : (strings.isFrench
                    ? 'Ce mois-ci'
                    : 'This month'),
            style: TextStyle(
              fontFamily: LabTheme.fontFamily,
              fontFamilyFallback: LabTheme.fontFallback,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
        ),
      ),

      if (monthTraces.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MindCard(
              variant: MindCardVariant.flat,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    strings.isArabic
                        ? 'لم يتم تسجيل أي آثار في هذا الشهر.'
                        : (strings.isFrench
                            ? 'Aucune trace enregistrée ce mois-ci.'
                            : 'No traces recorded this month.'),
                    style: TextStyle(
                        fontSize: 13, color: tokens.ink3),
                  ),
                ),
              ),
            ),
          ),
        )
      else
        SliverList.builder(
          itemCount: monthTraces.length,
          itemBuilder: (context, index) {
            final trace = monthTraces[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: MindCard(
                radius: tokens.rowRadius,
                onTap: () {
                  TraceEntryDetailSheet.show(
                    context,
                    trace: trace,
                    onEdit: () =>
                        EditPastTraceSheet.show(context, trace),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.cardTint,
                        border: Border.all(
                          color: tokens.m1.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${trace.date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trace.overallMood,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          if (trace.selectedEmotions.isNotEmpty)
                            Text(
                              trace.selectedEmotions.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: tokens.ink3),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${trace.moodIntensity}/10',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: tokens.ink3),
                  ],
                ),
              ),
            );
          },
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 20)),

      // ── Reflections Archive ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ReflectionsSection(
            analytics: analytics,
            strings: strings,
            searchController: _reflectionSearchController,
            ref: ref,
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 20)),

      // ── Milestones & Journey ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MilestonesSection(
            analytics: analytics,
            strings: strings,
          ),
        ),
      ),
    ];
  }

  void _confirmDeleteTrace(
      BuildContext context, MindTraceModel trace, AppStrings strings) {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.cardRadius)),
        title: Text(strings.deleteTraceConfirmTitle,
            style: TextStyle(color: tokens.ink)),
        content: Text(strings.deleteTraceConfirmBody,
            style: TextStyle(color: tokens.ink2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:
                Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref
                  .read(mindTraceControllerProvider.notifier)
                  .deleteCheckIn(trace.id);
              setState(() => _selectedCalendarTrace = null);
            },
            style: TextButton.styleFrom(foregroundColor: tokens.safety),
            child: Text(strings.deleteEntryBtn),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month, AppStrings strings) {
    if (strings.isArabic) {
      const names = [
        'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
        'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      return names[(month - 1).clamp(0, 11)];
    } else if (strings.isFrench) {
      const names = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
      ];
      return names[(month - 1).clamp(0, 11)];
    } else {
      const names = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return names[(month - 1).clamp(0, 11)];
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EXTRACTED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Compact time-window pill row.
class _TimeWindowRow extends StatelessWidget {
  const _TimeWindowRow({
    required this.selected,
    required this.onChanged,
    required this.strings,
  });

  final ProgressTimeWindow selected;
  final ValueChanged<ProgressTimeWindow> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProgressTimeWindow.values.map((w) {
          final active = w == selected;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: MindPressable(
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged(w);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? tokens.cardTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: active ? tokens.m1 : tokens.line,
                    width: active ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  w.label(strings),
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? tokens.ink : tokens.ink2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Single metric tile for the top metrics row.
class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Expanded(
      child: MindCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thought trace summary card with the latest 3 traces.
class _ThoughtTraceCard extends StatelessWidget {
  const _ThoughtTraceCard({
    required this.analytics,
    required this.strings,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final traces = analytics.chronologicalTraces;

    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint_rounded, size: 18, color: tokens.m1),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.thoughtTraceTitle,
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              Text(
                '${traces.length}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.thoughtTraceQuote,
            style: LabTheme.textStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: tokens.ink3,
            ),
          ),
          const SizedBox(height: 14),

          if (traces.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    strings.thoughtTraceWaitingTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.thoughtTraceWaitingSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: tokens.ink3, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  MindButton(
                    text: strings.recordTodayTraceBtn,
                    onPressed: () =>
                        context.go(AppRouter.track),
                  ),
                ],
              ),
            )
          else
            ...traces.reversed.take(3).map((trace) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MindCard(
                  variant: MindCardVariant.flat,
                  radius: tokens.rowRadius,
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    ThoughtTraceDetailSheet.show(
                      context,
                      trace: trace,
                      onEdit: () =>
                          context.go(AppRouter.track),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trace.dateKey,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tokens.cardTint,
                              borderRadius:
                                  BorderRadius.circular(99),
                              border: Border.all(
                                color: tokens.m1
                                    .withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${trace.overallMood} · ${trace.moodIntensity}/10',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${trace.thoughtPreview}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LabTheme.textStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: tokens.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          if (traces.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: MindPressable(
                onPressed: () =>
                    context.go(AppRouter.track),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timeline_rounded,
                          size: 14, color: tokens.ink2),
                      const SizedBox(width: 6),
                      Text(
                        strings.isArabic
                            ? 'فتح الخط الزمني الكامل'
                            : (strings.isFrench
                                ? 'Ouvrir la chronologie complète'
                                : 'Open full timeline'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Emotional frequency spectrum with proportional bars.
class _EmotionalSpectrumCard extends StatelessWidget {
  const _EmotionalSpectrumCard({
    required this.analytics,
    required this.strings,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entries = analytics.emotionFrequencies.entries.take(5).toList();
    final total = analytics.totalEntries > 0 ? analytics.totalEntries : 1;

    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.emotionalSpectrumTitle,
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${analytics.emotionalVarietyCount} ${strings.isArabic ? 'مشاعر' : (strings.isFrench ? 'Identifiées' : 'Identified')}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final ratio = (entry.value / total).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                      Text(
                        '${(ratio * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: tokens.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(tokens.m1),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Mood intensity timeline with micro bars.
class _IntensityTimelineCard extends StatelessWidget {
  const _IntensityTimelineCard({
    required this.analytics,
    required this.strings,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.intensityTimelineTitle,
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${analytics.averageIntensity.toStringAsFixed(1)} / 10',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.intensityMinMax(
                analytics.minIntensity, analytics.maxIntensity),
            style: TextStyle(fontSize: 12, color: tokens.ink3),
          ),
          const SizedBox(height: 16),
          if (analytics.intensityTimeline.isEmpty)
            Text(
              strings.isArabic
                  ? 'لا توجد بيانات كافية.'
                  : (strings.isFrench
                      ? 'Données insuffisantes.'
                      : 'Not enough data yet.'),
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            )
          else ...[
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    analytics.intensityTimeline.map((item) {
                  final h =
                      (item.intensity / 10.0).clamp(0.1, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 1.5),
                      child: Tooltip(
                        message:
                            '${item.date.month}/${item.date.day}: ${item.mood} (${item.intensity}/10)',
                        child: Container(
                          height: 64 * h,
                          decoration: BoxDecoration(
                            color: item.intensity >= 7
                                ? tokens.safety
                                    .withValues(alpha: 0.7)
                                : tokens.m1
                                    .withValues(alpha: 0.7),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${analytics.intensityTimeline.first.date.month}/${analytics.intensityTimeline.first.date.day}',
                  style: TextStyle(
                      fontSize: 10, color: tokens.ink3),
                ),
                Text(
                  '${analytics.intensityTimeline.last.date.month}/${analytics.intensityTimeline.last.date.day}',
                  style: TextStyle(
                      fontSize: 10, color: tokens.ink3),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Somatic & Sleep empirical card.
class _SomaticSleepCard extends StatelessWidget {
  const _SomaticSleepCard({
    required this.analytics,
    required this.strings,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime_outlined,
                  size: 18, color: MindTokens.moodRestless),
              const SizedBox(width: 8),
              Text(
                strings.energyAndSleepTitle,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SomaticPill(
                label: strings.avgEnergyMetric,
                value: analytics.averageEnergy != null
                    ? '${analytics.averageEnergy!.toStringAsFixed(1)}/10'
                    : '--',
              ),
              const SizedBox(width: 8),
              _SomaticPill(
                label: strings.avgSleepMetric,
                value: analytics.averageSleepDuration != null
                    ? '${analytics.averageSleepDuration!.toStringAsFixed(1)}h'
                    : '--',
              ),
              const SizedBox(width: 8),
              _SomaticPill(
                label: strings.avgQualityMetric,
                value: analytics.averageSleepQuality != null
                    ? '${analytics.averageSleepQuality!.toStringAsFixed(1)}/5'
                    : '--',
              ),
            ],
          ),
          if (analytics.sleepTensionObservation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analytics.sleepTensionObservation!,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink,
                        height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.empiricalDisclaimer,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: tokens.ink3,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SomaticPill extends StatelessWidget {
  const _SomaticPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink3),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Patterns Worth Exploring section.
class _PatternsSection extends StatelessWidget {
  const _PatternsSection({
    required this.insights,
    required this.strings,
    required this.onDismiss,
  });

  final List<PersonalInsightItem> insights;
  final AppStrings strings;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.patternsWorthExploringTitle,
          style: TextStyle(
            fontFamily: LabTheme.fontFamily,
            fontFamilyFallback: LabTheme.fontFallback,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.patternsSub,
          style: TextStyle(fontSize: 12, color: tokens.ink3),
        ),
        const SizedBox(height: 14),
        ...insights.map((ins) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MindCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(ins.icon, size: 16, color: tokens.m1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ins.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      MindPressable(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onDismiss(ins.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            strings.dismissInsight,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ins.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: tokens.ink,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ins.caveat,
                    style: TextStyle(
                        fontSize: 11,
                        color: tokens.ink3,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Selected calendar day detail card.
class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.trace,
    required this.strings,
    required this.onDelete,
    required this.onOpen,
  });

  final MindTraceModel trace;
  final AppStrings strings;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MindCard(
      variant: MindCardVariant.tint,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trace.dateKey,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${trace.overallMood} · ${trace.moodIntensity}/10',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink),
                ),
              ),
            ],
          ),
          if (trace.journalText != null &&
              trace.journalText!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${trace.journalText!}"',
              style: LabTheme.textStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: tokens.ink,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: tokens.safety,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(strings.deleteEntryBtn,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              MindButton(
                text: strings.reopenTraceAction,
                onPressed: onOpen,
                variant: MindButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reflections archive section with search + filter chips.
class _ReflectionsSection extends StatelessWidget {
  const _ReflectionsSection({
    required this.analytics,
    required this.strings,
    required this.searchController,
    required this.ref,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;
  final TextEditingController searchController;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final query =
        ref.watch(reflectionSearchQueryProvider).toLowerCase().trim();
    final sourceFilter =
        ref.watch(selectedReflectionSourceFilterProvider);

    final filtered = analytics.allReflections.where((item) {
      if (sourceFilter != null && item.sourceType != sourceFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        return item.text.toLowerCase().contains(query) ||
            item.sourceTitle.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isArabic
              ? 'أرشيف التأملات'
              : (strings.isFrench
                  ? 'Archive des réflexions'
                  : 'Reflections'),
          style: TextStyle(
            fontFamily: LabTheme.fontFamily,
            fontFamilyFallback: LabTheme.fontFallback,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          controller: searchController,
          onChanged: (val) =>
              ref.read(reflectionSearchQueryProvider.notifier).setQuery(val),
          style: TextStyle(fontSize: 13, color: tokens.ink),
          decoration: InputDecoration(
            hintText: strings.searchReflectionsHint,
            hintStyle: TextStyle(fontSize: 13, color: tokens.ink3),
            prefixIcon:
                Icon(Icons.search, size: 18, color: tokens.ink2),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    tooltip: strings.clearSearchTooltip,
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      searchController.clear();
                      ref
                          .read(reflectionSearchQueryProvider.notifier)
                          .setQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: tokens.surface2,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide: BorderSide(color: tokens.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide: BorderSide(color: tokens.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide:
                  BorderSide(color: tokens.lineStrong, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: strings.filterAllSources,
                isSelected: sourceFilter == null,
                onTap: () => ref
                    .read(selectedReflectionSourceFilterProvider.notifier)
                    .setFilter(null),
              ),
              const SizedBox(width: 8),
              ...ReflectionSourceType.values.map((type) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _FilterChip(
                    label: type.label(strings),
                    icon: type.icon,
                    isSelected: sourceFilter == type,
                    onTap: () => ref
                        .read(
                            selectedReflectionSourceFilterProvider.notifier)
                        .setFilter(type),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Items
        if (filtered.isEmpty)
          MindCard(
            variant: MindCardVariant.flat,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  analytics.allReflections.isEmpty
                      ? strings.noReflectionsEmpty
                      : strings.noReflectionsFound,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: tokens.ink3, height: 1.4),
                ),
              ),
            ),
          )
        else
          ...filtered.take(10).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                radius: tokens.rowRadius,
                onTap: item.originalTrace != null
                    ? () {
                        TraceEntryDetailSheet.show(
                          context,
                          trace: item.originalTrace!,
                          onEdit: () => EditPastTraceSheet.show(
                              context, item.originalTrace!),
                        );
                      }
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.sourceType.icon,
                            size: 14, color: tokens.m1),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.sourceTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                              fontSize: 11, color: tokens.ink3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${item.text}"',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LabTheme.textStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: tokens.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Filter chip for reflections.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MindPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tokens.cardTint : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? tokens.m1 : tokens.line,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: isSelected ? tokens.ink : tokens.ink3),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? tokens.ink : tokens.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Milestones & journey section.
class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({
    required this.analytics,
    required this.strings,
  });

  final ProgressAnalyticsModel analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final journeyRatio = analytics.totalJourneyActivities > 0
        ? (analytics.journeyActivitiesExplored /
                analytics.totalJourneyActivities)
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Journey progress card
        MindCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.journeyProgressTitle,
                      style: TextStyle(
                        fontFamily: LabTheme.fontFamily,
                        fontFamilyFallback: LabTheme.fontFallback,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.activitiesExplored(
                      analytics.journeyActivitiesExplored,
                      analytics.totalJourneyActivities,
                    ),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: journeyRatio,
                  minHeight: 6,
                  backgroundColor: tokens.surface2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(tokens.m1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Milestones title
        Text(
          strings.milestonesTitle,
          style: TextStyle(
            fontFamily: LabTheme.fontFamily,
            fontFamilyFallback: LabTheme.fontFallback,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.milestonesSub,
          style: TextStyle(fontSize: 12, color: tokens.ink3, height: 1.3),
        ),
        const SizedBox(height: 14),

        // Milestone rows
        ...analytics.milestones.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MindCard(
              variant: m.isUnlocked
                  ? MindCardVariant.tint
                  : MindCardVariant.flat,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isUnlocked
                          ? tokens.cardTint
                          : tokens.surface,
                      border: Border.all(
                        color: m.isUnlocked
                            ? tokens.m1
                            : tokens.line,
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      m.isUnlocked
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: m.isUnlocked
                          ? tokens.m1
                          : tokens.ink3,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: m.isUnlocked
                                ? tokens.ink
                                : tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: tokens.ink3,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m.isUnlocked
                        ? (strings.isArabic
                            ? 'مفتوح'
                            : (strings.isFrench
                                ? 'Débloqué'
                                : 'Unlocked'))
                        : '${m.currentValue}/${m.targetValue}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: m.isUnlocked
                          ? tokens.m1
                          : tokens.ink3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
