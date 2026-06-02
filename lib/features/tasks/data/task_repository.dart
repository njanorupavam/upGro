import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dio/dio.dart';

class TaskRepository {
  const TaskRepository();

  Options _options(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<TaskItem>> listTasks({
    required String token,
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
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
    final response = await dio.post<Map<String, dynamic>>(
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
    final response = await dio.put<Map<String, dynamic>>(
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
    await dio.delete<void>(
      '/tasks/$id',
      options: _options(token),
    );
  }
}
