import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'challenge_provider.dart';
import 'focus_timer_provider.dart';
import 'package:dayforge/features/dashboard/presentation/dashboard_controller.dart';

const _unlockedBadgesKey = 'focusflow_unlocked_badges';

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<BadgeItem> kAllBadges = [
  BadgeItem(
    id: 'spark',
    title: 'The Spark',
    description: 'Reach Day 3 of the 21-day challenge.',
    icon: Icons.bolt,
    color: Colors.amber,
  ),
  BadgeItem(
    id: 'habit_builder',
    title: 'Habit Builder',
    description: 'Complete 1 week (Day 7) of consistency.',
    icon: Icons.favorite,
    color: Colors.redAccent,
  ),
  BadgeItem(
    id: 'autopilot',
    title: 'Autopilot',
    description: 'Reach Day 14. Habits are locking in.',
    icon: Icons.auto_awesome,
    color: Colors.purpleAccent,
  ),
  BadgeItem(
    id: 'new_identity',
    title: 'New Identity',
    description: 'Complete the entire 21-day challenge!',
    icon: Icons.emoji_events,
    color: Colors.orange,
  ),
  BadgeItem(
    id: 'focus_master',
    title: 'Focus Master',
    description: 'Complete 5 Pomodoro focus sessions.',
    icon: Icons.timer,
    color: Colors.blue,
  ),
  BadgeItem(
    id: 'consistency_king',
    title: 'Consistency King',
    description: 'Achieve a 5-day habit streak.',
    icon: Icons.whatshot,
    color: Colors.deepOrangeAccent,
  ),
  BadgeItem(
    id: 'goal_crusher',
    title: 'Goal Crusher',
    description: 'Make 50% or more progress on any goal.',
    icon: Icons.flag,
    color: Colors.green,
  ),
];

class BadgeState {
  final Set<String> unlockedIds;
  final BadgeItem? newlyUnlocked;

  const BadgeState({
    this.unlockedIds = const {},
    this.newlyUnlocked,
  });

  BadgeState copyWith({
    Set<String>? unlockedIds,
    BadgeItem? Function()? newlyUnlocked,
  }) {
    return BadgeState(
      unlockedIds: unlockedIds ?? this.unlockedIds,
      newlyUnlocked: newlyUnlocked != null ? newlyUnlocked() : this.newlyUnlocked,
    );
  }
}

class BadgeNotifier extends Notifier<BadgeState> {
  @override
  BadgeState build() {
    _loadUnlocked();

    // Listen to changes to compute locks in real-time
    final challenge = ref.watch(challengeProvider);
    final timerState = ref.watch(focusTimerProvider);
    final dashboard = ref.watch(dashboardControllerProvider);

    // Run evaluation after the build cycle finishes to avoid layout collisions
    Future.microtask(() => _evaluate(challenge, timerState, dashboard));

    return const BadgeState();
  }

  Future<void> _loadUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_unlockedBadgesKey) ?? [];
      state = state.copyWith(unlockedIds: list.toSet());
    } catch (_) {}
  }

  void _evaluate(ChallengeState challenge, FocusTimerState timerState, DashboardState dashboard) async {
    final currentUnlocked = Set<String>.from(state.unlockedIds);
    BadgeItem? newlyUnlockedItem;

    // 1. The Spark (Day 3)
    if (challenge.isActive && challenge.currentDay >= 3) {
      if (!currentUnlocked.contains('spark')) {
        currentUnlocked.add('spark');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'spark');
      }
    }

    // 2. Habit Builder (Day 7)
    if (challenge.isActive && challenge.currentDay >= 7) {
      if (!currentUnlocked.contains('habit_builder')) {
        currentUnlocked.add('habit_builder');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'habit_builder');
      }
    }

    // 3. Autopilot (Day 14)
    if (challenge.isActive && challenge.currentDay >= 14) {
      if (!currentUnlocked.contains('autopilot')) {
        currentUnlocked.add('autopilot');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'autopilot');
      }
    }

    // 4. New Identity (Day 21)
    if (challenge.isComplete) {
      if (!currentUnlocked.contains('new_identity')) {
        currentUnlocked.add('new_identity');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'new_identity');
      }
    }

    // 5. Focus Master (5 sessions)
    if (timerState.totalCompleted >= 5) {
      if (!currentUnlocked.contains('focus_master')) {
        currentUnlocked.add('focus_master');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'focus_master');
      }
    }

    // 6. Consistency King (5-day streak)
    final hasFiveDayStreak = dashboard.habits.any((h) => h.bestStreak >= 5);
    if (hasFiveDayStreak) {
      if (!currentUnlocked.contains('consistency_king')) {
        currentUnlocked.add('consistency_king');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'consistency_king');
      }
    }

    // 7. Goal Crusher (>= 50% goal progress)
    final hasCompletedGoal = dashboard.goals.any((g) => g.progress >= 50);
    if (hasCompletedGoal) {
      if (!currentUnlocked.contains('goal_crusher')) {
        currentUnlocked.add('goal_crusher');
        newlyUnlockedItem = kAllBadges.firstWhere((b) => b.id == 'goal_crusher');
      }
    }

    // If new badge was unlocked, save and trigger toast overlay
    if (newlyUnlockedItem != null) {
      state = state.copyWith(
        unlockedIds: currentUnlocked,
        newlyUnlocked: () => newlyUnlockedItem,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_unlockedBadgesKey, currentUnlocked.toList());
      } catch (_) {}
    }
  }

  void clearCelebration() {
    state = state.copyWith(newlyUnlocked: () => null);
  }

  Future<void> resetBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_unlockedBadgesKey);
      state = const BadgeState();
    } catch (_) {}
  }
}

final badgeProvider =
    NotifierProvider<BadgeNotifier, BadgeState>(BadgeNotifier.new);
