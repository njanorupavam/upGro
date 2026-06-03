import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/data/goal_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsState {
  final List<GoalItem> goals;
  final String? errorMessage;
  final bool isLoading;
  final bool isSaving;

  GoalsState({
    this.goals = const [],
    this.errorMessage,
    this.isLoading = false,
    this.isSaving = false,
  });

  GoalsState copyWith({
    List<GoalItem>? goals,
    String? Function()? errorMessage,
    bool? isLoading,
    bool? isSaving,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class GoalsNotifier extends Notifier<GoalsState> {
  late final GoalRepository _repository;
  String? _token;

  @override
  GoalsState build() {
    _repository = ref.watch(goalRepositoryProvider);
    _token = ref.watch(authControllerProvider.select((auth) => auth.token));
    if (_token != null) {
      Future.microtask(() => loadGoals());
    }
    return GoalsState();
  }

  Future<void> loadGoals() async {
    if (_token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final goals = await _repository.listGoals(_token!);
      state = state.copyWith(goals: goals);
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
    } finally {
      state = state.copyWith(isLoading: false);
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

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await _repository.deleteGoal(token: _token!, id: id);
      await loadGoals();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> _save(Future<GoalItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await action();
      await loadGoals();
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

    return 'Goal action failed. Please try again.';
  }
}

final goalsControllerProvider = NotifierProvider<GoalsNotifier, GoalsState>(GoalsNotifier.new);
