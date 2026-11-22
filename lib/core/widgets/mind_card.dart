import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Visual variant for [MindCard].
enum MindCardVariant {
  /// Standard raised card (`surface` fill, `1px line`, `shadows` in Dawn only).
  plain,

  /// Mood-tinted hero card (`13%` Dawn / `7%` Vercel `m1` blend over `surface`).
  tint,

  /// Inset well (`surface2` fill, borderless, zero shadow).
  flat,
}

/// Token-driven card primitive for Mindora.
///
/// Reads surface, border, corner radius (`28px`), and theme elevation strictly
/// from `context.tokens` without per-widget brightness conditionals.
class MindCard extends StatelessWidget {
  const MindCard({
    super.key,
    required this.child,
    this.variant = MindCardVariant.plain,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
    this.radius,
  });

  final Widget child;
  final MindCardVariant variant;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cardRadius = BorderRadius.circular(radius ?? tokens.cardRadius);

    final resolvedBg =
        backgroundColor ??
        switch (variant) {
          MindCardVariant.plain => tokens.surface,
          MindCardVariant.tint => tokens.cardTint,
          MindCardVariant.flat => tokens.surface2,
        };

    final resolvedBorder =
        borderColor ??
        (variant == MindCardVariant.flat ? Colors.transparent : tokens.line);

    final resolvedShadows = variant == MindCardVariant.flat
        ? const <BoxShadow>[]
        : tokens.shadows;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: cardRadius,
        border: Border.all(color: resolvedBorder, width: 1.0),
        boxShadow: resolvedShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = MindPressable(
        onPressed: onTap,
        borderRadius: cardRadius,
        semanticLabel: semanticLabel,
        child: content,
      );
    } else if (semanticLabel != null) {
      content = Semantics(
        container: true,
        label: semanticLabel,
        child: content,
      );
    }

    return content;
  }
}
