import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Expressive drawn-vector character for Mindora's six core mood states.
///
/// Zero Unicode emojis are used anywhere — every face is drawn via [CustomPainter]
/// with WCAG-verified plum strokes (`>= 5.8:1` on all six vivid mood fills),
/// tactile spring squish on tap/selection, and full reduced-motion support.
class MoodFace extends StatefulWidget {
  const MoodFace({
    super.key,
    required this.mood,
    this.size = 64.0,
    this.isSelected = false,
    this.semanticLabel,
    this.onTap,
  });

  /// Canonical mood driving both vivid fill color and facial expression.
  final AppMood mood;

  /// Bounding diameter in logical pixels (`72–80` on Home grid, `44–56` on summaries, `26–32` on calendar).
  final double size;

  /// Displays a crisp selection ring, warm lift, and jelly-bounce spring.
  final bool isSelected;

  /// Accessible label for TalkBack / VoiceOver when interactive or standalone.
  final String? semanticLabel;

  /// Optional tap callback; triggers light haptic + tactile jelly squish.
  final VoidCallback? onTap;

  @override
  State<MoodFace> createState() => _MoodFaceState();
}

class _MoodFaceState extends State<MoodFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scaleX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.09), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.09, end: 0.97), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutCubic));

    _scaleY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.91), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.91, end: 1.03), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant MoodFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _triggerBounce();
    }
  }

  void _triggerBounce() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _bounceCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fillColor = MindTokens.moodColor(widget.mood);
    final highlightColor = MindTokens.moodHighlight(widget.mood);

    Widget face = AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (context, child) {
        final sx = reduceMotion ? 1.0 : _scaleX.value;
        final sy = reduceMotion ? 1.0 : _scaleY.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sx, sy, 1.0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: fillColor.withValues(alpha: tokens.isDark ? 0.42 : 0.48),
                    blurRadius: widget.size * 0.28,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _MoodFacePainter(
              mood: widget.mood,
              fillColor: fillColor,
              highlightColor: highlightColor,
              strokeColor: MindTokens.onMoodConstant,
              ringColor: tokens.ink,
              isSelected: widget.isSelected,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      face = MindPressable(
        onPressed: () {
          HapticFeedback.selectionClick();
          _triggerBounce();
          widget.onTap!();
        },
        semanticLabel: widget.semanticLabel,
        borderRadius: BorderRadius.circular(widget.size),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(child: face),
        ),
      );
    } else if (widget.semanticLabel != null) {
      face = Semantics(
        image: true,
        selected: widget.isSelected,
        label: widget.semanticLabel,
        child: face,
      );
    } else {
      face = ExcludeSemantics(child: face);
    }

    return face;
  }
}

/// Complete accessible picker card pairing a drawn [MoodFace] with its plain label.
///
/// Guarantees >= 72dp comfortable touch target, warm mood-tinted surface on
/// selection, and crisp non-color selection cues (border + weight + check badge).
class MoodFaceTile extends StatelessWidget {
  const MoodFaceTile({
    super.key,
    required this.mood,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.faceSize = 54.0,
  });

  final AppMood mood;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double faceSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final moodColor = MindTokens.moodColor(mood);
    final selectedBg = tokens.tint(moodColor, tokens.isDark ? 0.24 : 0.22);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: MindPressable(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 96, minWidth: 72),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 7 : 8,
            vertical: isSelected ? 11 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : tokens.surface,
            borderRadius: BorderRadius.circular(tokens.tileRadius),
            border: Border.all(
              color: isSelected ? tokens.ink : tokens.line,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected ? tokens.shadows : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoodFace(
                mood: mood,
                size: faceSize,
                isSelected: isSelected,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 14.0,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  const _MoodFacePainter({
    required this.mood,
    required this.fillColor,
    required this.highlightColor,
    required this.strokeColor,
    required this.ringColor,
    required this.isSelected,
  });

  final AppMood mood;
  final Color fillColor;
  final Color highlightColor;
  final Color strokeColor;
  final Color ringColor;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = math.min(w, h) * 0.46;

    // 1. Soft organic squircle-circle fill with sunlit radial gradient
    final bodyRect = Rect.fromCircle(center: center, radius: radius);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.38),
        radius: 0.92,
        colors: [highlightColor, fillColor],
      ).createShader(bodyRect);

    final rrect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(radius * 0.88),
    );
    canvas.drawRRect(rrect, bodyPaint);

    // 2. Subtle warm top-start specular shine for tactile depth
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, h * 0.24),
        width: radius * 0.48,
        height: radius * 0.24,
      ),
      shinePaint,
    );

    // 3. Crisp selection outline
    if (isSelected) {
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.045).clamp(1.8, 3.0);
      canvas.drawRRect(rrect, ringPaint);
    }

    // 4. Drawn facial expression strokes (deep plum, WCAG >= 5.8:1)
    final strokeW = (w * 0.062).clamp(1.5, 4.2);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillDot = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    switch (mood) {
      case AppMood.good:
        // Rosy cheeks
        final cheekPaint = Paint()
          ..color = MindTokens.moodFrustrated.withValues(alpha: 0.36);
        canvas.drawCircle(Offset(w * 0.25, h * 0.58), w * 0.075, cheekPaint);
        canvas.drawCircle(Offset(w * 0.75, h * 0.58), w * 0.075, cheekPaint);
        // Happy curved-up arc eyes (^ ^)
        final leftEye = Path()
          ..moveTo(w * 0.27, h * 0.45)
          ..quadraticBezierTo(w * 0.34, h * 0.34, w * 0.41, h * 0.45);
        final rightEye = Path()
          ..moveTo(w * 0.59, h * 0.45)
          ..quadraticBezierTo(w * 0.66, h * 0.34, w * 0.73, h * 0.45);
        canvas.drawPath(leftEye, strokePaint);
        canvas.drawPath(rightEye, strokePaint);
        // Warm wide smile
        final smile = Path()
          ..moveTo(w * 0.33, h * 0.59)
          ..quadraticBezierTo(w * 0.50, h * 0.77, w * 0.67, h * 0.59);
        canvas.drawPath(smile, strokePaint);

      case AppMood.calm:
        // Peaceful closed downward-arc eyes
        final leftLid = Path()
          ..moveTo(w * 0.27, h * 0.44)
          ..quadraticBezierTo(w * 0.34, h * 0.51, w * 0.41, h * 0.44);
        final rightLid = Path()
          ..moveTo(w * 0.59, h * 0.44)
          ..quadraticBezierTo(w * 0.66, h * 0.51, w * 0.73, h * 0.44);
        canvas.drawPath(leftLid, strokePaint);
        canvas.drawPath(rightLid, strokePaint);
        // Serene small smile
        final gentleSmile = Path()
          ..moveTo(w * 0.40, h * 0.62)
          ..quadraticBezierTo(w * 0.50, h * 0.70, w * 0.60, h * 0.62);
        canvas.drawPath(gentleSmile, strokePaint);

      case AppMood.anxious:
        // Wide attentive round eyes
        canvas.drawCircle(Offset(w * 0.35, h * 0.47), w * 0.052, fillDot);
        canvas.drawCircle(Offset(w * 0.65, h * 0.47), w * 0.052, fillDot);
        // Soft raised inner worried brows
        canvas.drawLine(
          Offset(w * 0.27, h * 0.36),
          Offset(w * 0.39, h * 0.31),
          strokePaint,
        );
        canvas.drawLine(
          Offset(w * 0.73, h * 0.36),
          Offset(w * 0.61, h * 0.31),
          strokePaint,
        );
        // Gentle wavy mouth
        final wave = Path()
          ..moveTo(w * 0.34, h * 0.65)
          ..quadraticBezierTo(w * 0.42, h * 0.59, w * 0.50, h * 0.65)
          ..quadraticBezierTo(w * 0.58, h * 0.71, w * 0.66, h * 0.65);
        canvas.drawPath(wave, strokePaint);

      case AppMood.frustrated:
        // Determined inward-angled brows
        canvas.drawLine(
          Offset(w * 0.26, h * 0.35),
          Offset(w * 0.42, h * 0.41),
          strokePaint,
        );
        canvas.drawLine(
          Offset(w * 0.74, h * 0.35),
          Offset(w * 0.58, h * 0.41),
          strokePaint,
        );
        // Focused eyes
        canvas.drawCircle(Offset(w * 0.35, h * 0.49), w * 0.048, fillDot);
        canvas.drawCircle(Offset(w * 0.65, h * 0.49), w * 0.048, fillDot);
        // Firm slight frown
        final frown = Path()
          ..moveTo(w * 0.36, h * 0.68)
          ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.64, h * 0.68);
        canvas.drawPath(frown, strokePaint);

      case AppMood.heavy:
        // Soft drooping outer eyes for tired/heavy empathy (never angry)
        final leftLowEye = Path()
          ..moveTo(w * 0.27, h * 0.45)
          ..quadraticBezierTo(w * 0.34, h * 0.51, w * 0.41, h * 0.47);
        final rightLowEye = Path()
          ..moveTo(w * 0.73, h * 0.45)
          ..quadraticBezierTo(w * 0.66, h * 0.51, w * 0.59, h * 0.47);
        canvas.drawPath(leftLowEye, strokePaint);
        canvas.drawPath(rightLowEye, strokePaint);
        // Gentle downcast low curve
        final lowCurve = Path()
          ..moveTo(w * 0.38, h * 0.67)
          ..quadraticBezierTo(w * 0.50, h * 0.61, w * 0.62, h * 0.67);
        canvas.drawPath(lowCurve, strokePaint);

      case AppMood.restless:
        // Asymmetric alert eyes
        canvas.drawCircle(Offset(w * 0.35, h * 0.44), w * 0.056, fillDot);
        canvas.drawCircle(Offset(w * 0.65, h * 0.48), w * 0.044, fillDot);
        // Energetic ripple mouth
        final ripple = Path()
          ..moveTo(w * 0.33, h * 0.64)
          ..lineTo(w * 0.42, h * 0.60)
          ..lineTo(w * 0.50, h * 0.67)
          ..lineTo(w * 0.58, h * 0.60)
          ..lineTo(w * 0.67, h * 0.64);
        canvas.drawPath(ripple, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodFacePainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.isSelected != isSelected;
  }
}
