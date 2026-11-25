import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

/// Token-driven semantic pill/badge. Zero emojis; pairs icon or clear text.
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  color: defaultFg,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: label,
          child: badge,
        ),
      );
    }

    return badge;
  }
}
