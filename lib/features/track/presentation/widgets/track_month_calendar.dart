import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mood_emblem.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import 'track_mood_utils.dart';

/// Calming open circular monthly calendar with subtle mood halos, dot leading
/// anchors, and day-filter selection strip shared across Track & Progress views.
class TrackMonthCalendar extends StatelessWidget {
  const TrackMonthCalendar({
    super.key,
    required this.month,
    required this.traces,
    required this.selectedDateKey,
    required this.strings,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.canGoNextMonth,
    required this.onSelectDateKey,
    this.onInspectTrace,
  });

  final DateTime month;
  final List<MindTraceModel> traces;
  final String? selectedDateKey;
  final AppStrings strings;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoNextMonth;
  final ValueChanged<String?> onSelectDateKey;
  final ValueChanged<MindTraceModel>? onInspectTrace;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset + 6) ~/ 7) * 7;
    final now = DateTime.now();

    final loggedByDayKey = <String, MindTraceModel>{};
    for (final t in traces) {
      loggedByDayKey.putIfAbsent(t.dateKey, () => t);
    }

    final selectedTrace =
        selectedDateKey != null ? loggedByDayKey[selectedDateKey] : null;
    final weekdays = strings.weekdayShortLabels;

    return MindCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${strings.monthName(month.month)} ${month.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPreviousMonth,
                icon: Icon(
                  isRtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 22,
                  color: tokens.ink2,
                ),
                tooltip: strings.previousMonthTooltip,
              ),
              IconButton(
                onPressed: canGoNextMonth ? onNextMonth : null,
                icon: Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: canGoNextMonth
                      ? tokens.ink2
                      : tokens.ink3.withValues(alpha: 0.35),
                ),
                tooltip: strings.nextMonthTooltip,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.calendarNoBreaksNote,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset ||
                  index >= firstDayOffset + daysInMonth) {
                return Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.line.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }

              final day = index - firstDayOffset + 1;
              final dayKey =
                  '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final matchedTrace = loggedByDayKey[dayKey];
              final isLogged = matchedTrace != null;
              final isSelected = selectedDateKey == dayKey;
              final isToday = day == now.day &&
                  month.month == now.month &&
                  month.year == now.year;

              final mood = isLogged
                  ? AppMood.fromKey(matchedTrace.overallMood)
                  : null;
              final moodColor = mood != null
                  ? MindTokens.moodColor(mood)
                  : tokens.m1;
              final moodFill = isLogged
                  ? tokens.moodDayColor(moodColor, matchedTrace.moodIntensity)
                  : tokens.surface2;

              Color circleBg;
              Color textColor;
              Border? circleBorder;

              if (isSelected) {
                circleBg = isLogged ? moodColor : tokens.ink;
                textColor = tokens.onMood;
                circleBorder = null;
              } else if (isLogged) {
                circleBg = moodFill;
                textColor = tokens.ink;
                circleBorder = Border.all(
                  color: moodColor.withValues(alpha: isToday ? 0.9 : 0.45),
                  width: isToday ? 1.8 : 1.2,
                );
              } else if (isToday) {
                circleBg = Colors.transparent;
                textColor = tokens.ink;
                circleBorder = Border.all(color: tokens.m1, width: 1.6);
              } else {
                // Open typographic calendar field — no rectangular grid cages.
                circleBg = Colors.transparent;
                textColor = tokens.ink2;
                circleBorder = null;
              }

              return Center(
                child: MindPressable(
                    borderRadius: BorderRadius.circular(999),
                    semanticLabel:
                        '$day ${strings.monthName(month.month)}${isLogged ? ' · ${trackMoodLabel(matchedTrace.overallMood, strings)}' : ''}',
                    onPressed: () {
                      onSelectDateKey(isSelected ? null : dayKey);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: circleBg,
                        shape: BoxShape.circle,
                        border: circleBorder,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: (isLogged || isToday || isSelected)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: textColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (isLogged && !isSelected) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: moodColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ),
              );
            },
          ),
        ),
          if (selectedDateKey != null) ...[
            const SizedBox(height: 12),
            _SelectedDayBanner(
              tokens: tokens,
              strings: strings,
              dateKey: selectedDateKey!,
              trace: selectedTrace,
              onInspectTrace: onInspectTrace,
              onClear: () => onSelectDateKey(null),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedDayBanner extends StatelessWidget {
  const _SelectedDayBanner({
    required this.tokens,
    required this.strings,
    required this.dateKey,
    required this.trace,
    required this.onClear,
    this.onInspectTrace,
  });

  final MindTokens tokens;
  final AppStrings strings;
  final String dateKey;
  final MindTraceModel? trace;
  final VoidCallback onClear;
  final ValueChanged<MindTraceModel>? onInspectTrace;

  @override
  Widget build(BuildContext context) {
    final hasTrace = trace != null;
    final moodColor = hasTrace
        ? MindTokens.moodColor(AppMood.fromKey(trace!.overallMood))
        : tokens.ink2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          if (hasTrace) ...[
            MoodEmblem(
              moodKey: trace!.overallMood,
              size: 18,
              color: moodColor,
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: tokens.ink2,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hasTrace && onInspectTrace != null
                  ? () => onInspectTrace!(trace!)
                  : null,
              child: Text(
                hasTrace
                    ? '${strings.filteredByDateLabel(dateKey)} · ${trackMoodLabel(trace!.overallMood, strings)} (${trace!.moodIntensity}/10)'
                    : strings.filteredByDateLabel(dateKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MindPressable(
            onPressed: onClear,
            semanticLabel: strings.showAllEntriesBtn,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.line),
              ),
              alignment: Alignment.center,
              child: Text(
                strings.showAllEntriesBtn,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
