import 'package:flutter/material.dart';

/// Bespoke geometric vector emblem representing core mood states without
/// resorting to system emojis or generic face icons.
class MoodEmblem extends StatelessWidget {
  const MoodEmblem({
    super.key,
    required this.moodKey,
    required this.color,
    this.size = 18.0,
    this.strokeWidth,
  });

  /// Canonical or localized mood identifier (`calm`, `anxious`, `frustrated`,
  /// `heavy`, `restless`).
  final String moodKey;

  /// Calibrated foreground stroke color for the active brightness mode.
  final Color color;

  /// Bounding square size in logical pixels.
  final double size;

  /// Optional custom stroke thickness; scales proportionally with [size].
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeKey(moodKey);
    final effectiveStroke = strokeWidth ?? (size * 0.11).clamp(1.5, 2.6);

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _MoodEmblemPainter(
              normalizedKey: normalized,
              color: color,
              strokeWidth: effectiveStroke,
            ),
          ),
        ),
      ),
    );
  }

  /// Normalizes canonical or localized mood names to one of the 5 core keys.
  static String normalizeKey(String raw) {
    final key = raw.toLowerCase().trim();
    if (key.contains('calm') || key.contains('calme') || key.contains('هاد')) {
      return 'calm';
    }
    if (key.contains('anxi') || key.contains('متوت') || key.contains('قلق')) {
      return 'anxious';
    }
    if (key.contains('frustr') || key.contains('محب')) {
      return 'frustrated';
    }
    if (key.contains('heav') || key.contains('lourd') || key.contains('ثقيل')) {
      return 'heavy';
    }
    if (key.contains('restless') ||
        key.contains('agit') ||
        key.contains('مشت') ||
        key.contains('متقلب')) {
      return 'restless';
    }
    return 'calm';
  }
}

class _MoodEmblemPainter extends CustomPainter {
  const _MoodEmblemPainter({
    required this.normalizedKey,
    required this.color,
    required this.strokeWidth,
  });

  final String normalizedKey;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softStrokePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.9
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (normalizedKey) {
      case 'calm':
        // Concentric botanical breath ripples around a calm anchor point.
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          w * 0.39,
          softStrokePaint,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          w * 0.23,
          strokePaint,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          w * 0.085,
          fillPaint,
        );
      case 'anxious':
        // Harmonized high-frequency pulse crest (alertness / tension rhythm).
        final pulse = Path()
          ..moveTo(w * 0.1, h * 0.54)
          ..lineTo(w * 0.27, h * 0.54)
          ..lineTo(w * 0.38, h * 0.24)
          ..lineTo(w * 0.52, h * 0.78)
          ..lineTo(w * 0.65, h * 0.36)
          ..lineTo(w * 0.74, h * 0.54)
          ..lineTo(w * 0.9, h * 0.54);
        canvas.drawPath(pulse, strokePaint);
      case 'frustrated':
        // Geometric angular tension prism / clean spark stroke.
        final spark = Path()
          ..moveTo(w * 0.58, h * 0.14)
          ..lineTo(w * 0.26, h * 0.53)
          ..lineTo(w * 0.52, h * 0.53)
          ..lineTo(w * 0.42, h * 0.86)
          ..lineTo(w * 0.74, h * 0.46)
          ..lineTo(w * 0.48, h * 0.46)
          ..close();
        canvas.drawPath(spark, strokePaint);
      case 'heavy':
        // Weighted cloud dome resting calmly above a grounded dusk horizon.
        final dome = Path()
          ..moveTo(w * 0.22, h * 0.62)
          ..cubicTo(
            w * 0.12,
            h * 0.62,
            w * 0.12,
            h * 0.42,
            w * 0.27,
            h * 0.41,
          )
          ..cubicTo(
            w * 0.31,
            h * 0.22,
            w * 0.61,
            h * 0.2,
            w * 0.68,
            h * 0.39,
          )
          ..cubicTo(
            w * 0.86,
            h * 0.39,
            w * 0.88,
            h * 0.62,
            w * 0.76,
            h * 0.62,
          )
          ..close();
        canvas.drawPath(dome, strokePaint);
        canvas.drawLine(
          Offset(w * 0.22, h * 0.78),
          Offset(w * 0.78, h * 0.78),
          softStrokePaint,
        );
      case 'restless':
      default:
        // Twin kinetic breeze ribbons curving forward without turbulence clutter.
        final upperWind = Path()
          ..moveTo(w * 0.14, h * 0.38)
          ..cubicTo(
            w * 0.38,
            h * 0.24,
            w * 0.54,
            h * 0.5,
            w * 0.76,
            h * 0.35,
          )
          ..cubicTo(
            w * 0.84,
            h * 0.29,
            w * 0.88,
            h * 0.22,
            w * 0.8,
            h * 0.18,
          );
        final lowerWind = Path()
          ..moveTo(w * 0.18, h * 0.64)
          ..cubicTo(
            w * 0.42,
            h * 0.54,
            w * 0.56,
            h * 0.76,
            w * 0.8,
            h * 0.62,
          );
        canvas.drawPath(upperWind, strokePaint);
        canvas.drawPath(lowerWind, softStrokePaint);
        canvas.drawCircle(Offset(w * 0.84, h * 0.72), w * 0.055, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodEmblemPainter oldDelegate) =>
      oldDelegate.normalizedKey != normalizedKey ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
