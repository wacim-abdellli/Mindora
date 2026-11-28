import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/mind_tokens.dart';

/// Accessible toggle switch reading [MindTokens] exclusively (62×48dp hit target).
///
/// Supports pointer hover, keyboard focus (`Tab` + `Enter`/`Space`), RTL thumb
/// travel, and WCAG 1.4.11 compliant track/thumb contrast in both themes.
class MindSwitch extends StatefulWidget {
  const MindSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.focusNode,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<MindSwitch> createState() => _MindSwitchState();
}

class _MindSwitchState extends State<MindSwitch> {
  bool _focused = false;
  bool _hovered = false;

  void _toggle() {
    if (!widget.enabled || widget.onChanged == null) return;
    HapticFeedback.selectionClick();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final interactive = widget.enabled && widget.onChanged != null;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Semantics(
      toggled: widget.value,
      enabled: interactive,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: interactive,
        focusNode: widget.focusNode,
        mouseCursor: interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
        },
        onShowHoverHighlight: (hovered) {
          if (_hovered != hovered) setState(() => _hovered = hovered);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: interactive ? _toggle : null,
          child: SizedBox(
            width: 62,
            height: 48,
            child: Center(
              child: Opacity(
                opacity: interactive ? 1.0 : 0.42,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(
                      color: _focused && interactive
                          ? tokens.focusRing
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: 54,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: widget.value
                          ? tokens.switchOnTrack
                          : (_hovered && interactive
                                ? Color.alphaBlend(
                                    tokens.surfaceHover,
                                    tokens.switchOffTrack,
                                  )
                                : tokens.switchOffTrack),
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      border: Border.all(
                        color: widget.value
                            ? tokens.accentInk
                            : tokens.lineStrong,
                        width: 1.5,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      alignment: widget.value
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.value
                              ? tokens.switchThumbOn
                              : tokens.ink3,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
