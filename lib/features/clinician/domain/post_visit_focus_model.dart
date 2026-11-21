/// Collaborative action / reflection item agreed between psychiatrist and
/// patient for the interval between consultations.
class FocusGoalItem {
  const FocusGoalItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  FocusGoalItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return FocusGoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toCanonicalJson() => {
        'id': id,
        'title': title,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory FocusGoalItem.fromJson(Map<String, dynamic> json) {
    return FocusGoalItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// Encrypted post-visit between-session focus plan sent from the Psychiatrist
/// Workspace to the Patient Workspace (`MF-CAREPLAN-V1:...`).
///
/// Strictly non-diagnostic and patient-controllable: the patient may toggle,
/// complete, dismiss, or clear this card at any time.
class PostVisitFocusPlan {
  const PostVisitFocusPlan({
    this.schemaVersion = 1,
    required this.planId,
    required this.clinicianName,
    this.clinicName = '',
    required this.createdAt,
    this.followUpDate,
    this.focusItems = const [],
    this.observationCue = '',
    this.isDismissed = false,
    this.integrityHash = '',
  });

  final int schemaVersion;
  final String planId;
  final String clinicianName;
  final String clinicName;
  final DateTime createdAt;
  final DateTime? followUpDate;
  final List<FocusGoalItem> focusItems;
  final String observationCue;
  final bool isDismissed;
  final String integrityHash;

  PostVisitFocusPlan copyWith({
    int? schemaVersion,
    String? planId,
    String? clinicianName,
    String? clinicName,
    DateTime? createdAt,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
    List<FocusGoalItem>? focusItems,
    String? observationCue,
    bool? isDismissed,
    String? integrityHash,
  }) {
    return PostVisitFocusPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      planId: planId ?? this.planId,
      clinicianName: clinicianName ?? this.clinicianName,
      clinicName: clinicName ?? this.clinicName,
      createdAt: createdAt ?? this.createdAt,
      followUpDate:
          clearFollowUpDate ? null : (followUpDate ?? this.followUpDate),
      focusItems: focusItems ?? this.focusItems,
      observationCue: observationCue ?? this.observationCue,
      isDismissed: isDismissed ?? this.isDismissed,
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }

  /// Immutable signed fields for deterministic SHA-256 verification across
  /// local completions/dismissals.
  Map<String, dynamic> toCanonicalBodyJson() => {
        'schemaVersion': schemaVersion,
        'planId': planId,
        'clinicianName': clinicianName,
        'clinicName': clinicName,
        'createdAt': createdAt.toIso8601String(),
        'followUpDate': followUpDate?.toIso8601String(),
        'focusItems':
            focusItems.map((i) => i.toCanonicalJson()).toList(growable: false),
        'observationCue': observationCue,
      };

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'planId': planId,
        'clinicianName': clinicianName,
        'clinicName': clinicName,
        'createdAt': createdAt.toIso8601String(),
        'followUpDate': followUpDate?.toIso8601String(),
        'focusItems':
            focusItems.map((i) => i.toJson()).toList(growable: false),
        'observationCue': observationCue,
        'isDismissed': isDismissed,
        'integrityHash': integrityHash,
      };

  factory PostVisitFocusPlan.fromJson(Map<String, dynamic> json) {
    return PostVisitFocusPlan(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      planId: json['planId'] as String? ?? 'plan_unknown',
      clinicianName:
          json['clinicianName'] as String? ?? 'Clinician',
      clinicName: json['clinicName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      followUpDate: json['followUpDate'] != null
          ? DateTime.tryParse(json['followUpDate'] as String)
          : null,
      focusItems: (json['focusItems'] as List<dynamic>?)
              ?.map((e) => FocusGoalItem.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      observationCue: json['observationCue'] as String? ?? '',
      isDismissed: json['isDismissed'] as bool? ?? false,
      integrityHash: json['integrityHash'] as String? ?? '',
    );
  }
}
