enum TaskPriority {
  low('LOW', 'Low'),
  medium('MEDIUM', 'Medium'),
  high('HIGH', 'High');

  const TaskPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaskPriority fromApi(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.apiValue == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('TODO', 'To do'),
  inProgress('IN_PROGRESS', 'In progress'),
  completed('COMPLETED', 'Completed');

  const TaskStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaskStatus fromApi(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueDate,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromApi(json['priority'] as String),
      status: TaskStatus.fromApi(json['status'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String).toLocal(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.priority,
    required this.status,
    this.description,
    this.dueDate,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.apiValue,
      'status': status.apiValue,
      'dueDate': dueDate?.toUtc().toIso8601String(),
    };
  }
}
