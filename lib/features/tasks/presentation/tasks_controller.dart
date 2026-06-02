import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/data/task_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final tasksControllerProvider = ChangeNotifierProvider<TasksController>((ref) {
  final auth = ref.watch(authControllerProvider);
  final controller = TasksController(
    const TaskRepository(),
    auth.token,
  );
  controller.loadTasks();
  return controller;
});

class TasksController extends ChangeNotifier {
  TasksController(this._repository, this._token);

  final TaskRepository _repository;
  final String? _token;

  List<TaskItem> tasks = [];
  TaskStatus? statusFilter;
  TaskPriority? priorityFilter;
  String? errorMessage;
  bool isLoading = false;
  bool isSaving = false;

  Future<void> loadTasks() async {
    if (_token == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      tasks = await _repository.listTasks(
        token: _token,
        status: statusFilter,
        priority: priorityFilter,
      );
    } catch (error) {
      errorMessage = _readError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStatusFilter(TaskStatus? status) async {
    statusFilter = status;
    await loadTasks();
  }

  Future<void> setPriorityFilter(TaskPriority? priority) async {
    priorityFilter = priority;
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

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteTask(token: _token, id: id);
      await loadTasks();
      return true;
    } catch (error) {
      errorMessage = _readError(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _save(Future<TaskItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadTasks();
      return true;
    } catch (error) {
      errorMessage = _readError(error);
      return false;
    } finally {
      isSaving = false;
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

    return 'Task action failed. Please try again.';
  }
}
