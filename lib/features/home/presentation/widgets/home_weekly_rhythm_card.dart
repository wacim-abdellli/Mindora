import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

/// Non-punitive 7-day observation continuity strip rendered on [HomeScreen].
///
/// Maps the trailing 7 calendar days (ending today) against real [MindTraceModel]
/// records so users can glance at their rhythm and jump directly to a logged day
/// without streak guilt.
class HomeWeeklyRhythmCard extends StatelessWidget {
  const HomeWeeklyRhythmCard({
    super.key,
    required this.traces,
    required this.tokens,
    required this.strings,
    required this.isDark,
    required this.getMoodColor,
    required this.getMoodLabel,
    this.onDayTap,
  });

  final List<MindTraceModel> traces;
  final MindTokens tokens;
  final AppStrings strings;
  final bool isDark;
  final Color Function(String key) getMoodColor;
  final String Function(String key, AppStrings strings) getMoodLabel;
  final void Function(DateTime day, MindTraceModel? trace)? onDayTap;

  String _dateKeyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final trailingDays = List<DateTime>.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    final byDateKey = <String, MindTraceModel>{};
    for (final t in traces) {
      byDateKey.putIfAbsent(t.dateKey, () => t);
    }

    int observedCount = 0;
    for (final day in trailingDays) {
      if (byDateKey.containsKey(_dateKeyFor(day))) {
        observedCount++;
      }
    }

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.thisWeekTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  border: Border.all(color: tokens.line),
                ),
                child: Text(
                  strings.daysThisWeekCount(observedCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: observedCount > 0 ? tokens.ink : tokens.ink2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(trailingDays.length, (i) {
              final day = trailingDays[i];
              final isToday = i == 6;
              final trace = byDateKey[_dateKeyFor(day)];
              final weekdayChar = strings.weekdayInitial(day.weekday);

              final Color nodeBg;
              final Color nodeBorder;
              final double nodeBorderWidth;
              if (trace != null) {
                final mood = AppMood.fromKey(trace.overallMood);
                final moodColor = MindTokens.moodColor(mood);
                nodeBg = tokens.moodDayColor(moodColor, trace.moodIntensity);
                nodeBorder = isToday ? tokens.ink : moodColor;
                nodeBorderWidth = isToday ? 2.0 : 1.3;
              } else {
                nodeBg = tokens.surface2;
                nodeBorder = isToday ? tokens.m1 : tokens.line;
                nodeBorderWidth = isToday ? 1.8 : 1.0;
              }

              final semanticLabel = trace != null
                  ? '${strings.weekdayName(day.weekday)}: ${getMoodLabel(trace.overallMood, strings)} (${trace.moodIntensity}/10)'
                  : strings.weekdayName(day.weekday);

              return Expanded(
                child: Semantics(
                  button: onDayTap != null,
                  label: semanticLabel,
                  child: MindPressable(
                    enabled: onDayTap != null,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onDayTap != null
                        ? () {
                            HapticFeedback.selectionClick();
                            onDayTap!(day, trace);
                          }
                        : null,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: nodeBg,
                              border: Border.all(
                                color: nodeBorder,
                                width: nodeBorderWidth,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: trace != null
                                ? MoodFace(
                                    mood: AppMood.fromKey(trace.overallMood),
                                    size: 28,
                                  )
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isToday
                                          ? tokens.primary
                                          : tokens.ink3.withValues(alpha: 0.45),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            weekdayChar,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w600,
                              color: isToday ? tokens.ink : tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            strings.thisWeekSupportiveCaption,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.35,
              color: tokens.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
