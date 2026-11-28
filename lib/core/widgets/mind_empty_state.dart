import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_button.dart';

/// Calm, structured empty state with clear icon, headline, guidance, and CTA.
class MindEmptyState extends StatelessWidget {
  const MindEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 20 : 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 52 : 60,
                height: compact ? 52 : 60,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.line, width: 1.0),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: compact ? 24 : 28,
                  color: tokens.ink2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 14.5,
                  height: 1.5,
                  color: tokens.ink2,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                MindButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: MindButtonVariant.primary,
                ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: 10),
                MindButton(
                  text: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: MindButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Calm, non-technical error recovery view with retry affordance.
class MindErrorState extends StatelessWidget {
  const MindErrorState({
    super.key,
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tokens.safetySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.dangerBorder, width: 1.0),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 26, color: tokens.safety),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 14.5,
                  height: 1.5,
                  color: tokens.ink2,
                ),
              ),
              if (retryLabel != null && onRetry != null) ...[
                const SizedBox(height: 18),
                MindButton(
                  text: retryLabel!,
                  onPressed: onRetry,
                  variant: MindButtonVariant.secondary,
                  leadingIcon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
