import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/mind_tokens.dart';

/// House tactile pressable for Mindora.
///
/// Replaces stock Material ink splash ripples with organic scale + subtle fade
/// motion, desktop pointer hover & keyboard focus ring (`Enter`/`Space`
/// activation via [FocusableActionDetector]), and optional light haptic tick.
/// Honors reduced-motion accessibility.
class MindPressable extends StatefulWidget {
  const MindPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
    this.selected,
    this.pressScale = 0.975,
    this.pressOpacity = 0.88,
    this.enableHaptic = true,
    this.borderRadius,
    this.focusNode,
    this.autofocus = false,
    this.showHoverHighlight = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;
  final bool? selected;
  final double pressScale;
  final double pressOpacity;
  final bool enableHaptic;
  final BorderRadius? borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showHoverHighlight;

  @override
  State<MindPressable> createState() => _MindPressableState();
}

class _MindPressableState extends State<MindPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _handleActivate() {
    if (!widget.enabled || widget.onPressed == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onPressed != null;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tokens = context.tokens;
    final Duration duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 110);
    final bool isPressed = _pressed && interactive;
    final bool showHover = _hovered && interactive && widget.showHoverHighlight;
    final bool showFocus = _focused && interactive;

    Widget result = widget.child;

    if (showHover || showFocus) {
      result = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          color: showHover ? tokens.surfaceHover : Colors.transparent,
          borderRadius: widget.borderRadius,
          border: showFocus
              ? Border.all(color: tokens.focusRing, width: 2.0)
              : null,
        ),
        child: result,
      );
    }

    result = AnimatedScale(
      scale: reduceMotion ? 1.0 : (isPressed ? widget.pressScale : 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isPressed ? widget.pressOpacity : 1.0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: result,
      ),
    );

    if (widget.borderRadius != null) {
      result = ClipRRect(borderRadius: widget.borderRadius!, child: result);
    }

    result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive
          ? (_) {
              if (widget.enableHaptic) {
                HapticFeedback.selectionClick();
              }
              setState(() => _pressed = true);
            }
          : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      onTap: interactive ? widget.onPressed : null,
      child: result,
    );

    result = FocusableActionDetector(
      enabled: interactive,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (hovered) {
        if (_hovered != hovered) {
          setState(() => _hovered = hovered);
        }
      },
      onShowFocusHighlight: (focused) {
        if (_focused != focused) {
          setState(() => _focused = focused);
        }
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleActivate();
            return null;
          },
        ),
      },
      child: result,
    );

    if (interactive || widget.semanticLabel != null || widget.selected != null) {
      return Semantics(
        button: interactive,
        enabled: interactive,
        selected: widget.selected,
        label: widget.semanticLabel,
        child: result,
      );
    }

    return result;
  }
}
