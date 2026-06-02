class DashboardAnalytics {
  const DashboardAnalytics({
    required this.tasksCompleted,
    required this.totalTasks,
    required this.taskCompletionRate,
    required this.habitCompletionRate,
    required this.goalProgress,
  });

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      tasksCompleted: json['tasksCompleted'] as int,
      totalTasks: json['totalTasks'] as int,
      taskCompletionRate: json['taskCompletionRate'] as int,
      habitCompletionRate: json['habitCompletionRate'] as int,
      goalProgress: json['goalProgress'] as int,
    );
  }

  final int tasksCompleted;
  final int totalTasks;
  final int taskCompletionRate;
  final int habitCompletionRate;
  final int goalProgress;
}
