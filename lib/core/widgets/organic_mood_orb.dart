import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/theme/mind_tokens.dart';
import 'mood_emblem.dart';

/// Expressive, continuously animated fluid somatic mood orb built with pure
/// multi-harmonic vector curves and 3D radial shading.
///
/// Behavior & intensity coupling:
/// - **Morphology (`calm`, `anxious`, `frustrated`, `heavy`, `restless`)**:
///   Each mood defines a distinct organic silhouette with counter-rotating waves.
/// - **Intensity (`1..10`)**: Drives contour lobe amplitude, overall scale,
///   wave velocity, ambient glow (scaled by `tokens.orbGlowFactor` — 35% in Dark
///   Vercel vs 100% in Light Dawn), and outer resonance halo.
/// - **Vertical Drag (`onIntensityChanged`)**: Optional vertical gesture changes
///   intensity (1 level per 16px) with `selectionClick` haptic feedback.
class OrganicMoodOrb extends StatefulWidget {
  const OrganicMoodOrb({
    super.key,
    required this.moodKey,
    required this.intensity,
    required this.color,
    this.size = 104.0,
    this.onTap,
    this.onIntensityChanged,
    this.semanticLabel,
    this.idle = false,
    this.animateChanges = true,
  });

  final String moodKey;
  final int intensity;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final ValueChanged<int>? onIntensityChanged;
  final String? semanticLabel;
  final bool idle;
  final bool animateChanges;

  @override
  State<OrganicMoodOrb> createState() => _OrganicMoodOrbState();
}

class _OrbShapeSpec {
  const _OrbShapeSpec({
    required this.harmonicA,
    required this.ampA,
    required this.harmonicB,
    required this.ampB,
    required this.harmonicC,
    required this.ampC,
    required this.phaseOffset,
    required this.verticalSquash,
    required this.verticalBias,
    required this.scaleFactor,
    required this.speedFactor,
    required this.intensityNorm,
    required this.color,
  });

  final double harmonicA;
  final double ampA;
  final double harmonicB;
  final double ampB;
  final double harmonicC;
  final double ampC;
  final double phaseOffset;
  final double verticalSquash;
  final double verticalBias;
  final double scaleFactor;
  final double speedFactor;
  final double intensityNorm;
  final Color color;

  factory _OrbShapeSpec.forState({
    required String moodKey,
    required int intensity,
    required Color color,
  }) {
    final normKey = MoodEmblem.normalizeKey(moodKey);
    final t = ((intensity.clamp(1, 10) - 1) / 9.0);
    final baseScale = 0.88 + t * 0.20;

    switch (normKey) {
      case 'calm':
        return _OrbShapeSpec(
          harmonicA: 3.0,
          ampA: 0.042 + t * 0.052,
          harmonicB: 2.0,
          ampB: 0.024 + t * 0.032,
          harmonicC: 5.0,
          ampC: 0.008 + t * 0.018,
          phaseOffset: 0.45,
          verticalSquash: 0.96,
          verticalBias: 0.0,
          scaleFactor: baseScale,
          speedFactor: 0.42 + t * 0.95,
          intensityNorm: t,
          color: color,
        );
      case 'anxious':
        return _OrbShapeSpec(
          harmonicA: 6.0,
          ampA: 0.040 + t * 0.072,
          harmonicB: 4.0,
          ampB: 0.024 + t * 0.046,
          harmonicC: 8.0,
          ampC: 0.012 + t * 0.034,
          phaseOffset: 0.85,
          verticalSquash: 1.0,
          verticalBias: 0.0,
          scaleFactor: baseScale,
          speedFactor: 0.65 + t * 1.95,
          intensityNorm: t,
          color: color,
        );
      case 'frustrated':
        return _OrbShapeSpec(
          harmonicA: 5.0,
          ampA: 0.058 + t * 0.105,
          harmonicB: 3.0,
          ampB: 0.040 + t * 0.062,
          harmonicC: 7.0,
          ampC: 0.018 + t * 0.042,
          phaseOffset: 1.25,
          verticalSquash: 0.98,
          verticalBias: -0.02 * t,
          scaleFactor: baseScale,
          speedFactor: 0.72 + t * 2.15,
          intensityNorm: t,
          color: color,
        );
      case 'heavy':
        return _OrbShapeSpec(
          harmonicA: 2.0,
          ampA: 0.048 + t * 0.058,
          harmonicB: 3.0,
          ampB: 0.028 + t * 0.036,
          harmonicC: 4.0,
          ampC: 0.010 + t * 0.022,
          phaseOffset: 1.65,
          verticalSquash: 0.91 - t * 0.04,
          verticalBias: 0.04 + t * 0.06,
          scaleFactor: baseScale,
          speedFactor: 0.34 + t * 0.85,
          intensityNorm: t,
          color: color,
        );
      case 'restless':
      default:
        return _OrbShapeSpec(
          harmonicA: 4.0,
          ampA: 0.052 + t * 0.082,
          harmonicB: 3.0,
          ampB: 0.042 + t * 0.062,
          harmonicC: 6.0,
          ampC: 0.016 + t * 0.034,
          phaseOffset: 2.15,
          verticalSquash: 0.97,
          verticalBias: 0.0,
          scaleFactor: baseScale,
          speedFactor: 0.62 + t * 1.85,
          intensityNorm: t,
          color: color,
        );
    }
  }

  static _OrbShapeSpec lerp(_OrbShapeSpec a, _OrbShapeSpec b, double t) {
    return _OrbShapeSpec(
      harmonicA: b.harmonicA,
      ampA: a.ampA + (b.ampA - a.ampA) * t,
      harmonicB: b.harmonicB,
      ampB: a.ampB + (b.ampB - a.ampB) * t,
      harmonicC: b.harmonicC,
      ampC: a.ampC + (b.ampC - a.ampC) * t,
      phaseOffset: a.phaseOffset + (b.phaseOffset - a.phaseOffset) * t,
      verticalSquash:
          a.verticalSquash + (b.verticalSquash - a.verticalSquash) * t,
      verticalBias: a.verticalBias + (b.verticalBias - a.verticalBias) * t,
      scaleFactor: a.scaleFactor + (b.scaleFactor - a.scaleFactor) * t,
      speedFactor: a.speedFactor + (b.speedFactor - a.speedFactor) * t,
      intensityNorm:
          a.intensityNorm + (b.intensityNorm - a.intensityNorm) * t,
      color: Color.lerp(a.color, b.color, t) ?? b.color,
    );
  }
}

class _OrganicMoodOrbState extends State<OrganicMoodOrb>
    with TickerProviderStateMixin {
  AnimationController? _morphController;
  ValueNotifier<double>? _flowPhaseNotifier;
  Listenable? _paintListenable;
  Ticker? _flowTicker;
  Duration _lastElapsed = Duration.zero;
  double _tapScale = 1.0;
  double _dragAccumDy = 0.0;

  _OrbShapeSpec? _fromSpec;
  _OrbShapeSpec? _toSpec;

  void _ensureInitialized() {
    _toSpec ??= _OrbShapeSpec.forState(
      moodKey: widget.moodKey,
      intensity: widget.intensity,
      color: widget.color,
    );
    _fromSpec ??= _toSpec;
    _flowPhaseNotifier ??= ValueNotifier<double>(0.0);
    _morphController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..value = 1.0;
    _paintListenable ??=
        Listenable.merge([_morphController!, _flowPhaseNotifier!]);
  }

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
  }

  @override
  void reassemble() {
    super.reassemble();
    _ensureInitialized();
    _syncContinuousTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
    _syncContinuousTicker();
  }

  void _syncContinuousTicker() {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!isTest && !reduceMotion) {
      _flowTicker ??= createTicker(_onTick);
      if (!(_flowTicker!.isActive)) {
        _lastElapsed = Duration.zero;
        _flowTicker!.start();
      }
    } else {
      if (_flowTicker?.isActive == true) {
        _flowTicker!.stop();
      }
      _lastElapsed = Duration.zero;
    }
  }

  void _onTick(Duration elapsed) {
    _ensureInitialized();
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dtSec =
        ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    final morphT = Curves.easeOutCubic.transform(_morphController!.value);
    final activeSpec = _OrbShapeSpec.lerp(_fromSpec!, _toSpec!, morphT);

    // Monotonic velocity integration avoids widget rebuilds and drag stutters.
    _flowPhaseNotifier!.value =
        (_flowPhaseNotifier!.value + dtSec * activeSpec.speedFactor) %
            (math.pi * 200.0);
  }

  @override
  void didUpdateWidget(covariant OrganicMoodOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureInitialized();
    if (oldWidget.moodKey != widget.moodKey ||
        oldWidget.intensity != widget.intensity ||
        oldWidget.color != widget.color) {
      final currentT = Curves.easeOutCubic.transform(_morphController!.value);
      _fromSpec = _OrbShapeSpec.lerp(_fromSpec!, _toSpec!, currentT);
      _toSpec = _OrbShapeSpec.forState(
        moodKey: widget.moodKey,
        intensity: widget.intensity,
        color: widget.color,
      );
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (!widget.animateChanges || reduceMotion) {
        _fromSpec = _toSpec;
        _morphController!.value = 1.0;
      } else {
        _morphController!
          ..value = 0.0
          ..forward();
      }
    }
    _syncContinuousTicker();
  }

  @override
  void dispose() {
    _flowTicker?.dispose();
    _flowPhaseNotifier?.dispose();
    _morphController?.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    if (!MediaQuery.disableAnimationsOf(context)) {
      setState(() => _tapScale = 0.92);
      Future<void>.delayed(const Duration(milliseconds: 130), () {
        if (mounted) {
          setState(() => _tapScale = 1.0);
        }
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    Widget orb = AnimatedScale(
      scale: _tapScale,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _paintListenable!,
          builder: (context, _) {
            final morphT =
                Curves.easeOutCubic.transform(_morphController!.value);
            final spec = _OrbShapeSpec.lerp(_fromSpec!, _toSpec!, morphT);
            final effectivePhase = (isTest || reduceMotion)
                ? spec.intensityNorm * 1.4
                : _flowPhaseNotifier!.value;

            final effectiveColor = (widget.idle && !isTest && !reduceMotion)
                ? _idleColorAtPhase(effectivePhase, spec.color)
                : spec.color;
            final renderSpec = _OrbShapeSpec(
              harmonicA: spec.harmonicA,
              ampA: spec.ampA,
              harmonicB: spec.harmonicB,
              ampB: spec.ampB,
              harmonicC: spec.harmonicC,
              ampC: spec.ampC,
              phaseOffset: spec.phaseOffset,
              verticalSquash: spec.verticalSquash,
              verticalBias: spec.verticalBias,
              scaleFactor: spec.scaleFactor,
              speedFactor: spec.speedFactor,
              intensityNorm: spec.intensityNorm,
              color: effectiveColor,
            );

            return CustomPaint(
              size: Size.square(widget.size),
              painter: _OrganicMoodOrbPainter(
                spec: renderSpec,
                phase: effectivePhase,
                orbGlowFactor: tokens.orbGlowFactor,
                isDark: tokens.isDark,
              ),
            );
          },
        ),
      ),
    );

    if (widget.onTap == null && widget.onIntensityChanged == null) {
      return ExcludeSemantics(child: orb);
    }

    return Semantics(
      button: widget.onTap != null,
      slider: widget.onIntensityChanged != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap != null ? _handleTap : null,
        onVerticalDragStart: widget.onIntensityChanged != null
            ? (_) => _dragAccumDy = 0.0
            : null,
        onVerticalDragUpdate: widget.onIntensityChanged != null
            ? (details) {
                _dragAccumDy += details.delta.dy;
                if (_dragAccumDy.abs() >= 16.0) {
                  final step = _dragAccumDy < 0 ? 1 : -1;
                  _dragAccumDy = 0.0;
                  final next = (widget.intensity + step).clamp(1, 10);
                  if (next != widget.intensity) {
                    HapticFeedback.selectionClick();
                    widget.onIntensityChanged!(next);
                  }
                }
              }
            : null,
        child: SizedBox(
          width: math.max(48.0, widget.size),
          height: math.max(48.0, widget.size),
          child: Center(child: orb),
        ),
      ),
    );
  }

  static Color _idleColorAtPhase(double phase, Color fallback) {
    const moods = AppMood.values;
    final cycle = (phase * 0.25) % moods.length;
    final idx = cycle.floor() % moods.length;
    final nextIdx = (idx + 1) % moods.length;
    final t = cycle - cycle.floor();
    return Color.lerp(
          MindTokens.moodColor(moods[idx]),
          MindTokens.moodColor(moods[nextIdx]),
          t,
        ) ??
        fallback;
  }
}

class _OrganicMoodOrbPainter extends CustomPainter {
  const _OrganicMoodOrbPainter({
    required this.spec,
    required this.phase,
    required this.orbGlowFactor,
    required this.isDark,
  });

  final _OrbShapeSpec spec;
  final double phase;
  final double orbGlowFactor;
  final bool isDark;

  Path _buildFluidPath(Size size, {double scaleMultiplier = 1.0}) {
    final cx = size.width / 2;
    final cy = size.height / 2 + spec.verticalBias * (size.height * 0.34);
    final breathePulse = 1.0 +
        (0.014 + spec.intensityNorm * 0.036) * math.sin(phase * 1.35);
    final baseRadius =
        size.width * 0.34 * spec.scaleFactor * scaleMultiplier * breathePulse;
    const steps = 72;
    final pts = <Offset>[];

    for (var i = 0; i < steps; i++) {
      final theta = (i / steps) * 2 * math.pi;
      final waveA = spec.ampA *
          math.sin(spec.harmonicA * theta + spec.phaseOffset + phase);
      final waveB = spec.ampB *
          math.cos(spec.harmonicB * theta - spec.phaseOffset * 0.8 - phase * 1.32);
      final waveC = spec.ampC *
          math.sin(spec.harmonicC * theta + phase * 1.85);
      final r = baseRadius * (1.0 + waveA + waveB + waveC);
      pts.add(
        Offset(
          cx + r * math.cos(theta),
          cy + r * spec.verticalSquash * math.sin(theta),
        ),
      );
    }

    final path = Path();
    if (pts.isNotEmpty) {
      final firstMid = Offset(
        (pts.last.dx + pts.first.dx) / 2,
        (pts.last.dy + pts.first.dy) / 2,
      );
      path.moveTo(firstMid.dx, firstMid.dy);
      for (var i = 0; i < pts.length; i++) {
        final curr = pts[i];
        final next = pts[(i + 1) % pts.length];
        final mid = Offset((curr.dx + next.dx) / 2, (curr.dy + next.dy) / 2);
        path.quadraticBezierTo(curr.dx, curr.dy, mid.dx, mid.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2 + spec.verticalBias * (size.height * 0.34),
    );
    final path = _buildFluidPath(size);
    final outerRadius = size.width * 0.40 * spec.scaleFactor;

    // 1. Intensity-coupled ambient aura glow (35% strength in Dark Vercel vs 100% in Light Dawn).
    final baseGlowAlpha = (0.16 + spec.intensityNorm * 0.16) * orbGlowFactor;
    final haloPaint = Paint()
      ..color = spec.color.withValues(alpha: baseGlowAlpha)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.width * (0.11 + spec.intensityNorm * 0.08) * orbGlowFactor,
      );
    canvas.drawPath(path, haloPaint);

    // 2. Subtle outer resonance silhouette halo when intensity builds (>= 4/10).
    if (spec.intensityNorm > 0.25) {
      final echoScale = 1.13 +
          spec.intensityNorm * 0.05 +
          0.025 * math.sin(phase * 1.1);
      final echoPath = _buildFluidPath(size, scaleMultiplier: echoScale);
      final echoPaint = Paint()
        ..color = spec.color.withValues(
          alpha: (spec.intensityNorm - 0.2) * (0.28 * orbGlowFactor + 0.08),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(echoPath, echoPaint);
    }

    // 3. Sculpted 3D liquid mesh shading (highlight shifts subtly with fluid motion).
    final highlightColor = Color.lerp(
          spec.color,
          MindTokens.pureWhiteConstant,
          isDark ? 0.48 : 0.58,
        ) ??
        spec.color;
    final warmMid = Color.lerp(
          spec.color,
          isDark ? MindTokens.pureWhiteConstant : MindTokens.orbWarmHighlight,
          0.10,
        ) ??
        spec.color;
    final deepColor = Color.lerp(
          spec.color,
          MindTokens.darkBg,
          isDark ? 0.30 : 0.20,
        ) ??
        spec.color;

    final lightDriftX = -0.30 + 0.10 * math.cos(phase * 0.8);
    final lightDriftY = -0.34 + 0.08 * math.sin(phase * 0.9);
    final shaderRect = Rect.fromCircle(center: center, radius: outerRadius);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(lightDriftX, lightDriftY),
        radius: 1.08,
        colors: [highlightColor, warmMid, spec.color, deepColor],
        stops: const [0.0, 0.28, 0.62, 1.0],
      ).createShader(shaderRect);
    canvas.drawPath(path, bodyPaint);

    // 4. Crisp translucent glass rim hairline.
    final rimPaint = Paint()
      ..color = highlightColor.withValues(alpha: isDark ? 0.30 : 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05;
    canvas.drawPath(path, rimPaint);

    // 5. Soft pearlescent specular glint following top-left light shoulder.
    final glintPaint = Paint()
      ..color = MindTokens.pureWhiteConstant.withValues(
        alpha: isDark ? 0.24 : 0.36,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.045);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx + lightDriftX * outerRadius * 0.82,
          center.dy + lightDriftY * outerRadius * 0.82,
        ),
        width: outerRadius * 0.42,
        height: outerRadius * 0.24,
      ),
      glintPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrganicMoodOrbPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.orbGlowFactor != orbGlowFactor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.spec.harmonicA != spec.harmonicA ||
        oldDelegate.spec.ampA != spec.ampA ||
        oldDelegate.spec.ampB != spec.ampB ||
        oldDelegate.spec.ampC != spec.ampC ||
        oldDelegate.spec.scaleFactor != spec.scaleFactor ||
        oldDelegate.spec.intensityNorm != spec.intensityNorm ||
        oldDelegate.spec.verticalBias != spec.verticalBias ||
        oldDelegate.spec.color != spec.color;
  }
}
