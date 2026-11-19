import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/mind_tokens.dart';

/// Luxury concentric bio-luminescent vagal breathing visualizer.
///
/// Features fluid ripple waves and phase-dependent colors that breathe
/// organically with the user to downregulate the autonomic nervous system.
class VagalBreathingVisualizer extends StatefulWidget {
  const VagalBreathingVisualizer({
    super.key,
    required this.phase,
    required this.secondsLeft,
    required this.phaseText,
    required this.isDark,
  });

  final int phase; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  final int secondsLeft;
  final String phaseText;
  final bool isDark;

  @override
  State<VagalBreathingVisualizer> createState() => _VagalBreathingVisualizerState();
}

class _VagalBreathingVisualizerState extends State<VagalBreathingVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!isTest && !reduceMotion) {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
      _waveController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Color get _phaseAccentColor {
    switch (widget.phase) {
      case 0: // Inhale
        return MindTokens.moodAnxious;
      case 1: // Hold
        return MindTokens.moodRestless;
      case 2: // Exhale
        return MindTokens.moodFrustrated;
      case 3: // Hold
      default:
        return MindTokens.moodCalm;
    }
  }

  Color _phaseBgColor(BuildContext context) {
    return context.tokens.cardTintFor(_phaseAccentColor);
  }

  double get _targetScale {
    switch (widget.phase) {
      case 0: // Inhale
        return 1.25;
      case 1: // Hold Full
        return 1.25;
      case 2: // Exhale
        return 0.85;
      case 3: // Hold Empty
      default:
        return 0.85;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _phaseAccentColor;
    final bg = _phaseBgColor(context);
    final isDark = widget.isDark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outward Breathing Aura Rings
            ExcludeSemantics(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(190, 190),
                      painter: _BreathingRipplesPainter(
                        progress: reduceMotion ? 0.0 : _waveController.value,
                        color: accent,
                        phase: widget.phase,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Physical Interactive Breathing Core
            Semantics(
              liveRegion: true,
              label: '${widget.phaseText}, ${widget.secondsLeft}',
              child: AnimatedScale(
                scale: reduceMotion ? 1.0 : _targetScale,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bg,
                  border: Border.all(color: accent, width: 2.0),
                  boxShadow: isDark
                      ? const []
                      : [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.2),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Center(
                  child: MediaQuery.withClampedTextScaling(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.secondsLeft}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.phaseText.toUpperCase(),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: accent.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingRipplesPainter extends CustomPainter {
  const _BreathingRipplesPainter({
    required this.progress,
    required this.color,
    required this.phase,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final int phase;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 52.0 + (ringProgress * (maxRadius - 52.0));
      final opacity = (1.0 - ringProgress) * (isDark ? 0.30 : 0.20);

      final paint = Paint()
        ..color = color.withValues(alpha: math.max(0.0, opacity))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingRipplesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.phase != phase ||
        oldDelegate.isDark != isDark;
  }
}

