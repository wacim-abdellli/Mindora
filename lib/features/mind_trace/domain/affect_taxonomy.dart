import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import 'mind_trace_model.dart';

/// Affective valence dimension grounded in circumplex mood models.
enum AffectValence { positive, neutral, low, distressed }

/// Autonomic arousal dimension for somatic differentiation.
enum AffectArousal { low, moderate, high }

/// Clinical affect clusters aligned with mood-disorder and trauma-informed
/// psychiatric observation (strictly observational, non-diagnostic).
enum ClinicalAffectCluster {
  euthymic,
  depressiveAnhedonic,
  anxiousHyperarousal,
  irritableFriction,
  activatedWired,
  cognitiveDissociative,
}

/// Clinically grounded nuanced co-occurring feeling descriptor (Tier 2).
@immutable
class NuancedFeeling {
  const NuancedFeeling({
    required this.key,
    required this.english,
    required this.french,
    required this.arabic,
    required this.icon,
    required this.valence,
    required this.arousal,
    required this.cluster,
    required this.primaryAffinity,
  });

  final String key;
  final String english;
  final String french;
  final String arabic;
  final IconData icon;
  final AffectValence valence;
  final AffectArousal arousal;
  final ClinicalAffectCluster cluster;
  final List<String> primaryAffinity;

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabic;
    if (strings.isFrench) return french;
    return english;
  }
}

/// Two-tier psychiatric affect taxonomy:
/// - Tier 1: 5 core somatic mood anchors (`calm`, `anxious`, `frustrated`, `heavy`, `restless`)
/// - Tier 2: 19 multi-select nuanced co-occurring feelings across 6 clinical clusters
abstract final class AffectTaxonomy {
  static const Set<String> coreMoodKeys = {
    'calm',
    'anxious',
    'frustrated',
    'heavy',
    'restless',
  };

  static const List<NuancedFeeling> nuancedFeelings = [
    // Positive / Euthymic
    NuancedFeeling(
      key: 'hopeful',
      english: 'Hopeful',
      french: 'Plein d’espoir',
      arabic: 'متفائل',
      icon: Icons.wb_twilight_rounded,
      valence: AffectValence.positive,
      arousal: AffectArousal.moderate,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm'],
    ),
    NuancedFeeling(
      key: 'grateful',
      english: 'Grateful',
      french: 'Reconnaissant',
      arabic: 'ممتن',
      icon: Icons.favorite_outline_rounded,
      valence: AffectValence.positive,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm'],
    ),
    NuancedFeeling(
      key: 'content',
      english: 'Content',
      french: 'Serein',
      arabic: 'مرتاح',
      icon: Icons.wb_sunny_outlined,
      valence: AffectValence.positive,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm'],
    ),
    NuancedFeeling(
      key: 'motivated',
      english: 'Motivated',
      french: 'Motivé',
      arabic: 'متحمس',
      icon: Icons.trending_up_rounded,
      valence: AffectValence.positive,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm', 'restless'],
    ),
    NuancedFeeling(
      key: 'relieved',
      english: 'Relieved',
      french: 'Soulagé',
      arabic: 'مرتاح البال',
      icon: Icons.air_rounded,
      valence: AffectValence.positive,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm'],
    ),
    NuancedFeeling(
      key: 'focused',
      english: 'Focused',
      french: 'Concentré',
      arabic: 'مركز',
      icon: Icons.center_focus_strong_outlined,
      valence: AffectValence.neutral,
      arousal: AffectArousal.moderate,
      cluster: ClinicalAffectCluster.euthymic,
      primaryAffinity: ['calm'],
    ),

    // Depressive / Anhedonic
    NuancedFeeling(
      key: 'sad',
      english: 'Sad',
      french: 'Triste',
      arabic: 'حزين',
      icon: Icons.water_drop_outlined,
      valence: AffectValence.low,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.depressiveAnhedonic,
      primaryAffinity: ['heavy'],
    ),
    NuancedFeeling(
      key: 'numb',
      english: 'Numb',
      french: 'Engourdi',
      arabic: 'مبلّد',
      icon: Icons.lens_blur_rounded,
      valence: AffectValence.low,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.depressiveAnhedonic,
      primaryAffinity: ['heavy'],
    ),
    NuancedFeeling(
      key: 'exhausted',
      english: 'Exhausted',
      french: 'Épuisé',
      arabic: 'مرهق برشا',
      icon: Icons.battery_alert_outlined,
      valence: AffectValence.low,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.depressiveAnhedonic,
      primaryAffinity: ['heavy', 'anxious', 'frustrated'],
    ),
    NuancedFeeling(
      key: 'lonely',
      english: 'Lonely',
      french: 'Isolé',
      arabic: 'وحداني',
      icon: Icons.person_outline_rounded,
      valence: AffectValence.low,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.depressiveAnhedonic,
      primaryAffinity: ['heavy'],
    ),
    NuancedFeeling(
      key: 'guilty',
      english: 'Guilty',
      french: 'Coupable',
      arabic: 'حاس بالذنب',
      icon: Icons.anchor_rounded,
      valence: AffectValence.distressed,
      arousal: AffectArousal.moderate,
      cluster: ClinicalAffectCluster.depressiveAnhedonic,
      primaryAffinity: ['heavy'],
    ),

    // Anxious / Hyperarousal
    NuancedFeeling(
      key: 'overwhelmed',
      english: 'Overwhelmed',
      french: 'Submergé',
      arabic: 'مخنوق',
      icon: Icons.waves_outlined,
      valence: AffectValence.distressed,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.anxiousHyperarousal,
      primaryAffinity: ['anxious', 'frustrated', 'restless'],
    ),
    NuancedFeeling(
      key: 'on_edge',
      english: 'On edge',
      french: 'À cran',
      arabic: 'على أعصابي',
      icon: Icons.sensors_outlined,
      valence: AffectValence.distressed,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.anxiousHyperarousal,
      primaryAffinity: ['anxious', 'frustrated', 'restless'],
    ),
    NuancedFeeling(
      key: 'vulnerable',
      english: 'Vulnerable',
      french: 'Vulnérable',
      arabic: 'حسّاس برشا',
      icon: Icons.shield_outlined,
      valence: AffectValence.low,
      arousal: AffectArousal.moderate,
      cluster: ClinicalAffectCluster.anxiousHyperarousal,
      primaryAffinity: ['anxious'],
    ),

    // Activated / Wired
    NuancedFeeling(
      key: 'wired',
      english: 'Wired',
      french: 'Surexcité',
      arabic: 'مشحون',
      icon: Icons.flash_on_outlined,
      valence: AffectValence.neutral,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.activatedWired,
      primaryAffinity: ['restless', 'anxious', 'frustrated'],
    ),

    // Irritable / Friction
    NuancedFeeling(
      key: 'angry',
      english: 'Angry',
      french: 'En colère',
      arabic: 'متغشّش',
      icon: Icons.local_fire_department_outlined,
      valence: AffectValence.distressed,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.irritableFriction,
      primaryAffinity: ['frustrated'],
    ),
    NuancedFeeling(
      key: 'irritable',
      english: 'Irritable',
      french: 'Irritable',
      arabic: 'متقلّق بسرعة',
      icon: Icons.electric_bolt_outlined,
      valence: AffectValence.distressed,
      arousal: AffectArousal.high,
      cluster: ClinicalAffectCluster.irritableFriction,
      primaryAffinity: ['frustrated', 'restless'],
    ),

    // Cognitive / Dissociative
    NuancedFeeling(
      key: 'disconnected',
      english: 'Disconnected',
      french: 'Déconnecté',
      arabic: 'منفصل عالواقع',
      icon: Icons.link_off_rounded,
      valence: AffectValence.low,
      arousal: AffectArousal.low,
      cluster: ClinicalAffectCluster.cognitiveDissociative,
      primaryAffinity: ['heavy', 'anxious'],
    ),
    NuancedFeeling(
      key: 'confused',
      english: 'Confused',
      french: 'Confus',
      arabic: 'مشوش',
      icon: Icons.help_outline_rounded,
      valence: AffectValence.neutral,
      arousal: AffectArousal.moderate,
      cluster: ClinicalAffectCluster.cognitiveDissociative,
      primaryAffinity: ['restless'],
    ),
  ];

  /// Returns feelings ordered with the 6 affinity items for [coreKey] first.
  static List<NuancedFeeling> prioritizedForCore(String coreKey) {
    final norm = _normalizeCore(coreKey);
    final preferred = <NuancedFeeling>[];
    final rest = <NuancedFeeling>[];
    for (final feeling in nuancedFeelings) {
      if (feeling.primaryAffinity.contains(norm)) {
        preferred.add(feeling);
      } else {
        rest.add(feeling);
      }
    }
    return [...preferred, ...rest];
  }

  static NuancedFeeling? byKey(String raw) {
    final norm = raw.trim().toLowerCase();
    if (norm.isEmpty) return null;
    for (final f in nuancedFeelings) {
      if (f.key == norm ||
          f.english.toLowerCase() == norm ||
          f.french.toLowerCase() == norm ||
          f.arabic.trim().toLowerCase() == norm) {
        return f;
      }
    }
    return null;
  }

  static String localizedLabel(String raw, AppStrings strings) {
    final match = byKey(raw);
    if (match != null) return match.localized(strings);
    final core = _normalizeCoreOrNull(raw);
    if (core != null) {
      return switch (core) {
        'calm' => strings.moodCalm,
        'anxious' => strings.moodAnxious,
        'frustrated' => strings.moodFrustrated,
        'heavy' => strings.moodHeavy,
        'restless' => strings.moodRestless,
        _ => raw,
      };
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  static bool isCoreMood(String raw) => _normalizeCoreOrNull(raw) != null;

  static String _normalizeCore(String raw) =>
      _normalizeCoreOrNull(raw) ?? 'calm';

  static String? _normalizeCoreOrNull(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (key == 'calm' || key == 'calme' || key == 'هادئ') return 'calm';
    if (key == 'anxious' || key == 'anxieux' || key == 'قلق' || key == 'متوتر') {
      return 'anxious';
    }
    if (key == 'frustrated' || key == 'frustré' || key == 'محبط') {
      return 'frustrated';
    }
    if (key == 'heavy' || key == 'lourd' || key == 'ثقيل') return 'heavy';
    if (key == 'restless' ||
        key == 'agité' ||
        key == 'مشتت' ||
        key == 'متقلب' ||
        key == 'متململ') {
      return 'restless';
    }
    return null;
  }

  /// Extracts normalized nuanced / secondary emotion keys from a trace,
  /// excluding the primary core mood and redundant core-synonym entries.
  static List<String> extractNuancedKeys(MindTraceModel trace) {
    final primaryCore = _normalizeCoreOrNull(trace.overallMood);
    final seen = <String>{};
    final result = <String>[];
    for (final raw in trace.selectedEmotions) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final match = byKey(trimmed);
      final canonical = match?.key ?? trimmed;
      final lower = canonical.toLowerCase();
      if (primaryCore != null && _normalizeCoreOrNull(lower) == primaryCore) {
        continue;
      }
      if (seen.add(lower)) {
        result.add(canonical);
      }
    }
    return result;
  }
}
