import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

/// Displays a calm pill toast (`tokens.ink` fill, `tokens.bg` text, 2.2s duration).
void showMindToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final tokens = context.tokens;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.ink,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.inputRadius),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: LabTheme.fontFamily,
            fontFamilyFallback: LabTheme.fontFallback,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: tokens.bg,
          ),
        ),
      ),
    );
}
