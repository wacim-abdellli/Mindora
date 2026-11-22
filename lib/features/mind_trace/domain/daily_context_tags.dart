import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

/// Non-prescriptive daily routine / lifestyle context tag attached optionally
/// to a [MindTraceModel] entry for descriptive pattern correlation.
@immutable
class DailyContextTag {
  const DailyContextTag({
    required this.key,
    required this.english,
    required this.french,
    required this.arabic,
    required this.icon,
  });

  final String key;
  final String english;
  final String french;
  final String arabic;
  final IconData icon;

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabic;
    if (strings.isFrench) return french;
    return english;
  }
}

/// Curated set of 6 low-cognitive-load, strictly non-prescriptive daily context
/// tags (zero dietary, weight, or clinical-directive phrasing).
abstract final class DailyContextTags {
  static const List<DailyContextTag> all = [
    DailyContextTag(
      key: 'routine_kept',
      english: 'Routine kept',
      french: 'Routine maintenue',
      arabic: 'روتيني منظم',
      icon: Icons.schedule_rounded,
    ),
    DailyContextTag(
      key: 'sleep_consistent',
      english: 'Regular sleep',
      french: 'Sommeil régulier',
      arabic: 'نوم منتظم',
      icon: Icons.bedtime_outlined,
    ),
    DailyContextTag(
      key: 'late_caffeine_screens',
      english: 'Late screens / caffeine',
      french: 'Écrans / caféine tard',
      arabic: 'كافيين أو شاشات متأخرة',
      icon: Icons.nightlight_outlined,
    ),
    DailyContextTag(
      key: 'physical_movement',
      english: 'Physical movement',
      french: 'Mouvement physique',
      arabic: 'حركة ومشي',
      icon: Icons.directions_walk_rounded,
    ),
    DailyContextTag(
      key: 'social_connection',
      english: 'Social contact',
      french: 'Lien social',
      arabic: 'تواصل اجتماعي',
      icon: Icons.groups_outlined,
    ),
    DailyContextTag(
      key: 'high_workload',
      english: 'Heavy workload',
      french: 'Forte charge',
      arabic: 'ضغط عمل',
      icon: Icons.work_outline_rounded,
    ),
  ];

  static final Map<String, DailyContextTag> _byKey = {
    for (final tag in all) tag.key: tag,
  };

  static DailyContextTag? byKey(String key) => _byKey[key.trim()];

  static String localizedLabel(String key, AppStrings strings) {
    final tag = byKey(key);
    if (tag != null) return tag.localized(strings);
    return key.replaceAll('_', ' ');
  }
}
