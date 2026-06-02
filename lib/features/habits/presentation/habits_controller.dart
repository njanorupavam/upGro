import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/data/habit_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final habitsControllerProvider = ChangeNotifierProvider<HabitsController>((ref) {
  final auth = ref.watch(authControllerProvider);
  final controller = HabitsController(const HabitRepository(), auth.token);
  controller.loadHabits();
  return controller;
});

class HabitsController extends ChangeNotifier {
  HabitsController(this._repository, this._token);

  final HabitRepository _repository;
  final String? _token;

  List<HabitItem> habits = [];
  String? errorMessage;
  bool isLoading = false;
  bool isSaving = false;

  Future<void> loadHabits() async {
    if (_token == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      habits = await _repository.listHabits(_token);
    } catch (error) {
      errorMessage = _readError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createHabit(HabitDraft draft) {
    return _save(() => _repository.createHabit(token: _token!, draft: draft));
  }

  Future<bool> updateHabit(String id, HabitDraft draft) {
    return _save(() => _repository.updateHabit(token: _token!, id: id, draft: draft));
  }

  Future<bool> checkIn(String id) {
    return _save(() => _repository.checkIn(token: _token!, id: id));
  }

  Future<bool> deleteHabit(String id) async {
    if (_token == null) {
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteHabit(token: _token, id: id);
      await loadHabits();
      return true;
    } catch (error) {
      errorMessage = _readError(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _save(Future<HabitItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadHabits();
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

    return 'Habit action failed. Please try again.';
  }
}
