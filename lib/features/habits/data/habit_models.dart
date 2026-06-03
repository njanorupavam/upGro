class WeeklyHabitProgress {
  const WeeklyHabitProgress({
    required this.date,
    required this.completed,
  });

  factory WeeklyHabitProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyHabitProgress(
      date: json['date'] as String,
      completed: json['completed'] as bool,
    );
  }

  final String date;
  final bool completed;
}

class HabitItem {
  const HabitItem({
    required this.id,
    required this.title,
    required this.currentStreak,
    required this.bestStreak,
    required this.checkedInToday,
    required this.weeklyProgress,
    this.description,
    this.category,
    this.targetFrequency,
  });

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    final progress = json['weeklyProgress'] as List<dynamic>;

    return HabitItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      targetFrequency: json['targetFrequency'] as int?,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      checkedInToday: json['checkedInToday'] as bool,
      weeklyProgress: progress
          .map((item) =>
              WeeklyHabitProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? category;
  /// Target completions per week (7 = daily, 5 = weekdays)
  final int? targetFrequency;
  final int currentStreak;
  final int bestStreak;
  final bool checkedInToday;
  final List<WeeklyHabitProgress> weeklyProgress;
}

class HabitDraft {
  const HabitDraft({
    required this.title,
    this.description,
    this.category,
    this.targetFrequency = 7,
  });

  final String title;
  final String? description;
  final String? category;
  final int? targetFrequency;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (category != null) 'category': category,
      if (targetFrequency != null) 'targetFrequency': targetFrequency,
    };
  }
}
