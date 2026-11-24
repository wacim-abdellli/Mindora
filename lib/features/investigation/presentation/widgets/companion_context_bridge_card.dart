import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../clinician/domain/post_visit_focus_model.dart';
import '../../../mind_trace/domain/daily_context_tags.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../track/presentation/widgets/track_mood_utils.dart';

/// Optional, 1-tap context bridge shown at the top of an empty Companion
/// session whenever the user has logged a check-in today or has an active
/// clinician Post-Visit Focus item.
///
/// Strictly options-first: never auto-submits anything without an explicit tap,
/// routes prompts through the parent's safety-scanned send callback, and fits
/// cleanly on 320px + 1.35x Arabic RTL.
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
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trace != null) ...[
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moodColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.companionBridgeTitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: strings.isArabic ? 0 : 0.7,
                      color: tokens.ink2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.selectedTintFor(moodColor),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: moodColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '$moodLabel · ${trace.moodIntensity}/10',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (tagLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tagLabels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.ink2,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if ((trace.journalText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                trace.journalText!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  color: tokens.ink,
                ),
              ),
            ],
            const SizedBox(height: 12),
            MindButton(
              key: const ValueKey('companion-bridge-unpack-btn'),
              text: strings.companionBridgeUnpackBtn,
              variant: MindButtonVariant.primary,
              leadingIcon: Icons.auto_awesome_outlined,
              isFullWidth: true,
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
            ),
            if (trace.moodIntensity >= 7) ...[
              const SizedBox(height: 8),
              MindButton(
                key: const ValueKey('companion-bridge-settle-btn'),
                text: strings.companionBridgeSettleFirstBtn,
                variant: MindButtonVariant.soft,
                leadingIcon: Icons.air_rounded,
                isFullWidth: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenSettleSupport();
                },
              ),
            ],
          ],
          if (focusItem != null) ...[
            if (trace != null) const SizedBox(height: 10),
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
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                        strings.companionBridgeFocusChip(focusItem.title),
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
