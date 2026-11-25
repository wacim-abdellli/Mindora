import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/psychological_profile_model.dart';
import '../../domain/symptom_catalog.dart';

class EditSymptomsSheet extends ConsumerStatefulWidget {
  const EditSymptomsSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditSymptomsSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditSymptomsSheet> createState() => _EditSymptomsSheetState();
}

class _EditSymptomsSheetState extends ConsumerState<EditSymptomsSheet> {
  late Set<String> _selectedSymptoms;
  late TextEditingController _notesController;
  late TextEditingController _customSymptomController;

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = Set.from(widget.profile.selectedSymptoms);
    _notesController = TextEditingController(
      text: widget.profile.symptomNotes.isNotEmpty
          ? widget.profile.symptomNotes
          : widget.profile.currentDifficulties,
    );
    _customSymptomController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customSymptomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileControllerProvider.notifier).updateSymptoms(
      selectedSymptoms: _selectedSymptoms.toList(),
      symptomNotes: _notesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addCustomSymptom() {
    final text = _customSymptomController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedSymptoms.add(text);
        _customSymptomController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    final bg = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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

              Text(
                strings.sectionSymptoms,
                style: LabTheme.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.sectionSymptomsDesc,
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),

              const SizedBox(height: 12),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ...SymptomCategory.values.map((cat) {
                      final items = SymptomCatalog.byCategory(cat);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(cat.icon, size: 13, color: context.tokens.ink),
                                const SizedBox(width: 6),
                                Text(
                                  cat.localized(strings).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: context.tokens.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: items.map((item) {
                                final label = item.localized(strings);
                                final isSelected = _selectedSymptoms.contains(label) ||
                                    _selectedSymptoms.contains(item.english) ||
                                    _selectedSymptoms.contains(item.french) ||
                                    _selectedSymptoms.contains(item.arabic);

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isSelected) {
                                        _selectedSymptoms.remove(label);
                                        _selectedSymptoms.remove(item.english);
                                        _selectedSymptoms.remove(item.french);
                                        _selectedSymptoms.remove(item.arabic);
                                      } else {
                                        _selectedSymptoms.add(label);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected
                                                ? context.tokens.ink
                                                : textSecondary,
                                          ),
                                        ),
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

                    // Custom Symptom input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customSymptomController,
                            style: TextStyle(fontSize: 12, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: strings.isArabic
                                  ? '+ إضافة تجربة أو صعوبة خاصة...'
                                  : (strings.isFrench
                                      ? '+ Ajouter une expérience personnalisée...'
                                      : '+ Add custom experience...'),
                              hintStyle: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: context.tokens.surface2,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                            ),
                            onSubmitted: (_) => _addCustomSymptom(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: strings.addItemTooltip,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          color: context.tokens.ink,
                          onPressed: _addCustomSymptom,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Free-text field: "What has been difficult for you lately?"
                    Text(
                      (strings.isArabic
                              ? 'ما الذي كان صعباً أو مؤلماً مؤخراً؟'
                              : (strings.isFrench
                                  ? 'QU’EST-CE QUI A ÉTÉ DIFFICILE RÉCEMMENT ?'
                                  : 'WHAT HAS BEEN DIFFICULT LATELY?'))
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: TextStyle(fontSize: 12.5, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: strings.isArabic
                            ? 'دوّن بحرية أي تفاصيل أو صعوبات تود توثيقها...'
                            : (strings.isFrench
                                ? 'Décrivez vos déclencheurs ou défis sans pression...'
                                : 'Describe any patterns, triggers, or challenges without pressure...'),
                        hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: context.tokens.surface2,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.tokens.ink)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Save Action Button
              BouncingWidget(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.tokens.ink,
                    borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (strings.isArabic
                            ? 'حفظ الصعوبات والأعراض'
                            : (strings.isFrench
                                ? 'ENREGISTRER LES DIFFICULTÉS'
                                : 'SAVE SYMPTOMS & DIFFICULTIES'))
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: context.tokens.bg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

