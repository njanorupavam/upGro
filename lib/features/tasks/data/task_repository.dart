import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});

class TaskRepository {
  const TaskRepository(this._dio);

  final Dio _dio;

  Options _options(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<TaskItem>> listTasks({
    required String token,
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: {
        if (status != null) 'status': status.apiValue,
        if (priority != null) 'priority': priority.apiValue,
      },
      options: _options(token),
    );

    final tasks = response.data!['tasks'] as List<dynamic>;
    return tasks
        .map((task) => TaskItem.fromJson(task as Map<String, dynamic>))
        .toList();
  }

  Future<TaskItem> createTask({
    required String token,
    required TaskDraft draft,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: draft.toJson(),
      options: _options(token),
    );

    return TaskItem.fromJson(response.data!['task'] as Map<String, dynamic>);
  }

  Future<TaskItem> updateTask({
    required String token,
    required String id,
    required TaskDraft draft,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/tasks/$id',
      data: draft.toJson(),
      options: _options(token),
    );

    return TaskItem.fromJson(response.data!['task'] as Map<String, dynamic>);
  }

  Future<void> deleteTask({
    required String token,
    required String id,
  }) async {
    await _dio.delete<void>(
      '/tasks/$id',
      options: _options(token),
    );
  }
}
