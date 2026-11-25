import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import '../../features/investigation/domain/label_type.dart';

/// Minimalist, accessible badge representing Fact, Assumption, or Interpretation.
///
/// Always pairs letter code, vector icon, and localized text label using [MindTokens].
class LabelBadge extends ConsumerWidget {
  const LabelBadge({
    super.key,
    required this.label,
    this.showText = true,
    this.compact = false,
  });

  final LabelType label;
  final bool showText;
  final bool compact;

  IconData _iconForLabel() {
    switch (label) {
      case LabelType.fact:
        return Icons.check_circle_outline_rounded;
      case LabelType.assumption:
        return Icons.help_outline_rounded;
      case LabelType.interpretation:
        return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final accentColor = tokens.labelColor(label);
    final bgColor = tokens.labelBackground(label);
    final borderColor = tokens.labelBorder(label);
    final localizedName = strings.localizedLabelName(label);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForLabel(), size: compact ? 12 : 13.5, color: accentColor),
          const SizedBox(width: 4),
          Text(
            label.letter,
            style: TextStyle(
              fontFamily: LabTheme.fontFamily,
              fontFamilyFallback: LabTheme.fontFallback,
              fontSize: compact ? 12.0 : 12.5,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              localizedName,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                fontSize: compact ? 12.0 : 12.5,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
