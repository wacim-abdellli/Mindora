import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../controllers/observatory_controllers.dart';
import '../../domain/symptom_entry.dart';

class CustomSymptomSheet extends ConsumerStatefulWidget {
  const CustomSymptomSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomSymptomSheet(),
    );
  }

  @override
  ConsumerState<CustomSymptomSheet> createState() => _CustomSymptomSheetState();
}

class _CustomSymptomSheetState extends ConsumerState<CustomSymptomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  SymptomDomain _selectedDomain = SymptomDomain.mood;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveSymptom() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final customEntry = SymptomEntry(
      id: 'custom_sym_${now.millisecondsSinceEpoch}',
      titleEn: title,
      titleFr: title,
      titleAr: title,
      descriptionEn: _descController.text.trim(),
      descriptionFr: _descController.text.trim(),
      descriptionAr: _descController.text.trim(),
      domain: _selectedDomain,
      isCustom: true,
      createdAt: now,
    );

    ref.read(symptomListControllerProvider.notifier).addCustomSymptom(customEntry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final bg = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.sheetRadius)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: tokens.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr
                        ? 'إضافة تجربة أو عرض خاص'
                        : (strings.isFrench
                            ? 'Ajouter un ressenti personnalisé'
                            : 'Add Custom Symptom / Experience'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.closeBtn,
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Domain selection pills
              Text(
                isAr
                    ? 'المجال:'
                    : (strings.isFrench ? 'Domaine :' : 'Category Domain:'),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SymptomDomain.values.map((d) {
                  final isSelected = d == _selectedDomain;
                  return ChoiceChip(
                    label: Text(d.localized(strings)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDomain = d),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? textPrimary : textSecondary,
                    ),
                    backgroundColor: tokens.surface2,
                    selectedColor: tokens.selectedTintFor(tokens.m1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      side: BorderSide(
                        color: isSelected ? tokens.m1 : borderColor,
                      ),
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title input
              Text(
                isAr
                    ? 'تسمية العرض أو الصعوبة:'
                    : (strings.isFrench
                        ? 'Nom du ressenti / symptôme :'
                        : 'Symptom / Experience Name:'),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'مثلاً: ثقل غير معتاد في الرأس بعد الغداء'
                      : (strings.isFrench
                          ? 'ex. Brouillard mental l’après-midi'
                          : 'e.g., Afternoon mental fog'),
                  hintStyle: TextStyle(color: tokens.ink3, fontSize: 12.5),
                  filled: true,
                  fillColor: tokens.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 14),

              // Description input (Optional)
              Text(
                isAr
                    ? 'ملاحظة توضيحية (اختياري):'
                    : (strings.isFrench
                        ? 'Contexte ou nuance (optionnel) :'
                        : 'Optional Context / Cue:'),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'كيف تحس بالتجربة وما الذي يلازمها؟'
                      : (strings.isFrench
                          ? 'Comment se manifeste ce ressenti ?'
                          : 'How does it usually manifest?'),
                  hintStyle: TextStyle(color: tokens.ink3, fontSize: 12),
                  filled: true,
                  fillColor: tokens.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saveSymptom,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.ink,
                    foregroundColor: tokens.bg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
                  ),
                  child: Text(
                    isAr
                        ? 'حفظ العرض في المرصد'
                        : (strings.isFrench
                            ? 'Enregistrer dans l’Observatoire'
                            : 'Save to Observatory'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

