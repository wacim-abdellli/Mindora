import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_chip.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_sheet.dart';
import '../../../mind_trace/domain/adaptive_tracking_engine.dart';
import '../../../onboarding/domain/app_personalization_engine.dart';
import '../../domain/clinical_condition_catalog.dart';
import '../../domain/psychological_profile_model.dart';

class ConditionPickerResult {
  const ConditionPickerResult({
    required this.selectedConditionIds,
    required this.selectedTrackIds,
  });

  final List<String> selectedConditionIds;
  final List<String> selectedTrackIds;
}

/// Interactive options-first & search-enabled directory of 300+ psychological
/// conditions mapped to 12 actionable Care Tracks. Strictly non-diagnostic.
class ClinicalConditionSearchSheet extends ConsumerStatefulWidget {
  const ClinicalConditionSearchSheet({
    super.key,
    required this.initialConditionIds,
    required this.initialTrackIds,
  });

  final List<String> initialConditionIds;
  final List<String> initialTrackIds;

  static Future<ConditionPickerResult?> show(
    BuildContext context, {
    required List<String> initialConditionIds,
    required List<String> initialTrackIds,
  }) {
    return showMindSheet<ConditionPickerResult>(
      context: context,
      useRootNavigator: true,
      showCloseButton: true,
      title: AppStrings.of(context).search300ConditionsCta,
      builder: (_) => ClinicalConditionSearchSheet(
        initialConditionIds: initialConditionIds,
        initialTrackIds: initialTrackIds,
      ),
    );
  }

  @override
  ConsumerState<ClinicalConditionSearchSheet> createState() =>
      _ClinicalConditionSearchSheetState();
}

class _ClinicalConditionSearchSheetState
    extends ConsumerState<ClinicalConditionSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final Set<String> _conditionIds;
  late final Set<String> _trackIds;
  ClinicalTrack? _filterTrack;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _conditionIds = Set<String>.from(widget.initialConditionIds);
    _trackIds = Set<String>.from(widget.initialTrackIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    final matches = ClinicalConditionCatalog.search(_query).where((item) {
      if (_filterTrack != null && item.track != _filterTrack) return false;
      return true;
    }).toList(growable: false);

    final draftProfile = PsychologicalProfileModel(
      selectedConditionIds: _conditionIds.toList(),
      selectedTrackIds: _trackIds.toList(),
      updatedAt: DateTime.now(),
    );
    final previewMetrics = AdaptiveTrackingEngine.buildDailyRitual(
      profile: draftProfile,
      plan: AppPersonalizationEngine.resolve(draftProfile),
      todayTrace: null,
      hour: 9,
    );

    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.cardTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.line),
            ),
            child: Text(
              strings.conditionsTrackingBanner,
              style: LabTheme.textStyle(
                fontSize: 13,
                height: 1.4,
                color: tokens.ink2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('condition-catalog-search-field'),
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _query = val),
            style: LabTheme.textStyle(fontSize: 15, color: tokens.ink),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: tokens.ink2),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                    )
                  : null,
              hintText: strings.searchConditionsFieldHint,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MindChip(
                  label: strings.showAllEntriesBtn,
                  selected: _filterTrack == null,
                  onTap: () => setState(() => _filterTrack = null),
                ),
                const SizedBox(width: 8),
                for (final track in ClinicalTrack.values) ...[
                  MindChip(
                    key: ValueKey('track-filter-${track.id}'),
                    label: track.localizedTitle(strings),
                    selected:
                        _filterTrack == track || _trackIds.contains(track.id),
                    onTap: () => setState(() {
                      _filterTrack = _filterTrack == track ? null : track;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.34,
            ),
            child: (_query.trim().isEmpty && _filterTrack == null)
                ? ListView.separated(
                    shrinkWrap: true,
                    itemCount: ClinicalTrack.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final track = ClinicalTrack.values[idx];
                      final isTrackSelected = _trackIds.contains(track.id);
                      final selectedConditionCount = ClinicalConditionCatalog.byTrack(track)
                          .where((c) => _conditionIds.contains(c.id))
                          .length;
                      final highlighted = isTrackSelected || selectedConditionCount > 0;
                      return MindPressable(
                        key: ValueKey('track-card-${track.id}'),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filterTrack = track);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 58),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: highlighted ? tokens.cardTint : tokens.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: highlighted ? tokens.primary : tokens.line,
                              width: highlighted ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            track.localizedTitle(strings),
                                            style: LabTheme.textStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: tokens.ink,
                                            ),
                                          ),
                                        ),
                                        if (selectedConditionCount > 0) ...[
                                          const SizedBox(width: 6),
                                          MindBadge(
                                            label: strings.selectedItemsCountLabel(
                                              selectedConditionCount,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      track.localizedSubtitle(strings),
                                      style: LabTheme.textStyle(
                                        fontSize: 12.5,
                                        color: tokens.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                key: ValueKey('track-toggle-${track.id}'),
                                tooltip: track.localizedTitle(strings),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: Icon(
                                  isTrackSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 22,
                                  color: isTrackSelected ? tokens.primary : tokens.ink3,
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (!_trackIds.remove(track.id)) {
                                      _trackIds.add(track.id);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : (matches.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            strings.noMatchingConditionsLabel,
                            textAlign: TextAlign.center,
                            style: LabTheme.textStyle(
                              fontSize: 14,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = matches[idx];
                          final selected = _conditionIds.contains(item.id);
                          return MindPressable(
                            key: ValueKey('condition-item-${item.id}'),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  _conditionIds.remove(item.id);
                                } else {
                                  _conditionIds.add(item.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? tokens.cardTint : tokens.surface2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? tokens.primary : tokens.line,
                                  width: selected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.localized(strings),
                                          style: LabTheme.textStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.track.localizedTitle(strings),
                                          style: LabTheme.textStyle(
                                            fontSize: 12.5,
                                            color: tokens.ink2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.add_circle_outline_rounded,
                                    size: 22,
                                    color: selected ? tokens.primary : tokens.ink3,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.yourDailyQuestionsPreviewLabel,
                  style: LabTheme.textStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in previewMetrics)
                      MindBadge(
                        icon: Icons.auto_awesome_outlined,
                        label: m.localizedClinicianLabel(strings),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MindButton(
            key: const ValueKey('condition-catalog-done-btn'),
            text: strings.doneBtn,
            isFullWidth: true,
            onPressed: () {
              Navigator.of(context).pop(
                ConditionPickerResult(
                  selectedConditionIds: _conditionIds.toList(growable: false),
                  selectedTrackIds: _trackIds.toList(growable: false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
