import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import 'recovery_ledger_model.dart';

enum DiscoveryMilestoneId {
  firstTrace,
  nuanceExplorer,
  intradayObserver,
  stabilizerSpotted,
  sevenDays,
}

@immutable
class DiscoveryMilestone {
  const DiscoveryMilestone({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isUnlocked,
  });

  final DiscoveryMilestoneId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isUnlocked;
}

@immutable
class DiscoveryMilestonesSummary {
  const DiscoveryMilestonesSummary({
    required this.items,
    required this.distinctDays,
  });

  final List<DiscoveryMilestone> items;
  final int distinctDays;

  int get totalCount => items.length;
  int get unlockedCount => items.where((m) => m.isUnlocked).length;
}

/// Computes cumulative, strictly non-punitive self-discovery milestones.
///
/// Missed days never reset or penalize unlocked progress — every milestone tracks
/// cumulative understanding rather than brittle consecutive streaks.
class DiscoveryMilestonesService {
  const DiscoveryMilestonesService._();

  static DiscoveryMilestonesSummary compute({
    required List<MindTraceModel> traces,
    required RecoveryLedger ledger,
    required AppStrings strings,
  }) {
    final dayCounts = <String, int>{};
    final nuancedSet = <String>{};

    for (final t in traces) {
      dayCounts[t.dateKey] = (dayCounts[t.dateKey] ?? 0) + 1;
      for (final f in t.nuancedEmotions) {
        final clean = f.trim().toLowerCase();
        if (clean.isNotEmpty) nuancedSet.add(clean);
      }
      if (t.selectedEmotions.length > 1) {
        for (final f in t.selectedEmotions.skip(1)) {
          final clean = f.trim().toLowerCase();
          if (clean.isNotEmpty) nuancedSet.add(clean);
        }
      }
    }

    final distinctDays = dayCounts.length;
    final hasIntraday = dayCounts.values.any((count) => count >= 2);

    final items = <DiscoveryMilestone>[
      DiscoveryMilestone(
        id: DiscoveryMilestoneId.firstTrace,
        title: strings.milestoneFirstTitle,
        subtitle: strings.milestoneFirstSub,
        icon: Icons.water_drop_outlined,
        isUnlocked: traces.isNotEmpty,
      ),
      DiscoveryMilestone(
        id: DiscoveryMilestoneId.nuanceExplorer,
        title: strings.milestoneNuanceTitle,
        subtitle: strings.milestoneNuanceSub,
        icon: Icons.palette_outlined,
        isUnlocked: nuancedSet.length >= 3,
      ),
      DiscoveryMilestone(
        id: DiscoveryMilestoneId.intradayObserver,
        title: strings.milestoneIntradayTitle,
        subtitle: strings.milestoneIntradaySub,
        icon: Icons.schedule_rounded,
        isUnlocked: hasIntraday,
      ),
      DiscoveryMilestone(
        id: DiscoveryMilestoneId.stabilizerSpotted,
        title: strings.milestoneStabilizerTitle,
        subtitle: strings.milestoneStabilizerSub,
        icon: Icons.healing_outlined,
        isUnlocked: ledger.hasEvidence,
      ),
      DiscoveryMilestone(
        id: DiscoveryMilestoneId.sevenDays,
        title: strings.milestoneSevenDaysTitle,
        subtitle: strings.milestoneSevenDaysSub,
        icon: Icons.auto_graph_rounded,
        isUnlocked: distinctDays >= 7,
      ),
    ];

    return DiscoveryMilestonesSummary(
      items: items,
      distinctDays: distinctDays,
    );
  }
}
