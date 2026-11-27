import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../domain/forensic_loop_model.dart';

/// Connected 4-node vertical rail mapping context/triggers, diurnal/affect
/// patterns, cognitive thought chains, and observed stabilizers.
///
/// Designed for zero horizontal clipping down to 320px + 1.35x Arabic RTL.
class ForensicLoopMapCard extends StatelessWidget {
  const ForensicLoopMapCard({
    super.key,
    required this.loop,
    required this.strings,
  });

  final ForensicLoopLink loop;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (!loop.hasSufficientSignal) return const SizedBox.shrink();

    final tokens = context.tokens;
    final nodes = <_LoopNode>[
      if (loop.recurringContextOrTrigger != null)
        _LoopNode(
          title: strings.forensicLoopNodeTrigger,
          body: loop.recurringContextOrTrigger!,
          dotColor: tokens.ink2,
          icon: Icons.bolt_outlined,
        ),
      if (loop.somaticAffectPattern != null)
        _LoopNode(
          title: strings.forensicLoopNodeAffect,
          body: loop.somaticAffectPattern!,
          dotColor: tokens.m2,
          icon: Icons.waves_rounded,
        ),
      if (loop.recurringThoughtTheme != null)
        _LoopNode(
          title: strings.forensicLoopNodeThought,
          body: loop.recurringThoughtTheme!,
          dotColor: tokens.ink,
          icon: Icons.psychology_outlined,
          badgeText: loop.thoughtLabel != null
              ? '[${loop.thoughtLabel!.letter}] ${strings.localizedLabelName(loop.thoughtLabel!)}'
              : null,
        ),
      if (loop.observedStabilizer != null)
        _LoopNode(
          title: strings.forensicLoopNodeStabilizer,
          body: loop.observedStabilizer!,
          dotColor: tokens.m1,
          icon: Icons.spa_outlined,
        ),
    ];

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route_outlined,
                size: 16,
                color: tokens.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.forensicLoopMapTitle,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindBadge(
                label: strings.forensicLoopNodesBadge(loop.populatedNodeCount),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.forensicLoopMapSub,
            style: TextStyle(fontSize: 12, color: tokens.ink3, height: 1.35),
          ),
          const SizedBox(height: 14),
          ...List.generate(nodes.length, (i) {
            final node = nodes[i];
            final isLast = i == nodes.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: node.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: tokens.lineStrong,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(tokens.inputRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(node.icon, size: 14, color: tokens.ink2),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    node.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              node.body,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                                height: 1.35,
                              ),
                            ),
                            if (node.badgeText != null) ...[
                              const SizedBox(height: 6),
                              MindBadge(
                                label: node.badgeText!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(
            strings.forensicLoopDisclaimer,
            style: TextStyle(
              fontSize: 12.0,
              color: tokens.ink3,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopNode {
  const _LoopNode({
    required this.title,
    required this.body,
    required this.dotColor,
    required this.icon,
    this.badgeText,
  });

  final String title;
  final String body;
  final Color dotColor;
  final IconData icon;
  final String? badgeText;
}
