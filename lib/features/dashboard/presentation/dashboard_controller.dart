import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/data/goal_repository.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/data/habit_repository.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/data/task_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  final List<TaskItem> tasks;
  final List<HabitItem> habits;
  final List<GoalItem> goals;
  final String? errorMessage;
  final bool isLoading;

  DashboardState({
    this.tasks = const [],
    this.habits = const [],
    this.goals = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  DashboardState copyWith({
    List<TaskItem>? tasks,
    List<HabitItem>? habits,
    List<GoalItem>? goals,
    String? Function()? errorMessage,
    bool? isLoading,
  }) {
    return DashboardState(
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      goals: goals ?? this.goals,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

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
}

class DashboardNotifier extends Notifier<DashboardState> {
  late final TaskRepository _taskRepository;
  late final HabitRepository _habitRepository;
  late final GoalRepository _goalRepository;
  String? _token;

  @override
  DashboardState build() {
    _taskRepository = ref.watch(taskRepositoryProvider);
    _habitRepository = ref.watch(habitRepositoryProvider);
    _goalRepository = ref.watch(goalRepositoryProvider);
    _token = ref.watch(authControllerProvider.select((auth) => auth.token));
    if (_token != null) {
      Future.microtask(() => loadDashboard());
    }
    return DashboardState();
  }

  Future<void> loadDashboard() async {
    if (_token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final results = await Future.wait([
        _taskRepository.listTasks(token: _token!),
        _habitRepository.listHabits(_token!),
        _goalRepository.listGoals(_token!),
      ]);

      state = state.copyWith(
        tasks: results[0] as List<TaskItem>,
        habits: results[1] as List<HabitItem>,
        goals: results[2] as List<GoalItem>,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
    } finally {
      state = state.copyWith(isLoading: false);
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

final dashboardControllerProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
