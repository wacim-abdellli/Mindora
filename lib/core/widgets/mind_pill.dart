import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Reusable pill component for time selectors, category tags, and filter controls.
class MindPill extends StatelessWidget {
  const MindPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 13.0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final activeBg = tokens.primary;
    final activeFg = tokens.onPrimary;
    final inactiveBg = tokens.surface2;
    final inactiveFg = tokens.ink;

    return MindPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              border: Border.all(
                color: isSelected ? activeBg : tokens.line,
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? tokens.primaryButtonShadows
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: fontSize + 1,
                    color: isSelected ? activeFg : inactiveFg,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? activeFg : inactiveFg,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
