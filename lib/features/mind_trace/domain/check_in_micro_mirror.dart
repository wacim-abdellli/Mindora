import '../../../app/localization/app_strings.dart';
import 'mind_trace_model.dart';

/// Calm, non-diagnostic 1-line observational feedback generated locally after
/// logging a mood check-in or intra-day moment.
class CheckInMicroMirror {
  const CheckInMicroMirror._();

  static String build({
    required MindTraceModel latestToday,
    required List<MindTraceModel> todayTraces,
    required List<MindTraceModel> allTraces,
    required AppStrings strings,
  }) {
    final sortedToday = List<MindTraceModel>.from(todayTraces)
      ..sort((a, b) => a.effectiveTimestamp.compareTo(b.effectiveTimestamp));

    if (sortedToday.length >= 2) {
      final delta =
          sortedToday.last.moodIntensity - sortedToday.first.moodIntensity;
      if (delta <= -2) {
        return strings.microMirrorCalmerShift(delta.abs());
      }
      return strings.microMirrorMomentCount(sortedToday.length);
    }

    final refDay = DateTime(
      latestToday.date.year,
      latestToday.date.month,
      latestToday.date.day,
    );
    final windowStart = refDay.subtract(const Duration(days: 6));
    final observedDays = <String>{latestToday.dateKey};
    for (final t in allTraces) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (!d.isBefore(windowStart) && !d.isAfter(refDay)) {
        observedDays.add(t.dateKey);
      }
    }

    if (observedDays.length >= 3) {
      return strings.microMirrorWeeklyRhythm(observedDays.length);
    }
    return strings.microMirrorFirstMoment;
  }
}
