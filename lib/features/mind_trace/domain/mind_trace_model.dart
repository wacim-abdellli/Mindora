import 'affect_taxonomy.dart';

/// Intra-day circadian windows for psychiatric diurnal mood analysis.
enum DayTimeBucket { morning, afternoon, evening, night }

/// A comprehensive daily emotional and psychological check-in record.
///
/// Satisfies the Daily Mind Trace architecture:
/// - Basic metadata (id, date, timestamp, isCompleted)
/// - Core somatic & affective indicators (mood, emotions, intensity, energy, anxiety)
/// - Cognitive clarity (racing thoughts, concentration, intrusive thoughts, mental clarity, emotional disconnection)
/// - Somatic clarity (sleep hours, sleep quality, physical tension)
/// - Subjective explorations (dynamic questions, journal entry, voice note reference)
/// - AI reflection & suggested Journey activity integration
class MindTraceModel {
  const MindTraceModel({
    required this.id,
    this.userId = 'local_user',
    required this.date,
    this.overallMood = 'calm',
    this.selectedEmotions = const [],
    this.moodIntensity = 5,
    this.energyLevel,
    this.anxietyLevel,
    this.sleepHours,
    this.sleepQuality,
    this.concentrationLevel,
    this.mentalClarity,
    this.physicalTension,
    this.racingThoughts,
    this.intrusiveThoughts,
    this.emotionalDisconnection,
    this.symptomsAndExperiences,
    this.situation,
    this.behavioralResponse,
    this.journalText,
    this.voiceNotePath,
    this.dynamicAnswers = const {},
    this.investigationAnswers = const {},
    this.aiReflection,
    this.suggestedJourneyActivityId,
    this.contextTags = const [],
    this.isCompleted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String overallMood;
  final List<String> selectedEmotions;
  final int moodIntensity; // 1 - 10
  final int? energyLevel; // 0 - 10 (null when unrecorded)
  final int? anxietyLevel; // 0 - 10
  final double? sleepHours;
  final int? sleepQuality; // 1 - 5
  final int? concentrationLevel; // 1 - 10
  final int? mentalClarity; // 1 - 10
  final int? physicalTension; // 1 - 10
  final int? racingThoughts; // 1 - 10
  final int? intrusiveThoughts; // 1 - 10
  final int? emotionalDisconnection; // 1 - 10
  final String? symptomsAndExperiences;
  final String? situation;
  final String? behavioralResponse;
  final String? journalText;
  final String? voiceNotePath;
  final Map<String, String> dynamicAnswers;
  final Map<String, String> investigationAnswers;
  final String? aiReflection;
  final String? suggestedJourneyActivityId;
  final List<String> contextTags;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isInvestigated =>
      investigationAnswers.values.any((v) => v.trim().isNotEmpty);

  String get thoughtPreview {
    if (journalText != null && journalText!.trim().isNotEmpty) {
      return journalText!.trim();
    }
    if (situation != null && situation!.trim().isNotEmpty) {
      return situation!.trim();
    }
    return overallMood;
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime get effectiveTimestamp {
    if (date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        (createdAt.hour != 0 || createdAt.minute != 0)) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        createdAt.hour,
        createdAt.minute,
        createdAt.second,
      );
    }
    return date;
  }

  DayTimeBucket get timeBucket {
    final h = effectiveTimestamp.hour;
    if (h >= 5 && h < 12) return DayTimeBucket.morning;
    if (h >= 12 && h < 17) return DayTimeBucket.afternoon;
    if (h >= 17 && h < 22) return DayTimeBucket.evening;
    return DayTimeBucket.night;
  }

  String get formattedTime {
    final ts = effectiveTimestamp;
    return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }

  List<String> get nuancedEmotions => AffectTaxonomy.extractNuancedKeys(this);

  MindTraceModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? overallMood,
    List<String>? selectedEmotions,
    int? moodIntensity,
    int? energyLevel,
    bool clearEnergyLevel = false,
    int? anxietyLevel,
    bool clearAnxietyLevel = false,
    double? sleepHours,
    bool clearSleepHours = false,
    int? sleepQuality,
    bool clearSleepQuality = false,
    int? concentrationLevel,
    bool clearConcentrationLevel = false,
    int? mentalClarity,
    bool clearMentalClarity = false,
    int? physicalTension,
    bool clearPhysicalTension = false,
    int? racingThoughts,
    bool clearRacingThoughts = false,
    int? intrusiveThoughts,
    bool clearIntrusiveThoughts = false,
    int? emotionalDisconnection,
    bool clearEmotionalDisconnection = false,
    String? symptomsAndExperiences,
    bool clearSymptomsAndExperiences = false,
    String? situation,
    bool clearSituation = false,
    String? behavioralResponse,
    bool clearBehavioralResponse = false,
    String? journalText,
    bool clearJournalText = false,
    String? voiceNotePath,
    bool clearVoiceNotePath = false,
    Map<String, String>? dynamicAnswers,
    Map<String, String>? investigationAnswers,
    String? aiReflection,
    bool clearAiReflection = false,
    String? suggestedJourneyActivityId,
    bool clearSuggestedJourneyActivityId = false,
    List<String>? contextTags,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindTraceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      overallMood: overallMood ?? this.overallMood,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      moodIntensity: moodIntensity ?? this.moodIntensity,
      energyLevel:
          clearEnergyLevel ? null : (energyLevel ?? this.energyLevel),
      anxietyLevel:
          clearAnxietyLevel ? null : (anxietyLevel ?? this.anxietyLevel),
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
      sleepQuality:
          clearSleepQuality ? null : (sleepQuality ?? this.sleepQuality),
      concentrationLevel: clearConcentrationLevel
          ? null
          : (concentrationLevel ?? this.concentrationLevel),
      mentalClarity:
          clearMentalClarity ? null : (mentalClarity ?? this.mentalClarity),
      physicalTension: clearPhysicalTension
          ? null
          : (physicalTension ?? this.physicalTension),
      racingThoughts: clearRacingThoughts
          ? null
          : (racingThoughts ?? this.racingThoughts),
      intrusiveThoughts: clearIntrusiveThoughts
          ? null
          : (intrusiveThoughts ?? this.intrusiveThoughts),
      emotionalDisconnection: clearEmotionalDisconnection
          ? null
          : (emotionalDisconnection ?? this.emotionalDisconnection),
      symptomsAndExperiences: clearSymptomsAndExperiences
          ? null
          : (symptomsAndExperiences ?? this.symptomsAndExperiences),
      situation: clearSituation ? null : (situation ?? this.situation),
      behavioralResponse: clearBehavioralResponse
          ? null
          : (behavioralResponse ?? this.behavioralResponse),
      journalText: clearJournalText ? null : (journalText ?? this.journalText),
      voiceNotePath:
          clearVoiceNotePath ? null : (voiceNotePath ?? this.voiceNotePath),
      dynamicAnswers: dynamicAnswers ?? this.dynamicAnswers,
      investigationAnswers: investigationAnswers ?? this.investigationAnswers,
      aiReflection:
          clearAiReflection ? null : (aiReflection ?? this.aiReflection),
      suggestedJourneyActivityId: clearSuggestedJourneyActivityId
          ? null
          : (suggestedJourneyActivityId ?? this.suggestedJourneyActivityId),
      contextTags: contextTags ?? this.contextTags,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'overallMood': overallMood,
        'selectedEmotions': selectedEmotions,
        'moodIntensity': moodIntensity,
        'energyLevel': energyLevel,
        'anxietyLevel': anxietyLevel,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'concentrationLevel': concentrationLevel,
        'mentalClarity': mentalClarity,
        'physicalTension': physicalTension,
        'racingThoughts': racingThoughts,
        'intrusiveThoughts': intrusiveThoughts,
        'emotionalDisconnection': emotionalDisconnection,
        'symptomsAndExperiences': symptomsAndExperiences,
        'situation': situation,
        'behavioralResponse': behavioralResponse,
        'journalText': journalText,
        'voiceNotePath': voiceNotePath,
        'dynamicAnswers': dynamicAnswers,
        'investigationAnswers': investigationAnswers,
        'aiReflection': aiReflection,
        'suggestedJourneyActivityId': suggestedJourneyActivityId,
        'contextTags': contextTags,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MindTraceModel.fromJson(Map<String, dynamic> json) {
    return MindTraceModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? 'local_user',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      overallMood: json['overallMood'] as String? ?? 'calm',
      selectedEmotions: (json['selectedEmotions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      moodIntensity: (json['moodIntensity'] as num?)?.toInt() ?? 5,
      energyLevel: (json['energyLevel'] as num?)?.toInt(),
      anxietyLevel: (json['anxietyLevel'] as num?)?.toInt(),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: (json['sleepQuality'] as num?)?.toInt(),
      concentrationLevel: (json['concentrationLevel'] as num?)?.toInt(),
      mentalClarity: (json['mentalClarity'] as num?)?.toInt(),
      physicalTension: (json['physicalTension'] as num?)?.toInt(),
      racingThoughts: (json['racingThoughts'] as num?)?.toInt(),
      intrusiveThoughts: (json['intrusiveThoughts'] as num?)?.toInt(),
      emotionalDisconnection: (json['emotionalDisconnection'] as num?)?.toInt(),
      symptomsAndExperiences: json['symptomsAndExperiences'] as String?,
      situation: json['situation'] as String?,
      behavioralResponse: json['behavioralResponse'] as String?,
      journalText: json['journalText'] as String?,
      voiceNotePath: json['voiceNotePath'] as String?,
      dynamicAnswers: (json['dynamicAnswers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {},
      investigationAnswers:
          (json['investigationAnswers'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())) ??
              const {},
      aiReflection: json['aiReflection'] as String?,
      suggestedJourneyActivityId:
          json['suggestedJourneyActivityId'] as String?,
      contextTags: (json['contextTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static MindTraceModel createFresh({
    required String id,
    DateTime? date,
    String overallMood = 'calm',
  }) {
    final now = DateTime.now();
    return MindTraceModel(
      id: id,
      date: date ?? now,
      overallMood: overallMood,
      createdAt: now,
      updatedAt: now,
    );
  }
}
