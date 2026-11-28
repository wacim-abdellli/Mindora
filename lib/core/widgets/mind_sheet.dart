import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Presents a token-styled modal bottom sheet (`surface` fill, top radius `28`,
/// `1px line` top border, `tokens.scrim` backdrop, grabber bar, optional close button).
Future<T?> showMindSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  bool showGrabHandle = true,
  bool showCloseButton = false,
  String? title,
}) {
  final tokens = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: tokens.scrim,
    elevation: 0,
    builder: (sheetContext) {
      return MindSheet(
        showGrabHandle: showGrabHandle,
        showCloseButton: showCloseButton,
        title: title,
        child: builder(sheetContext),
      );
    },
  );
}

/// Modal bottom sheet container driven exclusively by [MindTokens].
class MindSheet extends StatelessWidget {
  const MindSheet({
    super.key,
    required this.child,
    this.showGrabHandle = true,
    this.showCloseButton = false,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 28),
  });

  final Widget child;
  final bool showGrabHandle;
  final bool showCloseButton;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.90;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final isWide = size.width >= 840;

    final sheet = Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: isWide ? 600 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(
          top: BorderSide(color: tokens.line, width: 1.0),
          left: isWide
              ? BorderSide(color: tokens.line, width: 1.0)
              : BorderSide.none,
          right: isWide
              ? BorderSide(color: tokens.line, width: 1.0)
              : BorderSide.none,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showGrabHandle) ...[
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: tokens.lineStrong,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
              if (title != null || showCloseButton) ...[
                Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      )
                    else
                      const Spacer(),
                    if (showCloseButton)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close_rounded, color: tokens.ink2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      child: isWide ? Center(heightFactor: 1.0, child: sheet) : sheet,
    );
  }
}
