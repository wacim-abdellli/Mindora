import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_button.dart';

/// Displays a token-styled confirmation dialog returning `true` if confirmed.
Future<bool> showMindConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final tokens = context.tokens;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: tokens.scrim,
    builder: (dialogCtx) => MindDialog(
      title: title,
      body: body,
      icon: icon,
      destructive: destructive,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      onCancel: () => Navigator.of(dialogCtx).pop(false),
      onConfirm: () => Navigator.of(dialogCtx).pop(true),
    ),
  );
  return result == true;
}

/// Token-driven accessible dialog (`maxWidth: 440`, 20dp radius, >= 48dp CTAs).
class MindDialog extends StatelessWidget {
  const MindDialog({
    super.key,
    required this.title,
    this.body,
    this.content,
    this.icon,
    this.destructive = false,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.maxWidth = 440,
  });

  final String title;
  final String? body;
  final Widget? content;
  final IconData? icon;
  final bool destructive;
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderColor = destructive ? tokens.dangerBorder : tokens.line;
    final titleColor = destructive ? tokens.safety : tokens.ink;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.rowRadius),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: tokens.shadows,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: destructive
                              ? tokens.safetySoft
                              : tokens.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: 20,
                          color: destructive ? tokens.safety : tokens.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: icon != null ? 4 : 0),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: LabTheme.fontFamily,
                            fontFamilyFallback: LabTheme.fontFallback,
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (body != null && body!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    body!,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: 14.5,
                      height: 1.5,
                      color: tokens.ink2,
                    ),
                  ),
                ],
                if (content != null) ...[
                  const SizedBox(height: 14),
                  content!,
                ],
                if (cancelLabel != null || confirmLabel != null) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (cancelLabel != null)
                        MindButton(
                          text: cancelLabel!,
                          variant: MindButtonVariant.secondary,
                          size: MindButtonSize.md,
                          onPressed:
                              onCancel ?? () => Navigator.of(context).maybePop(),
                        ),
                      if (confirmLabel != null)
                        MindButton(
                          text: confirmLabel!,
                          variant: destructive
                              ? MindButtonVariant.danger
                              : MindButtonVariant.primary,
                          size: MindButtonSize.md,
                          onPressed: onConfirm,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
