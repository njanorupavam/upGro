import 'package:dayforge/core/presentation/challenge_provider.dart';
import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/presentation/habits_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FocusModeScreen — Excel-style monthly habit tracker
// ─────────────────────────────────────────────────────────────────────────────

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsControllerProvider).habits;
    final challenge = ref.watch(challengeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth = _month == now.month && _year == now.year;

    final checkedToday = habits.where((h) => h.checkedInToday).length;
    final totalHabits = habits.length;

    // Build month map for all habits
    final habitGridData = {
      for (final h in habits) h.id: _buildMonthMap(h, _year, _month),
    };

    // Overall monthly completion
    int totalCompleted = 0;
    int totalTracked = 0;
    for (final map in habitGridData.values) {
      for (final entry in map.entries) {
        final day = entry.key;
        final isF = _isFuture(day, now, isCurrentMonth);
        if (!isF) {
          totalTracked++;
          if (entry.value) totalCompleted++;
        }
      }
    }
    final monthlyPct =
        totalTracked == 0 ? 0.0 : totalCompleted / totalTracked;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: DayForgeBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header bar ──────────────────────────────────────────────
                _FocusHeader(
                  month: _month,
                  year: _year,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  canGoNext: !isCurrentMonth,
                  daysInMonth: _daysInMonth,
                  checkedToday: checkedToday,
                  totalHabits: totalHabits,
                  monthlyPct: monthlyPct,
                  challengeDay: challenge.currentDay,
                  isActive: challenge.isActive,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // ── Summary pills ────────────────────────────────────────────
                _SummaryRow(
                  checkedToday: checkedToday,
                  totalHabits: totalHabits,
                  monthlyPct: monthlyPct,
                ),

                const SizedBox(height: 12),

                // ── Grid ─────────────────────────────────────────────────────
                if (habits.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view,
                            size: 52,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add habits to see the Focus Grid',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/habits'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Habits'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _FocusGrid(
                      habits: habits,
                      habitGridData: habitGridData,
                      daysInMonth: _daysInMonth,
                      year: _year,
                      month: _month,
                      now: now,
                      isCurrentMonth: isCurrentMonth,
                      onCheckIn: (habitId) async {
                        await ref
                            .read(habitsControllerProvider.notifier)
                            .checkIn(habitId);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a map from day-of-month → completed for a single habit
  Map<int, bool> _buildMonthMap(HabitItem habit, int year, int month) {
    final map = <int, bool>{};
    // Fill all days as false (no data = unknown/empty)
    for (int d = 1; d <= DateTime(year, month + 1, 0).day; d++) {
      map[d] = false;
    }
    // Fill from weeklyProgress
    for (final p in habit.weeklyProgress) {
      final date = DateTime.tryParse(p.date);
      if (date != null && date.year == year && date.month == month) {
        map[date.day] = p.completed;
      }
    }
    // Override today with live checkedInToday
    final now = DateTime.now();
    if (now.year == year && now.month == month) {
      map[now.day] = habit.checkedInToday;
    }
    return map;
  }

  bool _isFuture(int day, DateTime now, bool isCurrentMonth) {
    if (!isCurrentMonth) return false;
    return day > now.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FocusHeader
// ─────────────────────────────────────────────────────────────────────────────

class _FocusHeader extends StatelessWidget {
  const _FocusHeader({
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
    required this.daysInMonth,
    required this.checkedToday,
    required this.totalHabits,
    required this.monthlyPct,
    required this.challengeDay,
    required this.isActive,
    required this.isDark,
  });

  final int month, year, daysInMonth, checkedToday, totalHabits, challengeDay;
  final double monthlyPct;
  final bool canGoNext, isActive, isDark;
  final VoidCallback onPrev, onNext;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Month navigation
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.1),
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_months[month - 1]} $year',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$daysInMonth days',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Day $challengeDay of 21',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: canGoNext
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.outlineVariant.withOpacity(0.1),
              foregroundColor: canGoNext
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 12),
          // Today's progress ring
          ProgressRing(
            value: totalHabits == 0 ? 0 : checkedToday / totalHabits,
            label: 'Today',
            size: 72,
            centerText: '$checkedToday/$totalHabits',
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryRow
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.checkedToday,
    required this.totalHabits,
    required this.monthlyPct,
  });

  final int checkedToday, totalHabits;
  final double monthlyPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SummaryPill(
            label: 'Daily',
            value: '$checkedToday/$totalHabits',
            icon: Icons.today,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _SummaryPill(
            label: 'Monthly',
            value: '${(monthlyPct * 100).round()}%',
            icon: Icons.calendar_month,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: monthlyPct,
                        minHeight: 5,
                        backgroundColor:
                            theme.colorScheme.outlineVariant.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(monthlyPct * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FocusGrid — the main spreadsheet table
// ─────────────────────────────────────────────────────────────────────────────

class _FocusGrid extends StatelessWidget {
  const _FocusGrid({
    required this.habits,
    required this.habitGridData,
    required this.daysInMonth,
    required this.year,
    required this.month,
    required this.now,
    required this.isCurrentMonth,
    required this.onCheckIn,
  });

  final List<HabitItem> habits;
  final Map<String, Map<int, bool>> habitGridData;
  final int daysInMonth, year, month;
  final DateTime now;
  final bool isCurrentMonth;
  final Future<void> Function(String habitId) onCheckIn;

  static const double _rowH = 46.0;
  static const double _nameW = 170.0;
  static const double _cellW = 34.0;
  static const double _statW = 58.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Shared horizontal scroll controller
    final hScroll = ScrollController();

    final bgColor =
        isDark ? const Color(0x440F172A) : const Color(0x44FFFFFF);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LEFT STICKY: Habit names ──────────────────────────────
              SizedBox(
                width: _nameW,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header cell
                      _GridHeaderCell(
                        width: _nameW,
                        height: _rowH,
                        child: Text(
                          'HABIT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      // Habit name rows
                      for (final habit in habits)
                        _GridHabitNameCell(
                          habit: habit,
                          height: _rowH,
                          width: _nameW,
                        ),
                      // Bottom "Most Consistent" label row
                      _GridFooterCell(
                        label: 'CONSISTENCY',
                        width: _nameW,
                        height: 36,
                      ),
                    ],
                  ),
                ),
              ),
              // ── CENTER: Scrollable day columns ────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: hScroll,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header row
                      Row(
                        children: [
                          for (int d = 1; d <= daysInMonth; d++)
                            _DayHeaderCell(
                              day: d,
                              isToday: isCurrentMonth && d == now.day,
                              width: _cellW,
                              height: _rowH,
                            ),
                        ],
                      ),
                      // Habit day rows
                      for (final habit in habits)
                        _HabitDayRowCells(
                          habit: habit,
                          dayMap: habitGridData[habit.id] ?? {},
                          daysInMonth: daysInMonth,
                          year: year,
                          month: month,
                          now: now,
                          isCurrentMonth: isCurrentMonth,
                          cellW: _cellW,
                          rowH: _rowH,
                          onCheckIn: onCheckIn,
                        ),
                      // Completion % footer row
                      Row(
                        children: [
                          for (int d = 1; d <= daysInMonth; d++)
                            _DayCompletionFooterCell(
                              day: d,
                              habits: habits,
                              habitGridData: habitGridData,
                              isToday: isCurrentMonth && d == now.day,
                              isFuture: isCurrentMonth && d > now.day,
                              width: _cellW,
                              height: 36,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ── RIGHT STICKY: Streak + % stats ───────────────────────
              SizedBox(
                width: _statW * 2 + 54,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header cells
                      Row(
                        children: [
                          _GridHeaderCell(
                            width: _statW,
                            height: _rowH,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 12,
                                  color: theme.colorScheme.tertiary,
                                ),
                                Text(
                                  'Streak',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _GridHeaderCell(
                            width: _statW,
                            height: _rowH,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                Text(
                                  'Best',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _GridHeaderCell(
                            width: 54,
                            height: _rowH,
                            child: Text(
                              '%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Stat rows
                      for (final habit in habits)
                        _HabitStatRow(
                          habit: habit,
                          dayMap: habitGridData[habit.id] ?? {},
                          isCurrentMonth: isCurrentMonth,
                          now: now,
                          rowH: _rowH,
                          statW: _statW,
                        ),
                      // Footer row spacer
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            '${habits.isEmpty ? 0 : (habits.map((h) {
                              final map = habitGridData[h.id] ?? {};
                              int done = 0, total = 0;
                              for (final e in map.entries) {
                                if (!isCurrentMonth || e.key <= now.day) {
                                  total++;
                                  if (e.value) done++;
                                }
                              }
                              return total == 0 ? 0 : (done * 100 ~/ total);
                            }).reduce((a, b) => a + b)) ~/ (habits.isEmpty ? 1 : habits.length)}% avg',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid row/cell sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GridHeaderCell extends StatelessWidget {
  const _GridHeaderCell({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width, height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.15),
          ),
        ),
      ),
      child: child,
    );
  }
}

class _GridFooterCell extends StatelessWidget {
  const _GridFooterCell({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _GridHabitNameCell extends StatelessWidget {
  const _GridHabitNameCell({
    required this.habit,
    required this.height,
    required this.width,
  });

  final HabitItem habit;
  final double height, width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _categoryColor(habit);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.01),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.15),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.15),
          ),
          left: BorderSide(color: catColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _categoryIcon(habit),
            size: 14,
            color: catColor.withOpacity(0.8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              habit.title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(HabitItem h) {
    final t = h.title.toLowerCase();
    if (t.contains('work') || t.contains('read') || t.contains('task')) {
      return const Color(0xFF3B82F6);
    }
    if (t.contains('work') || t.contains('exercise') || t.contains('gym')) {
      return const Color(0xFF10B981);
    }
    if (t.contains('med') || t.contains('mind') || t.contains('journal')) {
      return const Color(0xFF8B5CF6);
    }
    if (t.contains('sleep') || t.contains('wake') || t.contains('eat')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF64748B);
  }

  IconData _categoryIcon(HabitItem h) {
    final t = h.title.toLowerCase();
    if (t.contains('water') || t.contains('hydra')) return Icons.water_drop;
    if (t.contains('med') || t.contains('breath')) {
      return Icons.self_improvement;
    }
    if (t.contains('read')) return Icons.menu_book;
    if (t.contains('work') || t.contains('exercise')) return Icons.fitness_center;
    if (t.contains('sleep') || t.contains('wake')) return Icons.bedtime;
    if (t.contains('journal') || t.contains('write')) return Icons.edit_note;
    if (t.contains('plan')) return Icons.checklist;
    return Icons.star;
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({
    required this.day,
    required this.isToday,
    required this.width,
    required this.height,
  });

  final int day;
  final bool isToday;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
            : isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
          ),
        ),
      ),
      child: Text(
        '$day',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isToday
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _HabitDayRowCells extends StatelessWidget {
  const _HabitDayRowCells({
    required this.habit,
    required this.dayMap,
    required this.daysInMonth,
    required this.year,
    required this.month,
    required this.now,
    required this.isCurrentMonth,
    required this.cellW,
    required this.rowH,
    required this.onCheckIn,
  });

  final HabitItem habit;
  final Map<int, bool> dayMap;
  final int daysInMonth, year, month;
  final DateTime now;
  final bool isCurrentMonth;
  final double cellW, rowH;
  final Future<void> Function(String habitId) onCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: rowH,
      child: Row(
        children: [
          for (int d = 1; d <= daysInMonth; d++)
            Builder(
              builder: (_) {
                final isFuture = isCurrentMonth && d > now.day;
                final isToday = isCurrentMonth && d == now.day;
                final completed = dayMap[d] ?? false;
                // Only interactive for today's unchecked cell
                final canTap = isToday && !completed;

                return SizedBox(
                  width: cellW,
                  height: rowH,
                  child: Center(
                    child: GridCell(
                      isCompleted: completed,
                      isToday: isToday,
                      hasData: !isFuture,
                      isFuture: isFuture,
                      size: 24,
                      onTap: canTap ? () => onCheckIn(habit.id) : null,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DayCompletionFooterCell extends StatelessWidget {
  const _DayCompletionFooterCell({
    required this.day,
    required this.habits,
    required this.habitGridData,
    required this.isToday,
    required this.isFuture,
    required this.width,
    required this.height,
  });

  final int day;
  final List<HabitItem> habits;
  final Map<String, Map<int, bool>> habitGridData;
  final bool isToday, isFuture;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isFuture || habits.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    int done = 0;
    for (final h in habits) {
      if (habitGridData[h.id]?[day] == true) done++;
    }
    final pct = done / habits.length;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Text(
        done > 0 ? '${(pct * 100).round()}%' : '',
        style: theme.textTheme.labelSmall?.copyWith(
          color: pct >= 1.0
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 8,
        ),
      ),
    );
  }
}

class _HabitStatRow extends StatelessWidget {
  const _HabitStatRow({
    required this.habit,
    required this.dayMap,
    required this.isCurrentMonth,
    required this.now,
    required this.rowH,
    required this.statW,
  });

  final HabitItem habit;
  final Map<int, bool> dayMap;
  final bool isCurrentMonth;
  final DateTime now;
  final double rowH, statW;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculate monthly completion %
    int done = 0, total = 0;
    for (final e in dayMap.entries) {
      if (!isCurrentMonth || e.key <= now.day) {
        total++;
        if (e.value) done++;
      }
    }
    final pct = total == 0 ? 0.0 : done / total;

    return SizedBox(
      height: rowH,
      child: Row(
        children: [
          // Current streak
          _StatCell(
            width: statW,
            height: rowH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, size: 12, color: theme.colorScheme.tertiary),
                Text(
                  '${habit.currentStreak}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Best streak
          _StatCell(
            width: statW,
            height: rowH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  '${habit.bestStreak}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // % completion bar
          _StatCell(
            width: 54,
            height: rowH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(pct * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: pct >= 0.8
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 0.8
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width, height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.15),
          ),
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
          ),
        ),
      ),
      child: child,
    );
  }
}
