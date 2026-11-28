import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_undo_banner.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/observatory_controllers.dart';
import '../../domain/symptom_entry.dart';
import '../../domain/symptom_report.dart';
import 'custom_symptom_sheet.dart';
import 'symptom_assessment_sheet.dart';

class SymptomLibraryView extends ConsumerStatefulWidget {
  const SymptomLibraryView({super.key});

  @override
  ConsumerState<SymptomLibraryView> createState() => _SymptomLibraryViewState();
}

class _SymptomLibraryViewState extends ConsumerState<SymptomLibraryView> {
  bool _showHistory = false;

  Future<void> _confirmDeleteReport(
    BuildContext context,
    SymptomReport report,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(symptomReportsControllerProvider.notifier);
    await notifier.deleteReport(report.id);
    if (!context.mounted) return;
    showMindUndoBanner(
      context,
      message: strings.itemRemovedUndo,
      undoLabel: strings.undoBtn,
      onUndo: () {
        notifier.recordReport(report);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    final filteredSymptoms = ref.watch(filteredSymptomsProvider);
    final selectedIds = ref.watch(selectedSymptomIdsProvider);
    final activeDomain = ref.watch(selectedDomainFilterProvider);
    final profile = ref.watch(profileControllerProvider).value;
    final reports = ref.watch(symptomReportsControllerProvider).value ?? const <SymptomReport>[];
    final allSymptoms = ref.watch(symptomListControllerProvider).value ?? const <SymptomEntry>[];

    return Column(
      children: [
        // 0. Library vs Saved Reports Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    isAr
                        ? 'مكتبة الأعراض'
                        : (strings.isFrench ? 'Bibliothèque' : 'Symptom Library'),
                  ),
                  selected: !_showHistory,
                  onSelected: (_) => setState(() => _showHistory = false),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: !_showHistory ? FontWeight.w700 : FontWeight.w500,
                    color: !_showHistory ? textPrimary : textSecondary,
                  ),
                  backgroundColor: surfaceColor,
                  selectedColor: tokens.selectedTintFor(tokens.m1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    side: BorderSide(
                      color: !_showHistory ? tokens.m1 : borderColor,
                    ),
                  ),
                  showCheckmark: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    isAr
                        ? 'السجل المحفوظ (${reports.length})'
                        : (strings.isFrench
                            ? 'Historique (${reports.length})'
                            : 'Saved Logs (${reports.length})'),
                  ),
                  selected: _showHistory,
                  onSelected: (_) => setState(() => _showHistory = true),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _showHistory ? FontWeight.w700 : FontWeight.w500,
                    color: _showHistory ? textPrimary : textSecondary,
                  ),
                  backgroundColor: surfaceColor,
                  selectedColor: tokens.selectedTintFor(tokens.m1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    side: BorderSide(
                      color: _showHistory ? tokens.m1 : borderColor,
                    ),
                  ),
                  showCheckmark: false,
                ),
              ),
            ],
          ),
        ),
        if (_showHistory) ...[
          const SizedBox(height: 10),
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isAr
                            ? 'لم يتم حفظ أي تقييم للأعراض بعد. اختر عرضاً من المكتبة لتسجيل ملاحظة.'
                            : (strings.isFrench
                                ? 'Aucun bilan enregistré pour le moment. Sélectionnez un ressenti dans la bibliothèque pour le noter.'
                                : 'No symptom logs saved yet. Select one or more items from the library to record an observation.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12.5, height: 1.45),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      final symptomTitles = r.symptomIds.map((id) {
                        final match = allSymptoms.where((s) => s.id == id);
                        return match.isNotEmpty ? match.first.title(strings) : id;
                      }).join(', ');
                      final timeStr =
                          '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(tokens.cardRadius),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${r.dateKey} • $timeStr',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tokens.selectedTintFor(tokens.m1),
                                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                                    border: Border.all(color: tokens.m1),
                                  ),
                                  child: Text(
                                    '${r.intensity}/10',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: strings.deleteEntryBtn,
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
                                  onPressed: () => _confirmDeleteReport(context, r, strings, tokens),
                                ),
                              ],
                            ),
                            if (symptomTitles.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                symptomTitles,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                            if (r.aiAnalysis != null && r.aiAnalysis!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                r.aiAnalysis!.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                            if (r.stabilizingStrategy != null &&
                                r.stabilizingStrategy!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tokens.cardTintFor(tokens.m1),
                                  borderRadius: BorderRadius.circular(tokens.rowRadius),
                                  border: Border.all(
                                    color: tokens.m1.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  r.stabilizingStrategy!.trim(),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ] else ...[
        // 1. Search Bar & Add Custom Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (q) => ref.read(symptomSearchQueryProvider.notifier).setQuery(q),
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'ابحث في كافة الأعراض والتجارب...'
                        : (strings.isFrench
                            ? 'Rechercher parmi tous les ressentis...'
                            : 'Search across all symptoms...'),
                    hintStyle: TextStyle(
                      color: tokens.ink3,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
                    filled: true,
                    fillColor: tokens.surface2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.inputRadius),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.inputRadius),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.inputRadius),
                      borderSide: BorderSide(color: tokens.focusRing, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: isAr
                    ? 'إضافة تجربة خاصة'
                    : (strings.isFrench
                        ? 'Ajouter un ressenti personnalisé'
                        : 'Add custom symptom'),
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.iconButtonRadius)),
                ),
                onPressed: () => CustomSymptomSheet.show(context),
              ),
            ],
          ),
        ),

        // 2. Domain / Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(isAr ? 'الكل' : (strings.isFrench ? 'Tout' : 'All')),
                selected: activeDomain == null,
                onSelected: (_) =>
                    ref.read(selectedDomainFilterProvider.notifier).select(null),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: activeDomain == null ? FontWeight.w700 : FontWeight.w500,
                  color: activeDomain == null ? textPrimary : textSecondary,
                ),
                backgroundColor: surfaceColor,
                selectedColor: tokens.selectedTintFor(tokens.m1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  side: BorderSide(
                    color: activeDomain == null ? tokens.m1 : borderColor,
                  ),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              ...SymptomDomain.values.map((d) {
                final isSelected = activeDomain == d;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    label: Text(d.localized(strings)),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(selectedDomainFilterProvider.notifier).select(
                            isSelected ? null : d),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? textPrimary : textSecondary,
                    ),
                    backgroundColor: surfaceColor,
                    selectedColor: tokens.selectedTintFor(tokens.m1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      side: BorderSide(
                        color: isSelected ? tokens.m1 : borderColor,
                      ),
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Symptoms List
        Expanded(
          child: filteredSymptoms.isEmpty
              ? Center(
                  child: Text(
                    isAr
                        ? 'لم يتم العثور على أعراض مطابقة'
                        : (strings.isFrench
                            ? 'Aucun ressenti correspondant trouvé'
                            : 'No matching symptoms found'),
                    style: TextStyle(color: textSecondary, fontSize: 12.5),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filteredSymptoms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final symptom = filteredSymptoms[index];
                    final isSelected = selectedIds.contains(symptom.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(tokens.rowRadius),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedSymptomIdsProvider.notifier).toggle(symptom.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.selectedTintFor(tokens.m1)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(tokens.rowRadius),
                          border: Border.all(
                            color: isSelected ? tokens.m1 : borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: tokens.m1,
                              checkColor: tokens.onMood,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (_) {
                                ref.read(selectedSymptomIdsProvider.notifier).toggle(symptom.id);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          symptom.title(strings),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (symptom.isCustom)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tokens.selectedTintFor(MindTokens.moodRestless),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAr
                                                ? 'خاص'
                                                : (strings.isFrench
                                                    ? 'Perso'
                                                    : 'Custom'),
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w700,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                      if (profile?.selectedSymptoms.contains(symptom.id) == true) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tokens.selectedTintFor(tokens.m1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAr
                                                ? 'من ملفك'
                                                : (strings.isFrench
                                                    ? 'Profil'
                                                    : 'Profile'),
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    symptom.description(strings),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 4. Floating Multi-Symptom Action Bar
        if (selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: tokens.shadows,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? '${selectedIds.length} تجارب محددة'
                              : (strings.isFrench
                                    ? '${selectedIds.length} signes sélectionnés'
                                    : '${selectedIds.length} symptoms selected'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              ref.read(selectedSymptomIdsProvider.notifier).clear(),
                          child: Text(
                            isAr
                                ? 'إلغاء التحديد'
                                : (strings.isFrench
                                    ? 'Tout désélectionner'
                                    : 'Clear selection'),
                            style: TextStyle(fontSize: 12.5, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      final all = ref.read(filteredSymptomsProvider);
                      final selected =
                          all.where((s) => selectedIds.contains(s.id)).toList();
                      SymptomAssessmentSheet.show(context, selectedSymptoms: selected);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.ink,
                      foregroundColor: tokens.bg,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(
                      isAr
                          ? 'تقييم الأعراض الآن'
                          : (strings.isFrench
                              ? 'Évaluer ces ressentis'
                              : 'Assess Symptoms'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
