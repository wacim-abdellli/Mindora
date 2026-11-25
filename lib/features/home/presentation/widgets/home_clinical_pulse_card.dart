import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../mind_trace/domain/adaptive_tracking_engine.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../onboarding/domain/app_personalization_engine.dart';
import '../../../profile/domain/psychological_profile_model.dart';

/// Playful, non-military adaptive daily ritual card for `Today` ([HomeScreen]).
///
/// Selects at most 2–3 high-signal metrics driven directly by the user's active
/// condition tracks (covering 300+ DSM-5-TR / ICD-11 terms) and time of day,
/// rendered with tactile visual widgets and a working Done / Collapse bar.
class HomeClinicalPulseCard extends StatefulWidget {
  const HomeClinicalPulseCard({
    super.key,
    required this.tokens,
    required this.strings,
    required this.plan,
    required this.todayTrace,
    required this.onUpdateTrace,
    this.profile,
    this.loggedDaysThisWeek = 0,
    this.overrideHour,
  });

  final MindTokens tokens;
  final AppStrings strings;
  final AppPersonalizationPlan plan;
  final MindTraceModel? todayTrace;
  final Future<void> Function(
    MindTraceModel Function(MindTraceModel? existing) updater,
  )
  onUpdateTrace;
  final PsychologicalProfileModel? profile;
  final int loggedDaysThisWeek;
  final int? overrideHour;

  @override
  State<HomeClinicalPulseCard> createState() => _HomeClinicalPulseCardState();
}

class _HomeClinicalPulseCardState extends State<HomeClinicalPulseCard> {
  bool _collapsed = false;

  bool get _isMorning {
    final hour = widget.overrideHour ?? DateTime.now().hour;
    return hour >= 5 && hour < 14;
  }

  int get _effectiveHour =>
      widget.overrideHour ?? DateTime.now().hour;

  MindTraceModel _baseOrNew(MindTraceModel? existing) {
    if (existing != null) return existing;
    final now = DateTime.now();
    return MindTraceModel(
      id: 'trace_${now.millisecondsSinceEpoch}',
      userId: 'local_user',
      date: now,
      overallMood: 'calm',
      moodIntensity: 5,
      selectedEmotions: const ['calm'],
      createdAt: now,
      updatedAt: now,
    );
  }

  void _handleDonePressed(BuildContext context, List<AdaptiveMetricSpec> specs) {
    HapticFeedback.mediumImpact();
    setState(() => _collapsed = !_collapsed);
    if (_collapsed) {
      showMindToast(context, widget.strings.ritualSavedSummaryToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final strings = widget.strings;
    final todayTrace = widget.todayTrace;
    final plan = widget.plan;

    // Minimal exploration users only see clinical ritual if they started logging or enabled Doctor Prep.
    if (plan.isMinimalExplorationMode &&
        todayTrace?.sleepHours == null &&
        todayTrace?.energyLevel == null &&
        todayTrace?.anxietyLevel == null &&
        (todayTrace?.dynamicAnswers ?? {}).isEmpty) {
      return const SizedBox.shrink();
    }

    final specs = AdaptiveTrackingEngine.buildDailyRitual(
      profile: widget.profile,
      plan: plan,
      todayTrace: todayTrace,
      hour: _effectiveHour,
    );

    final completed = specs
        .where((s) => AdaptiveTrackingEngine.isMetricCompleted(s.kind, todayTrace))
        .length;
    final total = specs.length;
    final isComplete = total > 0 && completed >= total;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return MindCard(
      key: const ValueKey('home-clinical-pulse-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.tint(
                    _isMorning ? MindTokens.moodGood : MindTokens.moodAnxious,
                    tokens.isDark ? 0.18 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isMorning
                      ? Icons.wb_twilight_rounded
                      : Icons.nights_stay_outlined,
                  size: 20,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMorning
                          ? strings.morningPulseTitle
                          : strings.eveningPulseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LabTheme.textStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isMorning
                          ? strings.ritualMorningTag
                          : strings.ritualEveningTag,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LabTheme.textStyle(
                        fontSize: 13.0,
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isComplete || _collapsed)
                Semantics(
                  button: true,
                  label: _collapsed
                      ? strings.ritualSavedCompactBtn
                      : strings.ritualSaveCollapseBtn,
                  child: MindPressable(
                    key: const ValueKey('pulse-done-toggle-btn'),
                    onPressed: () => _handleDonePressed(context, specs),
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _collapsed ? tokens.surface2 : tokens.primary,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(
                          color: _collapsed ? tokens.lineStrong : tokens.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _collapsed
                                ? Icons.edit_outlined
                                : Icons.check_circle_rounded,
                            size: 15,
                            color: _collapsed ? tokens.ink : tokens.onPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _collapsed
                                ? strings.ritualSavedCompactBtn
                                : strings.ritualSaveCollapseBtn,
                            style: LabTheme.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _collapsed ? tokens.ink : tokens.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                MindBadge(
                  key: const ValueKey('pulse-progress-indicator'),
                  label: '$completed / $total',
                  backgroundColor: tokens.surface,
                  borderColor: tokens.lineStrong,
                  textColor: tokens.ink2,
                ),
            ],
          ),

          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: _collapsed
                ? Padding(
                    key: const ValueKey('pulse-collapsed-view'),
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildCollapsedSummary(
                      specs,
                      todayTrace,
                      tokens,
                      strings,
                    ),
                  )
                : Column(
                    key: const ValueKey('pulse-expanded-view'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.loggedDaysThisWeek > 0) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MindBadge(
                            icon: Icons.auto_awesome_outlined,
                            label: strings.ritualStreakPill(
                              widget.loggedDaysThisWeek,
                            ),
                            backgroundColor: tokens.surface2,
                            textColor: tokens.ink2,
                          ),
                        ),
                      ],
                      for (var i = 0; i < specs.length; i++) ...[
                        SizedBox(height: i == 0 ? 16 : 18),
                        _buildMetricBlock(
                          specs[i],
                          todayTrace,
                          tokens,
                          strings,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary(
    List<AdaptiveMetricSpec> specs,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final chosenLabels = <String>[];
    for (final spec in specs) {
      for (final opt in spec.options) {
        if (AdaptiveTrackingEngine.isOptionSelected(spec.kind, opt, trace)) {
          chosenLabels.add(
            '${spec.localizedClinicianLabel(strings)}: ${opt.localized(strings)}',
          );
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: tokens.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chosenLabels.isNotEmpty
                  ? chosenLabels.join(' · ')
                  : strings.ritualCompletedSummaryTitle,
              style: LabTheme.textStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock(
    AdaptiveMetricSpec spec,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.localizedTitle(strings),
          style: LabTheme.textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        switch (spec.style) {
          AdaptiveMetricVisualStyle.sleepArc =>
            _buildSleepArcWidget(spec, trace, tokens, strings),
          AdaptiveMetricVisualStyle.energyBattery =>
            _buildBatteryBarsWidget(spec, trace, tokens, strings),
          AdaptiveMetricVisualStyle.bubbleMeter =>
            _buildBubbleScaleWidget(spec, trace, tokens, strings),
          AdaptiveMetricVisualStyle.pillRow =>
            _buildVisualSparksWidget(spec, trace, tokens, strings),
        },
      ],
    );
  }

  Widget _buildSleepArcWidget(
    AdaptiveMetricSpec spec,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    var activeIdx = -1;
    for (var i = 0; i < spec.options.length; i++) {
      if (AdaptiveTrackingEngine.isOptionSelected(
        spec.kind,
        spec.options[i],
        trace,
      )) {
        activeIdx = i;
        break;
      }
    }
    final fillRatio = activeIdx < 0 ? 0.0 : (activeIdx + 1) / spec.options.length;
    final arcColor = activeIdx <= 1 && activeIdx >= 0
        ? MindTokens.moodRestless
        : MindTokens.moodCalm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 7,
              width: constraints.maxWidth,
              color: tokens.surface2,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: (constraints.maxWidth * fillRatio).clamp(0.0, constraints.maxWidth),
                height: 7,
                decoration: BoxDecoration(
                  color: arcColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in spec.options)
              _tactileSegmentTile(
                spec: spec,
                opt: opt,
                selected: AdaptiveTrackingEngine.isOptionSelected(
                  spec.kind,
                  opt,
                  trace,
                ),
                leading: Icon(
                  Icons.bedtime_outlined,
                  size: 16,
                  color: AdaptiveTrackingEngine.isOptionSelected(
                    spec.kind,
                    opt,
                    trace,
                  )
                      ? tokens.onPrimary
                      : tokens.ink2,
                ),
                tokens: tokens,
                strings: strings,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatteryBarsWidget(
    AdaptiveMetricSpec spec,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in spec.options)
          _tactileSegmentTile(
            spec: spec,
            opt: opt,
            selected: AdaptiveTrackingEngine.isOptionSelected(
              spec.kind,
              opt,
              trace,
            ),
            leading: _SignalBars(
              barsFilled: opt.level1to4,
              totalBars: 4,
              color: AdaptiveTrackingEngine.isOptionSelected(
                spec.kind,
                opt,
                trace,
              )
                  ? tokens.onPrimary
                  : tokens.primary,
              mutedColor: tokens.lineStrong,
            ),
            tokens: tokens,
            strings: strings,
          ),
      ],
    );
  }

  Widget _buildBubbleScaleWidget(
    AdaptiveMetricSpec spec,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in spec.options)
          _tactileSegmentTile(
            spec: spec,
            opt: opt,
            selected: AdaptiveTrackingEngine.isOptionSelected(
              spec.kind,
              opt,
              trace,
            ),
            leading: _BubbleDot(
              level: opt.level1to4,
              selected: AdaptiveTrackingEngine.isOptionSelected(
                spec.kind,
                opt,
                trace,
              ),
              tokens: tokens,
            ),
            tokens: tokens,
            strings: strings,
          ),
      ],
    );
  }

  Widget _buildVisualSparksWidget(
    AdaptiveMetricSpec spec,
    MindTraceModel? trace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    IconData iconFor(AdaptiveMetricOption opt) {
      return switch (opt.key) {
        'walk' => Icons.directions_walk_rounded,
        'talked' => Icons.forum_outlined,
        'heavy_work' => Icons.work_outline_rounded,
        'rest' => Icons.spa_outlined,
        'yes' => Icons.schedule_rounded,
        'partly' => Icons.timelapse_rounded,
        'no' => Icons.shuffle_rounded,
        'passed' => Icons.air_rounded,
        'paused' => Icons.pause_circle_outline_rounded,
        'acted' => Icons.replay_rounded,
        _ => Icons.circle_outlined,
      };
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in spec.options)
          _tactileSegmentTile(
            spec: spec,
            opt: opt,
            selected: AdaptiveTrackingEngine.isOptionSelected(
              spec.kind,
              opt,
              trace,
            ),
            leading: Icon(
              iconFor(opt),
              size: 16,
              color: AdaptiveTrackingEngine.isOptionSelected(
                spec.kind,
                opt,
                trace,
              )
                  ? tokens.onPrimary
                  : tokens.ink2,
            ),
            tokens: tokens,
            strings: strings,
          ),
      ],
    );
  }

  Widget _tactileSegmentTile({
    required AdaptiveMetricSpec spec,
    required AdaptiveMetricOption opt,
    required bool selected,
    required Widget leading,
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final label = opt.localized(strings);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MindPressable(
        key: ValueKey<String>(opt.widgetKey),
        onPressed: () {
          HapticFeedback.selectionClick();
          widget.onUpdateTrace(
            (existing) => AdaptiveTrackingEngine.applySelection(
              _baseOrNew(existing),
              spec.kind,
              opt,
              strings: strings,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? tokens.primary : tokens.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tokens.primary : tokens.lineStrong,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LabTheme.textStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? tokens.onPrimary : tokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({
    required this.barsFilled,
    required this.totalBars,
    required this.color,
    required this.mutedColor,
  });

  final int barsFilled;
  final int totalBars;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= totalBars; i++) ...[
          if (i > 1) const SizedBox(width: 2),
          Container(
            width: 3,
            height: 5.0 + (i * 2.5),
            decoration: BoxDecoration(
              color: i <= barsFilled ? color : mutedColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

class _BubbleDot extends StatelessWidget {
  const _BubbleDot({
    required this.level,
    required this.selected,
    required this.tokens,
  });

  final int level;
  final bool selected;
  final MindTokens tokens;

  @override
  Widget build(BuildContext context) {
    final size = 6.0 + (level.clamp(1, 4) * 2.0);
    final fill = selected
        ? tokens.onPrimary
        : (level <= 1
              ? MindTokens.moodCalm
              : (level == 2
                    ? MindTokens.moodGood
                    : (level == 3
                          ? MindTokens.moodRestless
                          : MindTokens.moodFrustrated)));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
      ),
    );
  }
}
