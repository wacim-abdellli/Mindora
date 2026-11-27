import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../domain/recovery_ledger_model.dart';

/// Overflow-safe Empirical Recovery Ledger card shared by Insights (Patient)
/// and Clinician Dossier (Psychiatrist) views.
class ObservedStabilizersCard extends StatefulWidget {
  const ObservedStabilizersCard({
    super.key,
    required this.ledger,
    required this.strings,
  });

  final RecoveryLedger ledger;
  final AppStrings strings;

  @override
  State<ObservedStabilizersCard> createState() =>
      _ObservedStabilizersCardState();
}

class _ObservedStabilizersCardState extends State<ObservedStabilizersCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = widget.strings;
    final allItems = widget.ledger.stabilizers.take(5).toList(growable: false);
    if (allItems.isEmpty) return const SizedBox.shrink();
    final items = _showAll ? allItems : allItems.take(3).toList(growable: false);

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.spa_outlined,
                size: 18,
                color: tokens.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.observedStabilizersTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.observedStabilizersSub,
            style: TextStyle(fontSize: 12.5, color: tokens.ink2, height: 1.35),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final detailParts = <String>[
              '${item.totalOccurrences}x',
              if (item.avgSameDayShift != null && item.avgSameDayShift! < 0)
                strings.sameDayShiftStat(item.avgSameDayShift!)
              else if (item.avgCoOccurringIntensity != null)
                strings.stabilizerAvgMoodStat(item.avgCoOccurringIntensity!),
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  border: Border.all(color: tokens.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 16,
                          color: tokens.ink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.localizedLabel(strings),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 24),
                      child: Text(
                        detailParts.join(' · '),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.ink2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (allItems.length > 3)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: tokens.ink,
                ),
                child: Text(
                  _showAll
                      ? strings.showLessLabel
                      : strings.showAllCountLabel(allItems.length),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            strings.stabilizerDisclaimer,
            style: TextStyle(
              fontSize: 12.0,
              color: tokens.ink3,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
