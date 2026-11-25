import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

enum MindButtonVariant { primary, secondary, soft, ghost, danger }

/// Accessible, minimum 48×48px tap target button driven strictly by [MindTokens].
class MindButton extends StatelessWidget {
  const MindButton({
    super.key,
    required this.text,
    this.subText,
    this.onPressed,
    this.variant = MindButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String text;
  final String? subText;
  final VoidCallback? onPressed;
  final MindButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onPressed != null && !isLoading;

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
        fg = tokens.isDark ? tokens.bg : MindTokens.pureWhiteConstant;
        border = Colors.transparent;
        borderWidth = 1.0;
        shadows = const [];
    }

    final effectiveBg = enabled ? bg : bg.withValues(alpha: 0.45);
    final effectiveFg = enabled ? fg : fg.withValues(alpha: 0.45);

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
          Icon(leadingIcon, size: 17, color: effectiveFg),
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
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
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
          Icon(trailingIcon, size: 18, color: effectiveFg),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: variant == MindButtonVariant.primary ? 56 : 48,
        minWidth: isFullWidth ? double.infinity : 48,
      ),
      child: MindPressable(
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        semanticLabel: text,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            border: Border.all(color: border, width: borderWidth),
            boxShadow: shadows,
          ),
          child: content,
        ),
      ),
    );
  }
}
