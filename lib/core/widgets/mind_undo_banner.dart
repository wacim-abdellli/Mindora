import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';

/// Displays a forgiving floating Undo banner for reversible single-item deletions.
///
/// Replaces intrusive confirmation dialogs with a 6-second floating pill
/// (automatically extended to 15 seconds when screen-reader / accessible
/// navigation is active). Calls [onCommit] only if the banner closes without
/// the user pressing Undo.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showMindUndoBanner(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
  VoidCallback? onCommit,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    onCommit?.call();
    return null;
  }

  final tokens = context.tokens;
  final accessible = MediaQuery.accessibleNavigationOf(context);
  final duration = accessible
      ? const Duration(seconds: 15)
      : const Duration(seconds: 6);

  var undone = false;
  messenger.hideCurrentSnackBar();

  final controller = messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.ink,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
      ),
      content: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: tokens.bg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: TextButton(
              onPressed: () {
                if (undone) return;
                undone = true;
                HapticFeedback.selectionClick();
                messenger.hideCurrentSnackBar(
                  reason: SnackBarClosedReason.action,
                );
                onUndo();
              },
              style: TextButton.styleFrom(
                backgroundColor: tokens.bg,
                foregroundColor: tokens.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                ),
              ),
              child: Text(
                undoLabel,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  controller.closed.then((reason) {
    if (!undone && reason != SnackBarClosedReason.action) {
      onCommit?.call();
    }
  });

  return controller;
}
