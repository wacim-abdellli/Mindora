import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Organic botanical leaf emblem driven by [MindTokens].
class BotanicalEmblem extends StatelessWidget {
  const BotanicalEmblem({
    super.key,
    this.size = 32,
    this.color,
    this.backgroundColor,
  });

  final double size;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final leafColor = color ?? tokens.m1;

    final emblem = ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(size, size),
          painter: _BotanicalLeafPainter(color: leafColor),
        ),
      ),
    );

    if (backgroundColor == null) {
      return emblem;
    }

    return Container(
      width: size * 1.6,
      height: size * 1.6,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: emblem,
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  const _BotanicalLeafPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final stem = Path()
      ..moveTo(w * 0.45, h * 0.95)
      ..cubicTo(w * 0.45, h * 0.70, w * 0.52, h * 0.40, w * 0.50, h * 0.12);
    canvas.drawPath(stem, paint);

    final topLeaf = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..cubicTo(w * 0.62, h * 0.22, w * 0.60, h * 0.38, w * 0.50, h * 0.42)
      ..cubicTo(w * 0.40, h * 0.38, w * 0.38, h * 0.22, w * 0.50, h * 0.12);
    canvas.drawPath(topLeaf, fillPaint);
    canvas.drawPath(topLeaf, paint);

    final leftLeaf = Path()
      ..moveTo(w * 0.48, h * 0.55)
      ..cubicTo(w * 0.28, h * 0.45, w * 0.22, h * 0.60, w * 0.26, h * 0.70)
      ..cubicTo(w * 0.38, h * 0.70, w * 0.46, h * 0.62, w * 0.48, h * 0.55);
    canvas.drawPath(leftLeaf, fillPaint);
    canvas.drawPath(leftLeaf, paint);

    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.42)
      ..cubicTo(w * 0.70, h * 0.36, w * 0.76, h * 0.50, w * 0.72, h * 0.60)
      ..cubicTo(w * 0.60, h * 0.60, w * 0.52, h * 0.52, w * 0.51, h * 0.42);
    canvas.drawPath(rightLeaf, fillPaint);
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeafPainter oldDelegate) =>
      oldDelegate.color != color;
}
