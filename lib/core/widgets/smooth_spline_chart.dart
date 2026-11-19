import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

/// Smooth Bezier Spline Chart driven by [MindTokens]:
/// - `3.5px` smooth curve colored by `lineColor` (`tokens.m1` by default)
/// - dashed horizontal grid rules in `tokens.line`
/// - mood dots ringed by `tokens.surface` (`#0A0A0A` in Dark, `#FFFFFF` in Light)
/// - scrub tooltip in `tokens.ink` fill + `tokens.bg` text
class SmoothSplineChart extends StatelessWidget {
  const SmoothSplineChart({
    super.key,
    required this.values,
    this.height = 132,
    this.lineColor,
    this.fillColors,
    this.pointColors,
    this.activePointIndex,
    this.activePointLabel,
    this.showDots = true,
    this.onPointSelected,
  });

  /// Values normalized between 0.0 and 1.0.
  final List<double> values;
  final double height;
  final Color? lineColor;
  final List<Color>? fillColors;
  final List<Color>? pointColors;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;
  final ValueChanged<int>? onPointSelected;

  int _nearestIndex(double dx, double width) {
    if (values.length <= 1) return 0;
    const hPad = 10.0;
    final usableWidth = (width - hPad * 2).clamp(1.0, width);
    final stepX = usableWidth / (values.length - 1);
    final raw = ((dx - hPad) / stepX).round();
    return math.max(0, math.min(values.length - 1, raw));
  }

  void _notifyIndex(int next) {
    if (next != activePointIndex) {
      HapticFeedback.selectionClick();
    }
    onPointSelected?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final effectiveLine = lineColor ?? tokens.m1;
    final effectiveFill =
        fillColors ??
        [
          effectiveLine.withValues(alpha: 0.34),
          effectiveLine.withValues(alpha: 0.0),
        ];

    if (values.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final chart = RepaintBoundary(
            child: CustomPaint(
              size: Size(width, height),
              painter: _SplinePainter(
                values: values,
                lineColor: effectiveLine,
                fillColors: effectiveFill,
                pointColors: pointColors,
                gridColor: tokens.line,
                dotRingColor: tokens.surface,
                tooltipBgColor: tokens.ink,
                tooltipTextColor: tokens.bg,
                activePointIndex: activePointIndex,
                activePointLabel: activePointLabel,
                showDots: showDots,
                textDirection: Directionality.of(context),
              ),
            ),
          );

          if (onPointSelected == null || values.length < 2) {
            return chart;
          }

          return Semantics(
            label: activePointLabel ?? 'Mood trend curve',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _notifyIndex(_nearestIndex(details.localPosition.dx, width)),
              onHorizontalDragStart: (details) =>
                  _notifyIndex(_nearestIndex(details.localPosition.dx, width)),
              onHorizontalDragUpdate: (details) =>
                  _notifyIndex(_nearestIndex(details.localPosition.dx, width)),
              child: chart,
            ),
          );
        },
      ),
    );
  }
}

class _SplinePainter extends CustomPainter {
  _SplinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColors,
    required this.gridColor,
    required this.dotRingColor,
    required this.tooltipBgColor,
    required this.tooltipTextColor,
    required this.textDirection,
    this.pointColors,
    this.activePointIndex,
    this.activePointLabel,
    this.showDots = true,
  });

  final List<double> values;
  final Color lineColor;
  final List<Color> fillColors;
  final List<Color>? pointColors;
  final Color gridColor;
  final Color dotRingColor;
  final Color tooltipBgColor;
  final Color tooltipTextColor;
  final TextDirection textDirection;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad = 32.0;
    const bottomPad = 14.0;
    const hPad = 10.0;
    final usableHeight = math.max(12.0, size.height - topPad - bottomPad);
    final usableWidth = math.max(12.0, size.width - hPad * 2);

    // Dashed horizontal grid rules (High / Mid / Low)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    const dashLen = 4.0;
    const dashGap = 4.0;
    for (final factor in [0.0, 0.5, 1.0]) {
      final y = topPad + usableHeight * factor;
      for (double x = hPad; x < size.width - hPad; x += dashLen + dashGap) {
        final endX = math.min(x + dashLen, size.width - hPad);
        canvas.drawLine(Offset(x, y), Offset(endX, y), gridPaint);
      }
    }

    final points = <Offset>[];
    final stepX = values.length > 1 ? usableWidth / (values.length - 1) : 0.0;

    for (int i = 0; i < values.length; i++) {
      final val = values[i].clamp(0.0, 1.0);
      final dx = values.length > 1 ? hPad + i * stepX : size.width / 2;
      final dy = topPad + usableHeight - (val * usableHeight);
      points.add(Offset(dx, dy));
    }

    Color dotColorAt(int index) {
      if (pointColors != null && index < pointColors!.length) {
        return pointColors![index];
      }
      return lineColor;
    }

    if (points.length == 1) {
      _drawDot(canvas, points.first, dotColorAt(0), true);
      if (activePointLabel != null) {
        _drawTooltip(canvas, size, points.first, activePointLabel!);
      }
      return;
    }

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, topPad + usableHeight)
      ..lineTo(points.first.dx, topPad + usableHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillColors,
      ).createShader(Rect.fromLTWH(0, topPad, size.width, usableHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final activeIdx = activePointIndex ?? (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final isTarget = i == activeIdx;
      if (showDots || isTarget) {
        _drawDot(canvas, points[i], dotColorAt(i), isTarget);
      }
    }

    if (activePointLabel != null &&
        activeIdx >= 0 &&
        activeIdx < points.length) {
      final anchor = points[activeIdx];
      // Dashed vertical scrub guide line
      for (
        double y = anchor.dy + 9.0;
        y < topPad + usableHeight;
        y += dashLen + dashGap
      ) {
        final endY = math.min(y + dashLen, topPad + usableHeight);
        canvas.drawLine(
          Offset(anchor.dx, y),
          Offset(anchor.dx, endY),
          gridPaint,
        );
      }
      _drawTooltip(canvas, size, anchor, activePointLabel!);
    }
  }

  void _drawDot(Canvas canvas, Offset center, Color dotColor, bool isTarget) {
    if (isTarget) {
      canvas.drawCircle(
        center,
        9.5,
        Paint()..color = dotColor.withValues(alpha: 0.22),
      );
      canvas.drawCircle(center, 6.2, Paint()..color = dotRingColor);
      canvas.drawCircle(center, 4.4, Paint()..color = dotColor);
    } else {
      canvas.drawCircle(center, 4.8, Paint()..color = dotRingColor);
      canvas.drawCircle(center, 3.2, Paint()..color = dotColor);
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Size size,
    Offset target,
    String label,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          fontFamily: LabTheme.fontFamily,
          fontFamilyFallback: LabTheme.fontFallback,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: tooltipTextColor,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final tooltipW = textPainter.width + 20;
    const tooltipH = 26.0;
    final maxX = math.max(4.0, size.width - tooltipW - 4.0);
    final tooltipX = (target.dx - tooltipW / 2).clamp(4.0, maxX);
    final tooltipY = (target.dy - 11.0 - tooltipH).clamp(
      2.0,
      size.height - tooltipH,
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH),
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, Paint()..color = tooltipBgColor);

    textPainter.paint(
      canvas,
      Offset(tooltipX + 10, tooltipY + (tooltipH - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SplinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.activePointIndex != activePointIndex ||
        oldDelegate.activePointLabel != activePointLabel ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.pointColors != pointColors ||
        oldDelegate.dotRingColor != dotRingColor ||
        oldDelegate.tooltipBgColor != tooltipBgColor ||
        oldDelegate.textDirection != textDirection;
  }
}
