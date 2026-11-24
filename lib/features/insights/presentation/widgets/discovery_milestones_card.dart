import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../domain/discovery_milestones_model.dart';
import 'mood_aura_poster_sheet.dart';

/// Non-punitive cumulative self-discovery milestones + Mood Aura trigger card.
///
/// Safe at 320px + 1.35x Arabic RTL and strictly emoji-free.
class DiscoveryMilestonesCard extends StatelessWidget {
  const DiscoveryMilestonesCard({
    super.key,
    required this.traces,
    required this.summary,
    required this.strings,
  });

  final List<MindTraceModel> traces;
  final DiscoveryMilestonesSummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: tokens.m1),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.discoveryMilestonesTitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.7,
                    color: tokens.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindBadge(
                label: strings.discoveryBadgeCount(
                  summary.unlockedCount,
                  summary.totalCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.discoveryMilestonesSub,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: tokens.ink3,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in summary.items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: item.isUnlocked
                        ? tokens.selectedTintFor(tokens.m1)
                        : tokens.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isUnlocked ? tokens.m1 : tokens.line,
                      width: item.isUnlocked ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isUnlocked
                            ? Icons.check_circle_rounded
                            : item.icon,
                        size: 15,
                        color: item.isUnlocked ? tokens.m1 : tokens.ink3,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: item.isUnlocked
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: item.isUnlocked
                                    ? tokens.ink
                                    : tokens.ink2,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: tokens.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          MindButton(
            text: strings.openMoodAuraBtn,
            variant: MindButtonVariant.soft,
            leadingIcon: Icons.blur_circular_rounded,
            isFullWidth: true,
            onPressed: () => MoodAuraPosterSheet.show(
              context,
              traces: traces,
              summary: summary,
            ),
          ),
        ],
      ),
    );
  }
}
