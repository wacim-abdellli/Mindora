import 'package:flutter/material.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Calm pill-based segmented selector driven exclusively by [MindTokens].
///
/// Enforces minimum 48dp tap targets per option, non-color selection cues
/// (surface3 pill + active border + font weight), reduced-motion safety, and RTL layout.
class MindSegmented extends StatelessWidget {
  const MindSegmented({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  }) : assert(labels.length >= 2, 'MindSegmented requires at least two options');

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final innerRadius = (tokens.buttonRadius - 3).clamp(8.0, 16.0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: tokens.line, width: 1.0),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: MindPressable(
                onPressed: () => onChanged(i),
                selected: index == i,
                semanticLabel: labels[i],
                borderRadius: BorderRadius.circular(innerRadius),
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: labels.length >= 4 ? 4 : 10,
                    vertical: 8,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? tokens.surface3 : Colors.transparent,
                    borderRadius: BorderRadius.circular(innerRadius),
                    border: index == i
                        ? Border.all(
                            color: tokens.segmentedActiveBorder,
                            width: 1.0,
                          )
                        : null,
                    boxShadow: index == i
                        ? tokens.segmentedActiveShadows
                        : const <BoxShadow>[],
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: labels.length >= 4 ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: labels.length >= 4 ? 12.5 : 13.5,
                      height: 1.2,
                      fontWeight: index == i
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: index == i ? tokens.ink : tokens.ink2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
