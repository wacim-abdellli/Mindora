import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Reduced-motion-safe loading placeholder block using [MindTokens].
///
/// Renders a calm, static surface block when `MediaQuery.disableAnimationsOf`
/// is true, and a gentle low-amplitude surface pulse otherwise.
class MindSkeleton extends StatefulWidget {
  const MindSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  /// Convenience line skeleton for text placeholders.
  const MindSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  })  : borderRadius = const BorderRadius.all(Radius.circular(8)),
        isCircle = false;

  /// Convenience card skeleton for list/dashboard placeholders.
  const MindSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 96,
  })  : borderRadius = const BorderRadius.all(Radius.circular(20)),
        isCircle = false;

  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  @override
  State<MindSkeleton> createState() => _MindSkeletonState();
}

class _MindSkeletonState extends State<MindSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  void _syncController(bool reduceMotion) {
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController(MediaQuery.disableAnimationsOf(context));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final controller = _controller;

    if (controller == null) {
      return ExcludeSemantics(
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.surface2,
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : radius,
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final color = Color.lerp(
            tokens.surface2,
            tokens.surface3,
            Curves.easeInOut.transform(controller.value),
          );
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: color,
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : radius,
            ),
          );
        },
      ),
    );
  }
}
