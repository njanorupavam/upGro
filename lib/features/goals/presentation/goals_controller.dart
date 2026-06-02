import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/data/goal_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final goalsControllerProvider = ChangeNotifierProvider<GoalsController>((ref) {
  final auth = ref.watch(authControllerProvider);
  final controller = GoalsController(const GoalRepository(), auth.token);
  controller.loadGoals();
  return controller;
});

class GoalsController extends ChangeNotifier {
  GoalsController(this._repository, this._token);

  final GoalRepository _repository;
  final String? _token;

  List<GoalItem> goals = [];
  String? errorMessage;
  bool isLoading = false;
  bool isSaving = false;

  Future<void> loadGoals() async {
    if (_token == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      goals = await _repository.listGoals(_token);
    } catch (error) {
      errorMessage = _readError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoal(GoalDraft draft) {
    return _save(() => _repository.createGoal(token: _token!, draft: draft));
  }

  Future<bool> updateGoal(String id, GoalDraft draft) {
    return _save(() => _repository.updateGoal(token: _token!, id: id, draft: draft));
  }

  Future<bool> deleteGoal(String id) async {
    if (_token == null) {
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteGoal(token: _token, id: id);
      await loadGoals();
      return true;
    } catch (error) {
      errorMessage = _readError(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _save(Future<GoalItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadGoals();
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

    return 'Goal action failed. Please try again.';
  }
}
