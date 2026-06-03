import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _challengeStartKey = 'focusflow_challenge_start';

const List<String> kDailyQuotes = [
  '"We are what we repeatedly do. Excellence is not an act, but a habit." — Aristotle',
  '"You do not rise to the level of your goals. You fall to the level of your systems." — James Clear',
  '"Success is the sum of small efforts, repeated day in and day out." — Robert Collier',
  '"The secret of your future is hidden in your daily routine." — Mike Murdock',
  '"Motivation is what gets you started. Habit is what keeps you going." — Jim Ryun',
  '"Small daily improvements over time lead to stunning results." — Robin Sharma',
  '"Habit is the intersection of knowledge, skill, and desire." — Stephen Covey',
  '"First forget inspiration. Habit is more dependable." — Octavia Butler',
  '"The chains of habit are too strong to be felt until they are too strong to be broken." — Samuel Johnson',
  '"Good habits formed at youth make all the difference." — Aristotle',
  '"Make it so easy you can\'t say no." — Leo Babauta',
  '"You\'ll never change your life until you change something you do daily." — John C. Maxwell',
  '"Consistency is the key to achieving and maintaining momentum." — Darren Hardy',
  '"The difference between who you are and who you want to be is what you do." — Unknown',
  '"Discipline is doing what needs to be done even when you don\'t want to." — Unknown',
  '"Never miss twice. It\'s okay to miss once, but never miss two days in a row." — James Clear',
  '"Be consistent but not rigid." — Andrew Huberman',
  '"Every action you take is a vote for who you wish to become." — James Clear',
  '"The best time to plant a tree was 20 years ago. The second best time is now." — Chinese Proverb',
  '"Success is a few simple disciplines practiced every day." — Jim Rohn',
  '"After 21 days, you\'ve proven you can change. Now make it permanent." — Upgro',
];

class ChallengeState {
  final DateTime? startDate;
  final int currentDay;
  final bool isComplete;
  final String todayQuote;

  const ChallengeState({
    this.startDate,
    this.currentDay = 0,
    this.isComplete = false,
    this.todayQuote = '',
  });

  int get daysRemaining => (21 - currentDay).clamp(0, 21);
  double get progress => currentDay / 21;
  bool get isActive => startDate != null;
}

class ChallengeNotifier extends Notifier<ChallengeState> {
  @override
  ChallengeState build() {
    _load();
    return ChallengeState(todayQuote: kDailyQuotes[0]);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_challengeStartKey);
      if (stored != null) {
        final start = DateTime.tryParse(stored);
        if (start != null) {
          _update(start);
          return;
        }
      }
      state = ChallengeState(todayQuote: _todayQuote(0));
    } catch (_) {
      state = ChallengeState(todayQuote: _todayQuote(0));
    }
  }

  void _update(DateTime start) {
    final dayIndex = DateTime.now().difference(start).inDays;
    final currentDay = (dayIndex + 1).clamp(1, 21);
    final isComplete = dayIndex >= 21;
    state = ChallengeState(
      startDate: start,
      currentDay: currentDay,
      isComplete: isComplete,
      todayQuote: _todayQuote(dayIndex),
    );
  }

  String _todayQuote(int dayIndex) {
    final i = dayIndex.clamp(0, kDailyQuotes.length - 1);
    return kDailyQuotes[i];
  }

  Future<void> startChallenge() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_challengeStartKey, start.toIso8601String());
    } catch (_) {}
    _update(start);
  }

  Future<void> resetChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_challengeStartKey);
    } catch (_) {}
    state = ChallengeState(todayQuote: _todayQuote(0));
  }
}

final challengeProvider =
    NotifierProvider<ChallengeNotifier, ChallengeState>(ChallengeNotifier.new);
