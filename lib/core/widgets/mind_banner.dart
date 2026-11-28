import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_button.dart';

enum MindBannerTone { neutral, info, success, warning, safety }

/// Token-driven inline status or clinical notice banner.
///
/// Always pairs an icon with plain text (never color alone), honors RTL
/// directional spacing, and meets WCAG 2.1 AA+ contrast in both themes.
class MindBanner extends StatelessWidget {
  const MindBanner({
    super.key,
    required this.body,
    this.title,
    this.tone = MindBannerTone.neutral,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.compact = false,
  });

  final String? title;
  final String body;
  final MindBannerTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (Color bg, Color border, Color accent, IconData defaultIcon) =
        switch (tone) {
      MindBannerTone.neutral => (
          tokens.surface2,
          tokens.line,
          tokens.ink2,
          Icons.info_outline_rounded,
        ),
      MindBannerTone.info => (
          tokens.infoSoft,
          tokens.info.withValues(alpha: 0.30),
          tokens.info,
          Icons.info_outline_rounded,
        ),
      MindBannerTone.success => (
          tokens.successSoft,
          tokens.success.withValues(alpha: 0.30),
          tokens.success,
          Icons.check_circle_outline_rounded,
        ),
      MindBannerTone.warning => (
          tokens.warningSoft,
          tokens.warning.withValues(alpha: 0.32),
          tokens.warning,
          Icons.warning_amber_rounded,
        ),
      MindBannerTone.safety => (
          tokens.safetySoft,
          tokens.dangerBorder,
          tokens.safety,
          Icons.health_and_safety_outlined,
        ),
    };

    final titleColor = tone == MindBannerTone.safety ? tokens.safety : tokens.ink;

    return Semantics(
      container: true,
      liveRegion: tone == MindBannerTone.safety || tone == MindBannerTone.warning,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          compact ? 12 : 14,
          compact ? 10 : 12,
          onDismiss != null ? 6 : (compact ? 12 : 14),
          compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.inputRadius),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(icon ?? defaultIcon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title!.trim().isNotEmpty) ...[
                        Text(
                          title!,
                          style: TextStyle(
                            fontFamily: LabTheme.fontFamily,
                            fontFamilyFallback: LabTheme.fontFallback,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        body,
                        style: TextStyle(
                          fontFamily: LabTheme.fontFamily,
                          fontFamilyFallback: LabTheme.fontFallback,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded, size: 18, color: tokens.ink2),
                  ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MindButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  size: MindButtonSize.sm,
                  variant: tone == MindBannerTone.safety
                      ? MindButtonVariant.danger
                      : MindButtonVariant.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
