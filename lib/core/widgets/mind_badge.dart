import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Token-driven semantic pill/badge. Zero emojis; pairs icon or clear text.
///
/// Enforces the 12.0sp typography floor (never crushing via [FittedBox]) and
/// guarantees a minimum 48×48dp tap target with keyboard focus when interactive.
class MindBadge extends StatelessWidget {
  const MindBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final defaultBg = isSelected
        ? tokens.ink
        : (backgroundColor ?? tokens.surface2);
    final defaultFg = isSelected ? tokens.bg : (textColor ?? tokens.ink);
    final defaultBorder = isSelected
        ? Colors.transparent
        : (borderColor ?? tokens.line);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        border: Border.all(color: defaultBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: defaultFg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                color: defaultFg,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return MindPressable(
        onPressed: onTap,
        selected: isSelected,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: badge,
          ),
        ),
      );
    }

    return badge;
  }
}
