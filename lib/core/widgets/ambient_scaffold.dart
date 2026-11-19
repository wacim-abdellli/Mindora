import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Ambient theme-aware scaffold displaying the top mood glow in Light "Dawn"
/// (`tokens.glow` = 30%) and pure `#000000` flat void in Dark "Vercel" (`glow = 0%`).
class AmbientScaffold extends StatelessWidget {
  const AmbientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final glowColor = tokens.glow > 0
        ? tokens.m1.withValues(alpha: tokens.glow)
        : Colors.transparent;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: appBar,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (tokens.glow > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 440,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: glowColor),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    builder: (context, animatedGlow, _) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.0, -1.04),
                            radius: 1.15,
                            colors: [
                              animatedGlow ?? glowColor,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.72],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          body,
        ],
      ),
    );
  }
}
