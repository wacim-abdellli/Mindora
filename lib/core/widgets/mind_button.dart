import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

enum MindButtonVariant { primary, secondary, soft, ghost, danger }

enum MindButtonSize { sm, md, lg }

/// Accessible, minimum 48×48dp tap target button driven strictly by [MindTokens].
class MindButton extends StatelessWidget {
  const MindButton({
    super.key,
    required this.text,
    this.subText,
    this.onPressed,
    this.variant = MindButtonVariant.primary,
    this.size,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String text;
  final String? subText;
  final VoidCallback? onPressed;
  final MindButtonVariant variant;
  final MindButtonSize? size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onPressed != null && !isLoading;
    final resolvedSize = size ??
        (variant == MindButtonVariant.primary
            ? MindButtonSize.lg
            : MindButtonSize.md);

    final Color bg;
    final Color fg;
    final Color border;
    final double borderWidth;
    final List<BoxShadow> shadows;

    switch (variant) {
      case MindButtonVariant.primary:
        bg = tokens.primary;
        fg = tokens.onPrimary;
        border = Colors.transparent;
        borderWidth = 1.0;
        shadows = enabled ? tokens.primaryButtonShadows : const [];
      case MindButtonVariant.secondary:
        bg = tokens.surface;
        fg = tokens.ink;
        border = tokens.lineStrong;
        borderWidth = 1.2;
        shadows = const [];
      case MindButtonVariant.soft:
        bg = tokens.softButtonBg;
        fg = tokens.ink;
        border = tokens.softButtonBorder;
        borderWidth = 1.0;
        shadows = const [];
      case MindButtonVariant.ghost:
        bg = Colors.transparent;
        fg = tokens.ink;
        border = tokens.lineStrong;
        borderWidth = 1.5;
        shadows = const [];
      case MindButtonVariant.danger:
        bg = tokens.safety;
        fg = tokens.onSafety;
        border = Colors.transparent;
        borderWidth = 1.0;
        shadows = const [];
    }

    final isGhost = variant == MindButtonVariant.ghost;
    final effectiveBg = enabled
        ? bg
        : (isGhost ? Colors.transparent : tokens.disabledBg);
    final effectiveFg = enabled ? fg : tokens.disabledInk;
    final effectiveBorder = enabled ? border : tokens.line;

    final double minHeight;
    final EdgeInsetsGeometry buttonPadding;
    final double labelSize;
    final double iconSize;
    switch (resolvedSize) {
      case MindButtonSize.sm:
        minHeight = 48;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
        labelSize = 14.0;
        iconSize = 16.0;
      case MindButtonSize.md:
        minHeight = 48;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12);
        labelSize = 15.5;
        iconSize = 17.0;
      case MindButtonSize.lg:
        minHeight = 56;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
        labelSize = 15.5;
        iconSize = 18.0;
    }

    final semantic = subText != null && subText!.trim().isNotEmpty
        ? '$text. $subText'
        : text;

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize, color: effectiveFg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  color: effectiveFg,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subText != null)
                Text(
                  subText!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    color: effectiveFg.withValues(alpha: 0.84),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize + 1, color: effectiveFg),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
        minWidth: isFullWidth ? double.infinity : 48,
      ),
      child: MindPressable(
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        semanticLabel: semantic,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          padding: buttonPadding,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            border: Border.all(color: effectiveBorder, width: borderWidth),
            boxShadow: shadows,
          ),
          child: content,
        ),
      ),
    );
  }
}
