import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/data/task_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksState {
  final List<TaskItem> tasks;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String? errorMessage;
  final bool isLoading;
  final bool isSaving;

  TasksState({
    this.tasks = const [],
    this.statusFilter,
    this.priorityFilter,
    this.errorMessage,
    this.isLoading = false,
    this.isSaving = false,
  });

  TasksState copyWith({
    List<TaskItem>? tasks,
    TaskStatus? Function()? statusFilter,
    TaskPriority? Function()? priorityFilter,
    String? Function()? errorMessage,
    bool? isLoading,
    bool? isSaving,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class TasksNotifier extends Notifier<TasksState> {
  late final TaskRepository _repository;
  String? _token;

  @override
  TasksState build() {
    _repository = ref.watch(taskRepositoryProvider);
    _token = ref.watch(authControllerProvider.select((auth) => auth.token));
    if (_token != null) {
      Future.microtask(() => loadTasks());
    }
    return TasksState();
  }

  Future<void> loadTasks() async {
    if (_token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final tasks = await _repository.listTasks(
        token: _token!,
        status: state.statusFilter,
        priority: state.priorityFilter,
      );
      state = state.copyWith(tasks: tasks);
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setStatusFilter(TaskStatus? status) async {
    state = state.copyWith(statusFilter: () => status);
    await loadTasks();
  }

  Future<void> setPriorityFilter(TaskPriority? priority) async {
    state = state.copyWith(priorityFilter: () => priority);
    await loadTasks();
  }

  Future<bool> createTask(TaskDraft draft) async {
    return _save(() => _repository.createTask(token: _token!, draft: draft));
  }

  Future<bool> updateTask(String id, TaskDraft draft) async {
    return _save(() => _repository.updateTask(token: _token!, id: id, draft: draft));
  }

  Future<bool> toggleComplete(TaskItem task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.todo
        : TaskStatus.completed;

    return updateTask(
      task.id,
      TaskDraft(
        title: task.title,
        description: task.description,
        priority: task.priority,
        status: nextStatus,
        dueDate: task.dueDate,
      ),
    );
  }

  Future<bool> deleteTask(String id) async {
    if (_token == null) {
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await _repository.deleteTask(token: _token!, id: id);
      await loadTasks();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> _save(Future<TaskItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await action();
      await loadTasks();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Task action failed. Please try again.';
  }
}

final tasksControllerProvider = NotifierProvider<TasksNotifier, TasksState>(TasksNotifier.new);
