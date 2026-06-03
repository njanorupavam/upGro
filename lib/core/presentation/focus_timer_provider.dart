import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

const _sessionsKey = 'focusflow_completed_sessions';
const int kWorkDuration = 25 * 60; // 25 minutes
const int kBreakDuration = 5 * 60; // 5 minutes

class FocusTimerState {
  final int timeLeft;
  final bool isRunning;
  final bool isBreak;
  final String? associatedTaskId;
  final int totalCompleted;

  const FocusTimerState({
    this.timeLeft = kWorkDuration,
    this.isRunning = false,
    this.isBreak = false,
    this.associatedTaskId,
    this.totalCompleted = 0,
  });

  FocusTimerState copyWith({
    int? timeLeft,
    bool? isRunning,
    bool? isBreak,
    String? Function()? associatedTaskId,
    int? totalCompleted,
  }) {
    return FocusTimerState(
      timeLeft: timeLeft ?? this.timeLeft,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      associatedTaskId: associatedTaskId != null ? associatedTaskId() : this.associatedTaskId,
      totalCompleted: totalCompleted ?? this.totalCompleted,
    );
  }
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _timer;

  @override
  FocusTimerState build() {
    _loadSessions();
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const FocusTimerState();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_sessionsKey) ?? 0;
      state = state.copyWith(totalCompleted: count);
    } catch (_) {}
  }

  void start({String? taskId}) {
    if (state.isRunning) return;

    state = state.copyWith(
      isRunning: true,
      associatedTaskId: () => taskId ?? state.associatedTaskId,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft <= 1) {
        _onTimeUp();
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      timeLeft: state.isBreak ? kBreakDuration : kWorkDuration,
    );
  }

  void skip() {
    _timer?.cancel();
    _onTimeUp();
  }

  Future<void> _onTimeUp() async {
    _timer?.cancel();

    final wasWork = !state.isBreak;
    final nextIsBreak = wasWork;
    final nextTime = nextIsBreak ? kBreakDuration : kWorkDuration;

    int newCompleted = state.totalCompleted;
    if (wasWork) {
      newCompleted++;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_sessionsKey, newCompleted);
      } catch (_) {}

      // Fire desktop notification
      NotificationService.showNotification(
        'Focus Session Completed!',
        'Great job! Take a well-deserved 5-minute break.',
      );
    } else {
      NotificationService.showNotification(
        'Break Completed!',
        'Ready to focus again? Let\'s get started!',
      );
    }

    state = state.copyWith(
      isRunning: false,
      isBreak: nextIsBreak,
      timeLeft: nextTime,
      totalCompleted: newCompleted,
      associatedTaskId: () => null,
    );
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
