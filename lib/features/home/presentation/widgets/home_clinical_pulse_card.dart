import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../mind_trace/domain/daily_context_tags.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../onboarding/domain/app_personalization_engine.dart';

/// Time-of-day adaptive clinical daily pulse card for `Today` ([HomeScreen]).
///
/// Captures high-value longitudinal markers prized by psychiatrists (sleep
/// duration & quality, energy/activation, stress load, stressors/stabilizers,
/// and optional routine adherence) in 1–2 taps with ZERO typing, auto-saving
/// directly onto today's [MindTraceModel].
class HomeClinicalPulseCard extends StatelessWidget {
  const HomeClinicalPulseCard({
    super.key,
    required this.tokens,
    required this.strings,
    required this.plan,
    required this.todayTrace,
    required this.onUpdateTrace,
    this.overrideHour,
  });

  final MindTokens tokens;
  final AppStrings strings;
  final AppPersonalizationPlan plan;
  final MindTraceModel? todayTrace;
  final Future<void> Function(MindTraceModel Function(MindTraceModel? existing) updater)
  onUpdateTrace;
  final int? overrideHour;

  bool get _isMorning {
    final hour = overrideHour ?? DateTime.now().hour;
    return hour >= 5 && hour < 14;
  }

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

  int _completedCount() {
    final t = todayTrace;
    if (t == null) return 0;
    var count = 0;
    if (t.sleepHours != null) count++;
    if (_isMorning) {
      if (t.energyLevel != null) count++;
    } else {
      if (t.anxietyLevel != null) count++;
      if ((t.behavioralResponse ?? '').trim().isNotEmpty ||
          t.contextTags.isNotEmpty) {
        count++;
      }
    }
    if (plan.showRoutineAnchorQuestion &&
        (t.dynamicAnswers['routine_adherence'] ?? '').isNotEmpty) {
      count++;
    }
    return count;
  }

  int _targetCount() {
    var total = _isMorning ? 2 : 3;
    if (plan.showRoutineAnchorQuestion) total++;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Minimal exploration users only see clinical pulse if they already started filling details or explicitly enabled Doctor Prep.
    if (plan.isMinimalExplorationMode &&
        todayTrace?.sleepHours == null &&
        todayTrace?.energyLevel == null &&
        todayTrace?.anxietyLevel == null) {
      return const SizedBox.shrink();
    }

    final completed = _completedCount();
    final total = _targetCount();
    final isComplete = completed >= total;

    return MindCard(
      key: const ValueKey('home-clinical-pulse-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _isMorning
                    ? Icons.wb_twilight_rounded
                    : Icons.nights_stay_outlined,
                size: 20,
                color: tokens.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMorning
                          ? strings.morningPulseTitle
                          : strings.eveningPulseTitle,
                      style: LabTheme.textStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.pulseForYouAndDoctorSub,
                      style: LabTheme.textStyle(
                        fontSize: 13.0,
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MindBadge(
                icon: isComplete ? Icons.check_circle_rounded : null,
                label: isComplete ? strings.doneBtn : '$completed/$total',
                backgroundColor: isComplete ? tokens.primary : tokens.surface2,
                textColor: isComplete ? tokens.onPrimary : tokens.ink2,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isMorning) ...[
            _buildSleepHoursQuestion(),
            if (todayTrace?.sleepHours != null) ...[
              const SizedBox(height: 14),
              _buildSleepQualityQuestion(),
            ],
            const SizedBox(height: 16),
            _buildEnergyQuestion(),
          ] else ...[
            _buildStressQuestion(),
            if (todayTrace?.sleepHours == null) ...[
              const SizedBox(height: 16),
              _buildSleepHoursQuestion(),
            ],
            const SizedBox(height: 16),
            _buildWhatShapedTodaySection(),
          ],

          if (plan.showRoutineAnchorQuestion) ...[
            const SizedBox(height: 16),
            _buildRoutineAnchorQuestion(),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepHoursQuestion() {
    final current = todayTrace?.sleepHours;
    final options = <(String key, String label, double hours, bool regular)>[
      ('lt5', strings.sleepLt5h, 4.5, false),
      ('5to6', strings.sleep5to6h, 5.5, false),
      ('7to8', strings.sleep7to8h, 7.5, true),
      ('9plus', strings.sleep9plusH, 9.0, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.sleepHoursQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              _pulsePill(
                key: ValueKey<String>('pulse-sleep-${opt.$1}'),
                label: opt.$2,
                selected: current != null && (current - opt.$3).abs() < 0.4,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  final tags = List<String>.from(base.contextTags);
                  if (opt.$4) {
                    if (!tags.contains('sleep_consistent')) {
                      tags.add('sleep_consistent');
                    }
                  } else {
                    tags.remove('sleep_consistent');
                  }
                  return base.copyWith(
                    sleepHours: opt.$3,
                    contextTags: tags,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepQualityQuestion() {
    final current = todayTrace?.sleepQuality;
    final options = <(String key, String label, int quality)>[
      ('rested', strings.sleepRestedLabel, 5),
      ('woke', strings.sleepWokeUpLabel, 3),
      ('hard', strings.sleepHardLabel, 2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.sleepQualityQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              _pulsePill(
                key: ValueKey<String>('pulse-sleepq-${opt.$1}'),
                label: opt.$2,
                selected: current == opt.$3,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  return base.copyWith(
                    sleepQuality: opt.$3,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnergyQuestion() {
    final current = todayTrace?.energyLevel;
    final options = <(String key, String label, int level)>[
      ('drained', strings.energyDrainedLabel, 2),
      ('low', strings.energyLowLabel, 4),
      ('steady', strings.energySteadyLabel, 7),
      ('high', strings.energyHighLabel, 9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.morningEnergyQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              _pulsePill(
                key: ValueKey<String>('pulse-energy-${opt.$1}'),
                label: opt.$2,
                selected: current != null && (current - opt.$3).abs() <= 1,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  return base.copyWith(
                    energyLevel: opt.$3,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStressQuestion() {
    final current = todayTrace?.anxietyLevel;
    final options = <(String key, String label, int level)>[
      ('calm', strings.stressCalmLabel, 2),
      ('mild', strings.stressMildLabel, 4),
      ('heavy', strings.stressHeavyLabel, 7),
      ('overwhelmed', strings.stressOverwhelmedLabel, 9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.stressTodayQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              _pulsePill(
                key: ValueKey<String>('pulse-stress-${opt.$1}'),
                label: opt.$2,
                selected: current != null && (current - opt.$3).abs() <= 1,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  return base.copyWith(
                    anxietyLevel: opt.$3,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhatShapedTodaySection() {
    final currentTags = todayTrace?.contextTags ?? const <String>[];
    final currentHelper = todayTrace?.behavioralResponse?.trim() ?? '';

    const contextKeys = ['high_workload', 'late_caffeine_screens', 'social_connection'];
    final helpers = <(String key, String label, String? contextTag)>[
      ('walk', strings.helperWalk, 'physical_movement'),
      ('rest', strings.helperRest, null),
      ('breathe', strings.helperBreathing, null),
      ('talked', strings.helperTalked, 'social_connection'),
      ('quiet', strings.helperQuiet, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.whatShapedTodayQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tagKey in contextKeys)
              if (DailyContextTags.byKey(tagKey) != null)
                _pulsePill(
                  key: ValueKey<String>('pulse-tag-$tagKey'),
                  label: DailyContextTags.byKey(tagKey)!.localized(strings),
                  selected: currentTags.contains(tagKey),
                  onTap: () => onUpdateTrace((existing) {
                    final base = _baseOrNew(existing);
                    final nextTags = List<String>.from(base.contextTags);
                    if (nextTags.contains(tagKey)) {
                      nextTags.remove(tagKey);
                    } else {
                      nextTags.add(tagKey);
                    }
                    return base.copyWith(
                      contextTags: nextTags,
                      updatedAt: DateTime.now(),
                    );
                  }),
                ),
            for (final helper in helpers)
              _pulsePill(
                key: ValueKey<String>('pulse-help-${helper.$1}'),
                label: helper.$2,
                selected: currentHelper == helper.$2,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  final nextTags = List<String>.from(base.contextTags);
                  if (helper.$3 != null && !nextTags.contains(helper.$3)) {
                    nextTags.add(helper.$3!);
                  }
                  return base.copyWith(
                    behavioralResponse:
                        currentHelper == helper.$2 ? '' : helper.$2,
                    contextTags: nextTags,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineAnchorQuestion() {
    final current = todayTrace?.dynamicAnswers['routine_adherence'] ?? '';
    final options = <(String key, String label)>[
      ('yes', strings.routineYesLabel),
      ('partly', strings.routinePartlyLabel),
      ('no', strings.routineNoLabel),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle(strings.routineAnchorQuestion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              _pulsePill(
                key: ValueKey<String>('pulse-routine-${opt.$1}'),
                label: opt.$2,
                selected: current == opt.$1,
                onTap: () => onUpdateTrace((existing) {
                  final base = _baseOrNew(existing);
                  final nextDynamic = Map<String, String>.from(base.dynamicAnswers);
                  nextDynamic['routine_adherence'] = opt.$1;
                  final nextTags = List<String>.from(base.contextTags);
                  if (opt.$1 == 'yes') {
                    if (!nextTags.contains('routine_kept')) {
                      nextTags.add('routine_kept');
                    }
                  } else {
                    nextTags.remove('routine_kept');
                  }
                  return base.copyWith(
                    dynamicAnswers: nextDynamic,
                    contextTags: nextTags,
                    updatedAt: DateTime.now(),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _questionTitle(String text) {
    return Text(
      text,
      style: LabTheme.textStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: tokens.ink,
      ),
    );
  }

  Widget _pulsePill({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MindPressable(
        key: key,
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? tokens.primary : tokens.surface2,
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            border: Border.all(
              color: selected ? tokens.primary : tokens.lineStrong,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: tokens.onPrimary),
                const SizedBox(width: 6),
              ],
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
