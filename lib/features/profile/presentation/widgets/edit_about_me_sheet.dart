import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/psychological_profile_model.dart';

class EditAboutMeSheet extends ConsumerStatefulWidget {
  const EditAboutMeSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(
    BuildContext context,
    PsychologicalProfileModel profile,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAboutMeSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditAboutMeSheet> createState() => _EditAboutMeSheetState();
}

class _EditAboutMeSheetState extends ConsumerState<EditAboutMeSheet> {
  late TextEditingController _nameController;
  late TextEditingController _introController;
  late TextEditingController _additionalController;
  late String _selectedAgeRange;
  late String _selectedLanguage;

  static const List<String> _ageRanges = [
    'under_18',
    '18-24',
    '25-44',
    '45-64',
    '65+',
    'prefer_not_to_say',
  ];

  static String _normalizeAgeRange(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('–', '-');
    switch (normalized) {
      case 'under 18':
      case '<18':
      case 'under_18':
      case 'moins de 18 ans':
        return 'under_18';
      case '25-34':
      case '35-44':
      case '25-44':
        return '25-44';
      case '45-54':
      case '55-64':
      case '45-64':
      case '55+':
        return '45-64';
      case 'prefer not to say':
      case 'prefer_not_to_say':
      case '':
        return 'prefer_not_to_say';
      default:
        return _ageRanges.contains(normalized)
            ? normalized
            : 'prefer_not_to_say';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.preferredName);
    _introController = TextEditingController(
      text: widget.profile.personalIntroduction,
    );
    _additionalController = TextEditingController(
      text: widget.profile.additionalContext,
    );
    _selectedAgeRange = _normalizeAgeRange(widget.profile.ageRange);
    _selectedLanguage = widget.profile.preferredLanguage.isNotEmpty
        ? widget.profile.preferredLanguage
        : 'en';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref
        .read(profileControllerProvider.notifier)
        .updateAboutMe(
          preferredName: _nameController.text.trim(),
          ageRange: _selectedAgeRange,
          preferredLanguage: _selectedLanguage,
          personalIntroduction: _introController.text.trim(),
          additionalContext: _additionalController.text.trim(),
        );
    await ref
        .read(localeControllerProvider.notifier)
        .setLanguage(AppLanguage.fromCode(_selectedLanguage));

    if (mounted) {
      Navigator.pop(context);
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),

                Text(
                  strings.sectionAboutMe,
                  style: LabTheme.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.sectionAboutMeDesc,
                  style: TextStyle(fontSize: 12.5, color: textSecondary),
                ),

                const SizedBox(height: 20),

                // Preferred Name
                Text(
                  strings.isArabic
                      ? 'الاسم أو اللقب المفضل'
                      : (strings.isFrench
                            ? 'Prénom ou surnom'
                            : 'Preferred name'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 13.0, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'كيف تحب أن نناديك؟'
                        : (strings.isFrench
                              ? 'Comment souhaitez-vous être appelé(e) ?'
                              : 'How should we address you?'),
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: context.tokens.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.tokens.ink),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Age Range
                Text(
                  strings.isArabic
                      ? 'الفئة العمرية (اختياري)'
                      : (strings.isFrench
                            ? 'Tranche d’âge (optionnel)'
                            : 'Age range (optional)'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _ageRanges.map((range) {
                    final isSelected = _selectedAgeRange == range;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAgeRange = range);
                      },
                      borderRadius: BorderRadius.circular(
                        context.tokens.chipRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.tokens.cardTint
                              : context.tokens.surface2,
                          borderRadius: BorderRadius.circular(
                            context.tokens.chipRadius,
                          ),
                          border: Border.all(
                            color: isSelected ? context.tokens.ink : border,
                            width: isSelected ? 1 : 0.8,
                          ),
                        ),
                        child: Text(
                          strings.ageRangeDisplayName(range),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? context.tokens.ink
                                : textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Personal Introduction
                Text(
                  strings.isArabic
                      ? 'مقدمة شخصية قصيرة'
                      : (strings.isFrench
                            ? 'Présentation personnelle'
                            : 'Personal introduction'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _introController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13.0, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'مقدمة حرة ومريحة عن نفسك وتجربتك...'
                        : (strings.isFrench
                              ? 'Quelques mots simples que vous souhaitez partager...'
                              : 'Brief introductory thoughts you feel comfortable sharing...'),
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: context.tokens.surface2,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.tokens.ink),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Action
                BouncingWidget(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.tokens.ink,
                      borderRadius: BorderRadius.circular(
                        context.tokens.buttonRadius,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      strings.isArabic
                          ? 'حفظ المعلومات'
                          : (strings.isFrench
                                ? 'Enregistrer'
                                : 'Save changes'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.tokens.bg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
