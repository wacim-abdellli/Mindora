import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../clinician/domain/post_visit_focus_model.dart';
import '../../../mind_trace/domain/daily_context_tags.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../track/presentation/widgets/track_mood_utils.dart';

/// Streamlined, calm 1-tap bridge shown above an empty Talk sanctuary when
/// the user checked in today or has an active care-team focus note.
class CompanionContextBridgeCard extends StatelessWidget {
  const CompanionContextBridgeCard({
    super.key,
    required this.todayTrace,
    required this.focusPlan,
    required this.strings,
    required this.onStartPrompt,
    required this.onOpenSettleSupport,
  });

  final MindTraceModel? todayTrace;
  final PostVisitFocusPlan? focusPlan;
  final AppStrings strings;
  final ValueChanged<String> onStartPrompt;
  final VoidCallback onOpenSettleSupport;

  FocusGoalItem? get _nextFocusItem {
    final plan = focusPlan;
    if (plan == null || plan.isDismissed) return null;
    for (final item in plan.focusItems) {
      if (!item.isCompleted && item.title.trim().isNotEmpty) {
        return item;
      }
    }
    if (plan.observationCue.trim().isNotEmpty) {
      return FocusGoalItem(
        id: 'obs_cue',
        title: plan.observationCue.trim(),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final trace = todayTrace;
    final focusItem = _nextFocusItem;
    if (trace == null && focusItem == null) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final moodKey = trace?.overallMood ?? 'calm';
    final moodColor = trace != null
        ? MindTokens.moodColor(AppMood.fromKey(moodKey))
        : tokens.m1;
    final moodLabel = trace != null
        ? trackMoodLabel(trace.overallMood, strings)
        : '';
    final tagLabels = trace == null
        ? const <String>[]
        : trace.contextTags
            .take(2)
            .map((k) => DailyContextTags.localizedLabel(k, strings))
            .where((l) => l.trim().isNotEmpty)
            .toList();

    return MindCard(
      key: const ValueKey('companion-checkin-bridge-card'),
      variant: MindCardVariant.tint,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trace != null) ...[
            MindPressable(
              key: const ValueKey('companion-bridge-unpack-btn'),
              semanticLabel: strings.companionBridgeUnpackBtn,
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                HapticFeedback.lightImpact();
                onStartPrompt(
                  strings.companionBridgePrompt(
                    moodLabel: moodLabel,
                    intensity: trace.moodIntensity,
                    tagLabels: tagLabels,
                    note: trace.journalText ?? '',
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: moodColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.talkContextRibbonCheckIn(
                              moodLabel,
                              trace.moodIntensity,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: tokens.ink,
                            ),
                          ),
                          if ((trace.journalText ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              trace.journalText!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: tokens.ink,
                    ),
                  ],
                ),
              ),
            ),
            if (trace.moodIntensity >= 7) ...[
              const SizedBox(height: 8),
              MindPressable(
                key: const ValueKey('companion-bridge-settle-btn'),
                semanticLabel: strings.companionBridgeSettleFirstBtn,
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenSettleSupport();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air_rounded, size: 16, color: tokens.ink),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          strings.companionBridgeSettleFirstBtn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
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
            ],
          ],
          if (focusItem != null) ...[
            if (trace != null) const SizedBox(height: 8),
            MindPressable(
              key: const ValueKey('companion-bridge-focus-btn'),
              semanticLabel: strings.companionBridgeFocusChip(focusItem.title),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                HapticFeedback.selectionClick();
                onStartPrompt(
                  strings.companionBridgeFocusPrompt(focusItem.title),
                );
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 16,
                      color: tokens.m1,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.talkContextRibbonFocus(focusItem.title),
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
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: tokens.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
