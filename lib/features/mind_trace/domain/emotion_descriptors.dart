import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import 'affect_taxonomy.dart';

/// Descriptor for daily check-in emotion cards.
///
/// Strictly conforms to Session 02 requirements:
/// - 14 explicit emotions (Happy, Calm, Sad, Anxious, Overwhelmed, Angry, Numb,
///   Confused, Motivated, Exhausted, Disconnected, Restless, Mixed emotions, Custom emotion)
/// - Expressive vector icons
/// - ZERO emojis
/// - Trilingual localization (EN, FR, authentic Tunisian AR)
class EmotionDescriptor {
  final String key;
  final String englishLabel;
  final String frenchLabel;
  final String arabicLabel;
  final IconData icon;

  const EmotionDescriptor({
    required this.key,
    required this.englishLabel,
    required this.frenchLabel,
    required this.arabicLabel,
    required this.icon,
  });

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabicLabel;
    if (strings.isFrench) return frenchLabel;
    return englishLabel;
  }

  static const List<EmotionDescriptor> library = [
    EmotionDescriptor(
      key: 'happy',
      englishLabel: 'Happy',
      frenchLabel: 'Heureux',
      arabicLabel: 'فرحان',
      icon: Icons.wb_sunny_outlined,
    ),
    EmotionDescriptor(
      key: 'calm',
      englishLabel: 'Calm',
      frenchLabel: 'Calme',
      arabicLabel: 'هادئ',
      icon: Icons.spa_outlined,
    ),
    EmotionDescriptor(
      key: 'sad',
      englishLabel: 'Sad',
      frenchLabel: 'Triste',
      arabicLabel: 'حزين',
      icon: Icons.water_drop_outlined,
    ),
    EmotionDescriptor(
      key: 'anxious',
      englishLabel: 'Anxious',
      frenchLabel: 'Anxieux',
      arabicLabel: 'قلق',
      icon: Icons.bolt_outlined,
    ),
    EmotionDescriptor(
      key: 'overwhelmed',
      englishLabel: 'Overwhelmed',
      frenchLabel: 'Submergé',
      arabicLabel: 'مغمور',
      icon: Icons.waves_outlined,
    ),
    EmotionDescriptor(
      key: 'angry',
      englishLabel: 'Angry',
      frenchLabel: 'En colère',
      arabicLabel: 'غاضب',
      icon: Icons.local_fire_department_outlined,
    ),
    EmotionDescriptor(
      key: 'numb',
      englishLabel: 'Numb',
      frenchLabel: 'Engourdi',
      arabicLabel: 'فاقد للإحساس',
      icon: Icons.lens_blur_rounded,
    ),
    EmotionDescriptor(
      key: 'confused',
      englishLabel: 'Confused',
      frenchLabel: 'Confus',
      arabicLabel: 'مشوش',
      icon: Icons.help_outline_rounded,
    ),
    EmotionDescriptor(
      key: 'motivated',
      englishLabel: 'Motivated',
      frenchLabel: 'Motivé',
      arabicLabel: 'متحمس',
      icon: Icons.trending_up_rounded,
    ),
    EmotionDescriptor(
      key: 'exhausted',
      englishLabel: 'Exhausted',
      frenchLabel: 'Épuisé',
      arabicLabel: 'مرهق',
      icon: Icons.battery_alert_outlined,
    ),
    EmotionDescriptor(
      key: 'disconnected',
      englishLabel: 'Disconnected',
      frenchLabel: 'Déconnecté',
      arabicLabel: 'منفصل',
      icon: Icons.link_off_rounded,
    ),
    EmotionDescriptor(
      key: 'restless',
      englishLabel: 'Restless',
      frenchLabel: 'Agité',
      arabicLabel: 'متململ',
      icon: Icons.air_outlined,
    ),
    EmotionDescriptor(
      key: 'mixed',
      englishLabel: 'Mixed emotions',
      frenchLabel: 'Émotions mixtes',
      arabicLabel: 'مشاعر مختلطة',
      icon: Icons.all_inclusive_rounded,
    ),
    EmotionDescriptor(
      key: 'custom',
      englishLabel: 'Custom emotion',
      frenchLabel: 'Émotion personnalisée',
      arabicLabel: 'شعور مخصص',
      icon: Icons.add_circle_outline_rounded,
    ),
  ];

  static EmotionDescriptor? findByAny(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final desc in library) {
      if (desc.key.toLowerCase() == normalized ||
          desc.englishLabel.toLowerCase() == normalized ||
          desc.frenchLabel.toLowerCase() == normalized ||
          desc.arabicLabel.trim().toLowerCase() == normalized) {
        return desc;
      }
    }
    final taxonomyMatch = AffectTaxonomy.byKey(normalized);
    if (taxonomyMatch != null) {
      return EmotionDescriptor(
        key: taxonomyMatch.key,
        englishLabel: taxonomyMatch.english,
        frenchLabel: taxonomyMatch.french,
        arabicLabel: taxonomyMatch.arabic,
        icon: taxonomyMatch.icon,
      );
    }
    return null;
  }

  static String canonicalKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return findByAny(trimmed)?.key ?? trimmed;
  }

  static String localizedLabel(String raw, AppStrings strings) {
    final match = findByAny(raw);
    if (match != null) return match.localized(strings);
    return raw;
  }

  static IconData iconForLabel(String label) {
    final match = findByAny(label);
    if (match != null) return match.icon;
    return Icons.bubble_chart_outlined;
  }
}

