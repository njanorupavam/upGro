import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(dioProvider));
});

class GoalRepository {
  const GoalRepository(this._dio);

  final Dio _dio;

  Options _options(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<GoalItem>> listGoals(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/goals',
      options: _options(token),
    );

    final goals = response.data!['goals'] as List<dynamic>;
    return goals
        .map((goal) => GoalItem.fromJson(goal as Map<String, dynamic>))
        .toList();
  }

  Future<GoalItem> createGoal({
    required String token,
    required GoalDraft draft,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: draft.toJson(),
      options: _options(token),
    );

    return GoalItem.fromJson(response.data!['goal'] as Map<String, dynamic>);
  }

  Future<GoalItem> updateGoal({
    required String token,
    required String id,
    required GoalDraft draft,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/goals/$id',
      data: draft.toJson(),
      options: _options(token),
    );

    return GoalItem.fromJson(response.data!['goal'] as Map<String, dynamic>);
  }

  Future<void> deleteGoal({
    required String token,
    required String id,
  }) async {
    await _dio.delete<void>(
      '/goals/$id',
      options: _options(token),
    );
  }
}
