import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../domain/clarity_anchor_model.dart';

/// Scannable 3-line Pocket Clarity Anchor card distilling a cognitive
/// deconstruction into Observed Fact -> Mind's Jump -> Grounded Perspective.
///
/// Zero emojis, 100% MindTokens, and overflow-safe at 320px + 1.35x AR RTL.
class ClarityAnchorCard extends StatelessWidget {
  const ClarityAnchorCard({
    super.key,
    required this.anchor,
    required this.strings,
    this.compact = false,
    this.onTap,
  });

  final ClarityAnchorModel anchor;
  final AppStrings strings;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final card = MindCard(
      key: ValueKey('clarity-anchor-card-${anchor.caseId}'),
      variant: MindCardVariant.tint,
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.anchor_rounded, size: 15, color: tokens.m1),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  compact
                      ? anchor.title
                      : strings.clarityAnchorTitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: compact ? 13 : 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: (compact || strings.isArabic) ? 0 : 0.7,
                    color: compact ? tokens.ink : tokens.ink2,
                  ),
                ),
              ),
              if (anchor.isPrivate) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_rounded, size: 13, color: tokens.safety),
              ],
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              strings.clarityAnchorSub,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: tokens.ink3,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (anchor.observedFact != null)
            _buildRailLine(
              tokens: tokens,
              accent: MindTokens.moodAnxious,
              label: strings.clarityAnchorFactLabel,
              value: anchor.observedFact!,
              maxLines: compact ? 2 : 3,
            ),
          if (anchor.mindsJump != null) ...[
            const SizedBox(height: 8),
            _buildRailLine(
              tokens: tokens,
              accent: MindTokens.moodRestless,
              label: strings.clarityAnchorJumpLabel,
              value: anchor.mindsJump!,
              maxLines: compact ? 2 : 3,
            ),
          ],
          if (anchor.groundedPerspective != null) ...[
            const SizedBox(height: 8),
            _buildRailLine(
              tokens: tokens,
              accent: MindTokens.moodCalm,
              label: strings.clarityAnchorGroundedLabel,
              value: anchor.groundedPerspective!,
              maxLines: compact ? 2 : 4,
              emphasized: true,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return MindPressable(
      semanticLabel: '${strings.clarityAnchorTitle}: ${anchor.title}',
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      onPressed: onTap,
      child: card,
    );
  }

  Widget _buildRailLine({
    required MindTokens tokens,
    required Color accent,
    required String label,
    required String value,
    required int maxLines,
    bool emphasized = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: emphasized
            ? tokens.selectedTintFor(accent)
            : tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasized ? accent.withValues(alpha: 0.45) : tokens.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(13, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
                      color: tokens.ink,
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: 3.5,
              child: ColoredBox(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
