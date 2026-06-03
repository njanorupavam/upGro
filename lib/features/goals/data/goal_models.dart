class GoalItem {
  const GoalItem({
    required this.id,
    required this.title,
    required this.progress,
    this.description,
    this.targetDate,
    this.motivationNote,
  });

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String).toLocal(),
      progress: json['progress'] as int,
      motivationNote: json['motivationNote'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final int progress;
  /// Optional "Why I want this" motivation note shown on the goal card
  final String? motivationNote;
}

class GoalDraft {
  const GoalDraft({
    required this.title,
    required this.progress,
    this.description,
    this.targetDate,
    this.motivationNote,
  });

  final String title;
  final String? description;
  final DateTime? targetDate;
  final int progress;
  final String? motivationNote;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'targetDate': targetDate?.toUtc().toIso8601String(),
      'progress': progress,
      if (motivationNote != null) 'motivationNote': motivationNote,
    };
  }
}
