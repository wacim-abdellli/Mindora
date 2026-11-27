import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/clinical_condition_catalog.dart';
import '../../domain/condition_type.dart';
import '../../domain/diagnostic_status.dart';
import '../../domain/psychological_profile_model.dart';
import 'clinical_condition_search_sheet.dart';
import 'condition_status_bottom_sheet.dart';

class EditExperiencesSheet extends ConsumerWidget {
  const EditExperiencesSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExperiencesSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProfile = ref.watch(profileControllerProvider).value ?? profile;
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    final bg = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.sectionExperiences,
                        style: LabTheme.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.conditionsSectionSubtitle,
                        style: TextStyle(fontSize: 12.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    strings.isArabic ? 'تم' : (strings.isFrench ? 'Terminé' : 'Done'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.tokens.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.clinicalTracksSectionTitle,
                          style: LabTheme.textStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final track
                                in ClinicalConditionCatalog.resolveTracks(liveProfile))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: context.tokens.cardTint,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: border),
                                ),
                                child: Text(
                                  track.localizedTitle(strings),
                                  style: LabTheme.textStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('profile-search-300-conditions-btn'),
                          onPressed: () async {
                            final res = await ClinicalConditionSearchSheet.show(
                              context,
                              initialConditionIds: liveProfile.selectedConditionIds,
                              initialTrackIds: liveProfile.selectedTrackIds,
                            );
                            if (res != null) {
                              await ref
                                  .read(profileControllerProvider.notifier)
                                  .saveFullProfile(
                                    liveProfile.copyWith(
                                      selectedConditionIds:
                                          res.selectedConditionIds,
                                      selectedTrackIds: res.selectedTrackIds,
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                            }
                          },
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text(strings.search300ConditionsCta),
                        ),
                      ],
                    ),
                  ),
                  ...ExperienceCategory.values.map((cat) {
                  final catTitle = cat.localizedTitle(strings);
                  final conditionsInCat = cat.conditions;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catTitle,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: context.tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: conditionsInCat.map((cond) {
                            final entry = liveProfile.getEntry(cond);
                            final isSelected = entry != null;

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ConditionStatusBottomSheet.show(
                                  context,
                                  condition: cond,
                                  initialStatus: entry?.status ??
                                      DiagnosticStatus.selfIdentifiedExploring,
                                  initialNote: entry?.note ?? '',
                                  isSelected: isSelected,
                                );
                              },
                              borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.tokens.cardTint
                                      : context.tokens.surface2,
                                  borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                                  border: Border.all(
                                    color: isSelected ? context.tokens.ink : border,
                                    width: isSelected ? 1 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(Icons.check_rounded, size: 12, color: context.tokens.ink),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      strings.conditionName(cond),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? context.tokens.ink
                                            : textSecondary,
                                      ),
                                    ),
                                    if (isSelected && entry.status != DiagnosticStatus.preferNotToSay) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.tokens.surface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: border, width: 0.6),
                                        ),
                                        child: Text(
                                          strings.statusName(entry.status),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

