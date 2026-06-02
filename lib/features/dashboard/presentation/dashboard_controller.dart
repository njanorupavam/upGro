import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/data/goal_repository.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/data/habit_repository.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/data/task_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final dashboardControllerProvider =
    ChangeNotifierProvider<DashboardController>((ref) {
  final auth = ref.watch(authControllerProvider);
  final controller = DashboardController(
    token: auth.token,
    taskRepository: const TaskRepository(),
    habitRepository: const HabitRepository(),
    goalRepository: const GoalRepository(),
  );
  controller.loadDashboard();
  return controller;
});

class DashboardController extends ChangeNotifier {
  DashboardController({
    required this.token,
    required this.taskRepository,
    required this.habitRepository,
    required this.goalRepository,
  });

  final String? token;
  final TaskRepository taskRepository;
  final HabitRepository habitRepository;
  final GoalRepository goalRepository;

  List<TaskItem> tasks = [];
  List<HabitItem> habits = [];
  List<GoalItem> goals = [];
  String? errorMessage;
  bool isLoading = false;

  List<TaskItem> get todaysTasks {
    final now = DateTime.now();
    return tasks.where((task) {
      final dueDate = task.dueDate;
      if (dueDate == null) {
        return task.status != TaskStatus.completed;
      }

      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).toList();
  }

  List<HabitItem> get activeHabits => habits;

  int get completedTaskCount {
    return tasks.where((task) => task.status == TaskStatus.completed).length;
  }

  int get pendingTaskCount {
    return tasks.where((task) => task.status != TaskStatus.completed).length;
  }

  int get completedHabitCount {
    return habits.where((habit) => habit.checkedInToday).length;
  }

  int get averageGoalProgress {
    if (goals.isEmpty) {
      return 0;
    }

    final total = goals.fold<int>(0, (sum, goal) => sum + goal.progress);
    return (total / goals.length).round();
  }

  Future<void> loadDashboard() async {
    if (token == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        taskRepository.listTasks(token: token!),
        habitRepository.listHabits(token!),
        goalRepository.listGoals(token!),
      ]);

      tasks = results[0] as List<TaskItem>;
      habits = results[1] as List<HabitItem>;
      goals = results[2] as List<GoalItem>;
    } catch (error) {
      errorMessage = _readError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Dashboard data failed to load.';
  }
}
