class GoalItem {
  const GoalItem({
    required this.id,
    required this.title,
    required this.progress,
    this.description,
    this.targetDate,
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
    );
  }

  final String id;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final int progress;
}

class GoalDraft {
  const GoalDraft({
    required this.title,
    required this.progress,
    this.description,
    this.targetDate,
  });

  final String title;
  final String? description;
  final DateTime? targetDate;
  final int progress;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'targetDate': targetDate?.toUtc().toIso8601String(),
      'progress': progress,
    };
  }
}
