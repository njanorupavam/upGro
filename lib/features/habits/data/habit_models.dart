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
  });

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    final progress = json['weeklyProgress'] as List<dynamic>;

    return HabitItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      checkedInToday: json['checkedInToday'] as bool,
      weeklyProgress: progress
          .map((item) => WeeklyHabitProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final int currentStreak;
  final int bestStreak;
  final bool checkedInToday;
  final List<WeeklyHabitProgress> weeklyProgress;
}

class HabitDraft {
  const HabitDraft({
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}
