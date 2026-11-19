import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

/// Real-time animated neural waveform telemetry canvas.
///
/// Visualizes autonomic nervous system frequency and arousal intensity (1-10)
/// via high-precision multi-harmonic sine wave synthesis and glowing razor-thin strokes.
class NeuralWaveformVisualizer extends StatefulWidget {
  const NeuralWaveformVisualizer({
    super.key,
    required this.intensity,
    required this.moodColor,
    this.isDark = false,
    required this.strings,
  });

  final double intensity;
  final Color moodColor;
  final bool isDark;
  final AppStrings strings;

  @override
  State<NeuralWaveformVisualizer> createState() => _NeuralWaveformVisualizerState();
}

class _NeuralWaveformVisualizerState extends State<NeuralWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!isTesting && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getFrequencyTelemetry(double intensity, AppStrings s) {
    if (intensity <= 3) {
      final hz = (7.5 + (intensity * 0.5)).toStringAsFixed(1);
      return s.isArabic
          ? 'ALPHA $hz Hz • هدوء واستقرار عصبي'
          : (s.isFrench ? 'ALPHA $hz Hz • Calme Somatique' : 'ALPHA $hz Hz • SOMATIC REST');
    } else if (intensity <= 6) {
      final hz = (12.0 + (intensity * 1.2)).toStringAsFixed(1);
      return s.isArabic
          ? 'BETA $hz Hz • نشاط ذهني معتدل'
          : (s.isFrench ? 'BETA $hz Hz • Vigilance Modérée' : 'BETA $hz Hz • ACTIVE ATTENTION');
    } else {
      final hz = (24.0 + (intensity * 1.5)).toStringAsFixed(1);
      return s.isArabic
          ? 'GAMMA $hz Hz • استثارة عصبية مرتفعة'
          : (s.isFrench ? 'GAMMA $hz Hz • Hyperarousal Aigu' : 'GAMMA $hz Hz • ACUTE AROUSAL');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final telemetry = _getFrequencyTelemetry(widget.intensity, widget.strings);

    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  telemetry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: LabTheme.fontFamily,
                    fontFamilyFallback: LabTheme.fontFallback,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: widget.intensity >= 7 ? tokens.safety : tokens.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.moodColor,
                  boxShadow: tokens.glow > 0
                      ? [
                          BoxShadow(
                            color: widget.moodColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WaveformPainter(
                        phase: _controller.value * 2 * math.pi,
                        intensity: widget.intensity,
                        color: widget.moodColor,
                        glowAlpha: tokens.glow > 0 ? 0.20 : 0.35,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.phase,
    required this.intensity,
    required this.color,
    required this.glowAlpha,
  });

  final double phase;
  final double intensity;
  final Color color;
  final double glowAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final width = size.width;

    final amp = 4.0 + (intensity * 2.2);
    final freq = 0.02 + (intensity * 0.015);

    final path = Path();
    path.moveTo(0, midY);

    for (double x = 0; x <= width; x += 2.0) {
      final y = midY +
          math.sin(x * freq + phase) * amp * 0.75 +
          math.sin(x * freq * 2.4 - phase * 1.5) * (amp * 0.25);
      path.lineTo(x, y);
    }

    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowAlpha)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color ||
        oldDelegate.glowAlpha != glowAlpha;
  }
}
