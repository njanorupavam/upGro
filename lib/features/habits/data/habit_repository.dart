import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dio/dio.dart';

class HabitRepository {
  const HabitRepository();

  Options _options(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<HabitItem>> listHabits(String token) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/habits',
      options: _options(token),
    );

    final habits = response.data!['habits'] as List<dynamic>;
    return habits
        .map((habit) => HabitItem.fromJson(habit as Map<String, dynamic>))
        .toList();
  }

  Future<HabitItem> createHabit({
    required String token,
    required HabitDraft draft,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/habits',
      data: draft.toJson(),
      options: _options(token),
    );

    return HabitItem.fromJson(response.data!['habit'] as Map<String, dynamic>);
  }

  Future<HabitItem> updateHabit({
    required String token,
    required String id,
    required HabitDraft draft,
  }) async {
    final response = await dio.put<Map<String, dynamic>>(
      '/habits/$id',
      data: draft.toJson(),
      options: _options(token),
    );

    return HabitItem.fromJson(response.data!['habit'] as Map<String, dynamic>);
  }

  Future<void> deleteHabit({
    required String token,
    required String id,
  }) async {
    await dio.delete<void>(
      '/habits/$id',
      options: _options(token),
    );
  }

  Future<HabitItem> checkIn({
    required String token,
    required String id,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/habits/$id/checkin',
      options: _options(token),
    );

    return HabitItem.fromJson(response.data!['habit'] as Map<String, dynamic>);
  }
}
