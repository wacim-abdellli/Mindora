import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

enum MindToastVariant { neutral, success, warning, error }

OverlayEntry? _activeToastEntry;

/// Displays a calm toast above all modal sheets via the root [Overlay],
/// falling back to [ScaffoldMessenger] if no root overlay is present.
void showMindToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2200),
  MindToastVariant variant = MindToastVariant.neutral,
}) {
  final tokens = context.tokens;
  final (Color bg, Color fg, IconData? icon) = switch (variant) {
    MindToastVariant.neutral => (tokens.ink, tokens.bg, null),
    MindToastVariant.success => (
        tokens.success,
        tokens.onSuccess,
        Icons.check_circle_outline_rounded,
      ),
    MindToastVariant.warning => (
        tokens.warning,
        tokens.onWarning,
        Icons.info_outline_rounded,
      ),
    MindToastVariant.error => (
        tokens.safety,
        tokens.onSafety,
        Icons.error_outline_rounded,
      ),
  };

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay != null) {
    if (_activeToastEntry?.mounted == true) {
      _activeToastEntry!.remove();
    }
    _activeToastEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _MindToastOverlay(
        message: message,
        backgroundColor: bg,
        foregroundColor: fg,
        icon: icon,
        radius: tokens.inputRadius,
        duration: duration,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (_activeToastEntry == entry) {
            _activeToastEntry = null;
          }
        },
      ),
    );
    _activeToastEntry = entry;
    overlay.insert(entry);
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
        ),
        content: _MindToastBody(
          message: message,
          foregroundColor: fg,
          icon: icon,
        ),
      ),
    );
}

class _MindToastBody extends StatelessWidget {
  const _MindToastBody({
    required this.message,
    required this.foregroundColor,
    this.icon,
  });

  final String message;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            message,
            textAlign: icon == null ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: LabTheme.fontFamily,
              fontFamilyFallback: LabTheme.fontFallback,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MindToastOverlay extends StatefulWidget {
  const _MindToastOverlay({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.radius,
    required this.duration,
    required this.onDismissed,
    this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final double radius;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_MindToastOverlay> createState() => _MindToastOverlayState();
}

class _MindToastOverlayState extends State<_MindToastOverlay> {
  Timer? _dismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, () {
      if (!mounted) return;
      setState(() => _visible = false);
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.radius),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      child: _MindToastBody(
                        message: widget.message,
                        foregroundColor: widget.foregroundColor,
                        icon: widget.icon,
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
