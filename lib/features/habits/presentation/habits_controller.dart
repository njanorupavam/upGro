import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/data/habit_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HabitsState {
  final List<HabitItem> habits;
  final String? errorMessage;
  final bool isLoading;
  final bool isSaving;

  HabitsState({
    this.habits = const [],
    this.errorMessage,
    this.isLoading = false,
    this.isSaving = false,
  });

  HabitsState copyWith({
    List<HabitItem>? habits,
    String? Function()? errorMessage,
    bool? isLoading,
    bool? isSaving,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class HabitsNotifier extends Notifier<HabitsState> {
  late final HabitRepository _repository;
  String? _token;

  @override
  HabitsState build() {
    _repository = ref.watch(habitRepositoryProvider);
    _token = ref.watch(authControllerProvider.select((auth) => auth.token));
    if (_token != null) {
      Future.microtask(() => loadHabits());
    }
    return HabitsState();
  }

  Future<void> loadHabits() async {
    if (_token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final habits = await _repository.listHabits(_token!);
      state = state.copyWith(habits: habits);
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
    } finally {
      state = state.copyWith(isLoading: false);
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

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await _repository.deleteHabit(token: _token!, id: id);
      await loadHabits();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> _save(Future<HabitItem> Function() action) async {
    if (_token == null) {
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      await action();
      await loadHabits();
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

    return 'Habit action failed. Please try again.';
  }
}

final habitsControllerProvider = NotifierProvider<HabitsNotifier, HabitsState>(HabitsNotifier.new);
