import 'package:flutter/material.dart';

/// Canonical adaptive viewport breakpoints shared across Patient and Doctor editions.
abstract final class MindBreakpoints {
  static const double compactMax = 599.0;
  static const double mediumMin = 600.0;
  static const double expandedMin = 840.0;
  static const double largeMin = 1200.0;

  static bool isCompact(double width) => width < mediumMin;
  static bool isMedium(double width) =>
      width >= mediumMin && width < expandedMin;
  static bool isExpanded(double width) => width >= expandedMin;
  static bool isLarge(double width) => width >= largeMin;

  /// Recommended horizontal page margin for [width].
  static double horizontalPadding(double width) {
    if (width >= expandedMin) return 32.0;
    if (width >= mediumMin) return 24.0;
    return 16.0;
  }
}

/// Centers and caps reading/workspace width with adaptive horizontal padding.
class MindPageContainer extends StatelessWidget {
  const MindPageContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: MindBreakpoints.horizontalPadding(width),
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
