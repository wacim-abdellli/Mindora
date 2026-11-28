import 'app_strings.dart';

/// Locale-aware formatting & Unicode bidirectional isolation helpers for
/// English (`en`), French (`fr`), and Tunisian Arabic (`ar`).
abstract final class MindFormatters {
  /// Unicode Left-to-Right Isolate (LRI) & Pop Directional Isolate (PDI).
  ///
  /// Keeps signed numbers (`+1.4`, `-1.2h`), phone numbers (`+216...`), and
  /// numeric PIN codes from reordering inside RTL Arabic sentences.
  static const String lri = '\u2066';
  static const String pdi = '\u2069';

  /// Wraps [text] in Unicode LRI/PDI markers so signs and digits never flip in RTL.
  static String ltrIsolate(String text) => '$lri$text$pdi';

  /// Formats a decimal number using a comma in French (`6,5`) and dot in EN/AR (`6.5`).
  static String decimal(
    double value,
    AppStrings strings, {
    int decimals = 1,
  }) {
    final raw = value.toStringAsFixed(decimals);
    return strings.isFrench ? raw.replaceAll('.', ',') : raw;
  }

  /// Formats duration in hours (`6.5h` EN, `6,5 h` FR, LTR-isolated `6.5 س` AR).
  static String hours(double value, AppStrings strings) {
    final numStr = decimal(value, strings);
    if (strings.isArabic) return '${ltrIsolate(numStr)} س';
    if (strings.isFrench) return '$numStr h';
    return '${numStr}h';
  }

  /// Formats a signed delta (`+1.4`, `-1.2h`) with strict LTR isolation so `-`
  /// and `+` stay on the leading edge of the digits in Arabic RTL.
  static String signedDelta(
    double delta,
    AppStrings strings, {
    String unit = '',
  }) {
    final sign = delta >= 0 ? '+' : '';
    final numStr = decimal(delta, strings);
    final suffix = switch (unit) {
      'h' => strings.isArabic ? ' س' : (strings.isFrench ? ' h' : 'h'),
      _ => unit,
    };
    return '${ltrIsolate('$sign$numStr')}$suffix';
  }

  /// Formats repetition counts with Arabic singular/dual/plural grammar.
  static String times(int count, AppStrings strings) {
    if (strings.isArabic) {
      if (count == 1) return 'مرة واحدة';
      if (count == 2) return 'مرتان';
      if (count >= 3 && count <= 10) return '$count مرات';
      return '$count مرة';
    }
    if (strings.isFrench) return '$count×';
    return '${count}x';
  }

  /// Formats compact day counts with Arabic singular/dual/plural grammar.
  static String daysShort(int count, AppStrings strings) {
    if (strings.isArabic) {
      if (count == 1) return 'يوم واحد';
      if (count == 2) return 'يومان';
      if (count >= 3 && count <= 10) return '$count أيام';
      return '$count يوم';
    }
    if (strings.isFrench) return '$count j';
    return '${count}d';
  }

  /// Formats a concise localized date (`Nov 27, 2026` / `27 nov. 2026` / `27 نوفمبر 2026`).
  static String shortDate(DateTime date, AppStrings strings) {
    final m = strings.shortMonthName(date.month);
    if (strings.isFrench || strings.isArabic) {
      return '${date.day} $m ${date.year}';
    }
    return '$m ${date.day}, ${date.year}';
  }

  /// Directional inline progression arrow (`→` LTR, `←` RTL) replacing raw `'->'`.
  static String rangeArrow(AppStrings strings) => strings.isArabic ? '←' : '→';
}
