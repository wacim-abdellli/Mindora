import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/mind_switch.dart';
import '../controllers/profile_controller.dart';
import '../domain/communication_preferences_catalog.dart';
import '../domain/diagnostic_status.dart';
import '../domain/psychological_profile_model.dart';
import 'widgets/edit_about_me_sheet.dart';
import 'widgets/edit_communication_sheet.dart';
import 'widgets/edit_experiences_sheet.dart';
import 'widgets/edit_goals_sheet.dart';
import 'widgets/edit_personal_context_sheet.dart';
import 'widgets/edit_symptoms_sheet.dart';
import 'widgets/privacy_management_sheet.dart';

/// The interactive Psychological Profile Screen.
///
/// Fully satisfies Build Session 03:
/// - 7 Core Sections:
///   1. About Me (Preferred name, age range, language, bio)
///   2. Psychological Experiences (7 categorized clusters + diagnostic status)
///   3. Symptoms & Difficulties (Emotional, thought, behavioral, other + free text)
///   4. Personal Goals (13+ goals + custom goal)
///   5. Personal Context (Unjudged history & what you want companion to understand)
///   6. Communication Preferences (Tone, length, distress preference, disliked approaches)
///   7. Privacy & AI Personalization (Granular consent, local vault isolation, clear/delete)
/// - Vercel Luxury Dark & Master Burgundy aesthetic
/// - Zero emojis
/// - Progressive disclosure with section editors
class PsychologicalProfileView extends ConsumerWidget {
  const PsychologicalProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return profileAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (profile) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poetic Intro Banner
              _buildIntroBanner(
                context,
                isDark,
                strings,
                surfaceColor,
                borderColor,
                textPrimary,
                textSecondary,
              ),

              const SizedBox(height: 18),

              // Section 1: About Me
              _buildSectionCard(
                context: context,
                title: strings.sectionAboutMe,
                subtitle: strings.sectionAboutMeDesc,
                icon: Icons.person_outline_rounded,
                isCompleted: profile.hasAboutMe,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditAboutMeSheet.show(context, profile),
                content: _buildAboutMeSummary(
                  context,
                  profile,
                  isDark,
                  textPrimary,
                  textSecondary,
                  strings,
                ),
              ),

              const SizedBox(height: 14),

              // Section 2: Psychological Experiences (Conditions & Experiences)
              _buildSectionCard(
                context: context,
                title: strings.conditionsSectionTitle,
                subtitle: strings.conditionsSectionSubtitle,
                icon: Icons.psychology_outlined,
                isCompleted: profile.hasExperiences,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditExperiencesSheet.show(context, profile),
                content: _buildExperiencesSummary(
                  context,
                  profile,
                  isDark,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  strings,
                ),
              ),

              const SizedBox(height: 14),

              // Section 3: Symptoms and Difficulties
              _buildSectionCard(
                context: context,
                title: strings.sectionSymptoms,
                subtitle: strings.sectionSymptomsDesc,
                icon: Icons.grain_outlined,
                isCompleted: profile.hasSymptoms,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditSymptomsSheet.show(context, profile),
                content: _buildSymptomsSummary(
                  context,
                  profile,
                  isDark,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  strings,
                ),
              ),

              const SizedBox(height: 14),

              // Section 4: Personal Goals
              _buildSectionCard(
                context: context,
                title: strings.sectionGoals,
                subtitle: strings.sectionGoalsDesc,
                icon: Icons.track_changes_outlined,
                isCompleted: profile.hasGoals,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditGoalsSheet.show(context, profile),
                content: _buildGoalsSummary(
                  context,
                  profile,
                  isDark,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  strings,
                ),
              ),

              const SizedBox(height: 14),

              // Section 5: Personal Context (Optional Context & Details)
              _buildSectionCard(
                context: context,
                title: strings.optionalDetailsTitle,
                subtitle: strings.sectionContextDesc,
                icon: Icons.edit_note_rounded,
                isCompleted: profile.hasContext,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditPersonalContextSheet.show(context, profile),
                content: _buildContextSummary(
                  profile,
                  isDark,
                  textPrimary,
                  textSecondary,
                  strings,
                ),
              ),

              const SizedBox(height: 14),

              // Section 6: Communication Preferences
              _buildSectionCard(
                context: context,
                title: strings.sectionCommunication,
                subtitle: strings.sectionCommunicationDesc,
                icon: Icons.tune_rounded,
                isCompleted: profile.hasCommunicationPrefs,
                strings: strings,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => EditCommunicationSheet.show(context, profile),
                content: _buildCommunicationSummary(
                  context,
                  profile,
                  strings,
                  isDark,
                  borderColor,
                  textPrimary,
                  textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              // Section 7: Privacy and AI Personalization
              _buildPrivacyCard(
                context,
                ref,
                profile,
                isDark,
                strings,
                surfaceColor,
                borderColor,
                textPrimary,
                textSecondary,
              ),

              const SizedBox(height: 24),

              // Save / Confirm Button
              BouncingWidget(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: tokens.surface,
                      content: Text(
                        strings.profileSavedSnackbar,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tokens.ink,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    strings.saveProfileBtn,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: tokens.bg,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // INTRO BANNER
  // ===========================================================================
  Widget _buildIntroBanner(
    BuildContext context,
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: context.tokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FingerprintThreadSignature(size: 20, animated: false),
              const SizedBox(width: 8),
              Text(
                strings.isArabic
                    ? 'نظرة عامة على الملف'
                    : (strings.isFrench
                          ? 'Aperçu du profil'
                          : 'Profile overview'),
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: strings.isArabic ? 0 : 0.2,
                  color: context.tokens.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.tokens.cardTint,
                  borderRadius: BorderRadius.circular(
                    context.tokens.chipRadius,
                  ),
                  border: Border.all(color: context.tokens.line),
                ),
                child: Text(
                  strings.isArabic
                      ? 'حساب محلي آمن'
                      : (strings.isFrench
                            ? 'Compte local sécurisé'
                            : 'Private on device'),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: context.tokens.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.profileIntroQuote,
            style: LabTheme.textStyle(
              fontSize: 14.0,
              height: 1.45,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.profileSecondaryQuote,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION CARD WRAPPER
  // ===========================================================================
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required AppStrings strings,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onEdit,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(context.tokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Icon(icon, size: 16, color: context.tokens.ink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? context.tokens.cardTint
                            : context.tokens.surface2,
                        borderRadius: BorderRadius.circular(
                          context.tokens.chipRadius,
                        ),
                        border: Border.all(
                          color: isCompleted
                              ? context.tokens.ink.withValues(alpha: 0.35)
                              : borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompleted) ...[
                            Icon(
                              Icons.check,
                              size: 10,
                              color: context.tokens.ink,
                            ),
                            const SizedBox(width: 4),
                          ],
                      Text(
                            isCompleted
                                ? strings.profileCompletedBadge
                                : strings.profileNotCompletedBadge,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? context.tokens.ink
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: context.tokens.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 10),

                // Section Specific Content Summary
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1 SUMMARY: ABOUT ME
  // ===========================================================================
  Widget _buildAboutMeSummary(
    BuildContext context,
    PsychologicalProfileModel profile,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    if (!profile.hasAboutMe) {
      return Text(
        strings.isArabic
            ? 'ما زلت ما زدتش اسمك أو نبذة قصيرة.'
            : (strings.isFrench
                  ? 'Pas encore rempli · touchez pour ajouter.'
                  : 'Not set yet · tap to add.'),
        style: TextStyle(fontSize: 12.5, color: textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (profile.preferredName.isNotEmpty) ...[
              Text(
                profile.preferredName,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (profile.ageRange.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.tokens.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.ageRange,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
          ],
        ),
        if (profile.personalIntroduction.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '“${profile.personalIntroduction}”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LabTheme.textStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SECTION 2 SUMMARY: EXPERIENCES (CONDITIONS & EXPERIENCES)
  // ===========================================================================
  Widget _buildExperiencesSummary(
    BuildContext context,
    PsychologicalProfileModel profile,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    if (!profile.hasExperiences) {
      return Text(
        strings.isArabic
            ? 'ما فماش اختيارات حالياً · انقر لاختيار المجالات اللي تهمّك.'
            : (strings.isFrench
                  ? 'Aucune sélection pour l’instant · touchez pour choisir.'
                  : 'None selected yet · tap to choose focus areas.'),
        style: TextStyle(fontSize: 12.5, color: textSecondary),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: profile.conditions.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.tokens.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.tokens.line),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: strings.conditionName(entry.condition),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.ink,
                  ),
                ),
                if (entry.status != DiagnosticStatus.preferNotToSay) ...[
                  TextSpan(
                    text: ' • ${strings.statusName(entry.status)}',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: context.tokens.ink2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // SECTION 3 SUMMARY: SYMPTOMS & DIFFICULTIES
  // ===========================================================================
  Widget _buildSymptomsSummary(
    BuildContext context,
    PsychologicalProfileModel profile,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    if (!profile.hasSymptoms) {
      return Text(
        strings.isArabic
            ? 'ما فماش اختيارات حالياً · انقر للإضافة.'
            : (strings.isFrench
                  ? 'Pas encore rempli · touchez pour ajouter.'
                  : 'Not set yet · tap to add.'),
        style: TextStyle(fontSize: 12.5, color: textSecondary),
      );
    }

    final symptomsList = profile.selectedSymptoms.isNotEmpty
        ? profile.selectedSymptoms
        : (profile.symptomsAndExperiences.isNotEmpty
              ? profile.symptomsAndExperiences.split(', ')
              : <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (symptomsList.isNotEmpty)
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: symptomsList.take(6).map((sym) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.tokens.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  sym,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        if (profile.symptomNotes.isNotEmpty ||
            profile.currentDifficulties.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '“${profile.symptomNotes.isNotEmpty ? profile.symptomNotes : profile.currentDifficulties}”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LabTheme.textStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SECTION 4 SUMMARY: GOALS
  // ===========================================================================
  Widget _buildGoalsSummary(
    BuildContext context,
    PsychologicalProfileModel profile,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    if (!profile.hasGoals) {
      return Text(
        strings.isArabic
            ? 'ما زلت ما خترتش أهداف · انقر للإضافة.'
            : (strings.isFrench
                  ? 'Pas encore rempli · touchez pour ajouter.'
                  : 'Not set yet · tap to add.'),
        style: TextStyle(fontSize: 12.5, color: textSecondary),
      );
    }

    final goalsList = profile.selectedGoals.isNotEmpty
        ? profile.selectedGoals
        : (profile.personalGoals.isNotEmpty
              ? profile.personalGoals.split(', ')
              : <String>[]);

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: goalsList.take(5).map((goal) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.tokens.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            goal,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // SECTION 5 SUMMARY: PERSONAL CONTEXT
  // ===========================================================================
  Widget _buildContextSummary(
    PsychologicalProfileModel profile,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    final contextText = profile.personalContext.isNotEmpty
        ? profile.personalContext
        : profile.notesForAiCompanion;

    if (contextText.isEmpty) {
      return Text(
        strings.isArabic
            ? 'ما فماش ملاحظات بعد · انقر إذا تحب تزيد ملاحظة.'
            : (strings.isFrench
                  ? 'Rien d’ajouté pour l’instant · touchez pour écrire.'
                  : 'Not set yet · tap to share if helpful.'),
        style: TextStyle(fontSize: 12.5, color: textSecondary),
      );
    }

    return Text(
      '“$contextText”',
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: LabTheme.textStyle(
        fontSize: 12.5,
        fontStyle: FontStyle.italic,
        height: 1.35,
        color: textPrimary,
      ),
    );
  }

  // ===========================================================================
  // SECTION 6 SUMMARY: COMMUNICATION PREFERENCES
  // ===========================================================================
  Widget _buildCommunicationSummary(
    BuildContext context,
    PsychologicalProfileModel profile,
    AppStrings strings,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final toneLabel = _resolvePrefLabel(
      profile.communicationTone,
      CommunicationPreferencesCatalog.tones,
      strings,
    );
    final lengthLabel = _resolvePrefLabel(
      profile.responseLength,
      CommunicationPreferencesCatalog.responseLengths,
      strings,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.tokens.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            toneLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.tokens.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            lengthLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _resolvePrefLabel(
    String rawKey,
    List<PrefChoiceItem> catalog,
    AppStrings strings,
  ) {
    for (final item in catalog) {
      if (item.key == rawKey) return item.localized(strings);
    }
    return rawKey.replaceAll('_', ' ');
  }

  // ===========================================================================
  // SECTION 7: PRIVACY & AI PERSONALIZATION
  // ===========================================================================
  Widget _buildPrivacyCard(
    BuildContext context,
    WidgetRef ref,
    PsychologicalProfileModel profile,
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: context.tokens.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.sectionPrivacy,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: context.tokens.ink,
                ),
                tooltip: 'Privacy settings',
                onPressed: () => PrivacyManagementSheet.show(context, profile),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.sectionPrivacyDesc,
            style: TextStyle(fontSize: 12.5, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.shareWithAiToggle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              MindSwitch(
                value: profile.shareWithAiCompanion,
                semanticLabel: strings.shareWithAiToggle,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  ref
                      .read(profileControllerProvider.notifier)
                      .setAiPersonalization(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.shareWithAiDesc,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
