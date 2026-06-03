import 'dart:ui';
import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/presentation/habits_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    final notifier = ref.read(habitsControllerProvider.notifier);
    final checkedInCount = state.habits
        .where((habit) => habit.checkedInToday)
        .length;
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: state.isSaving ? null : () => _openHabitDialog(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadHabits,
        child: DayForgePage(
          title: 'Habit Tracker',
          subtitle: _todayLabel(),
          action: IconButton(
            tooltip: 'Refresh',
            onPressed: notifier.loadHabits,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              WeekStrip(habits: state.habits),
              const SizedBox(height: 18),
              MomentumCard(
                checkedInCount: checkedInCount,
                total: state.habits.length,
                longestStreak: _longestStreak(state.habits),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Daily Routine',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/focus'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.grid_view,
                                size: 12,
                                color: theme.colorScheme.tertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Focus Grid',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () => _openHabitDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New habit'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (state.isLoading)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.habits.isEmpty)
                const DayForgeCard(child: Text('No habits yet.'))
              else
                Column(
                  children: [
                    for (final habit in state.habits) ...[
                      HabitTile(
                        habit: habit,
                        onCheckIn: habit.checkedInToday
                            ? null
                            : () => notifier.checkIn(habit.id),
                        onEdit: () => _openHabitDialog(context, habit: habit),
                        onDelete: () =>
                            _deleteHabit(context, notifier, habit),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHabitDialog(
    BuildContext context, {
    HabitItem? habit,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => HabitFormDialog(habit: habit),
    );
  }

  Future<void> _deleteHabit(
    BuildContext context,
    HabitsNotifier notifier,
    HabitItem habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit'),
        content: Text('Delete "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteHabit(habit.id);
    }
  }
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({required this.habits, super.key});

  final List<HabitItem> habits;

  @override
  Widget build(BuildContext context) {
    final days = habits.isNotEmpty
        ? habits.first.weeklyProgress
        : const <WeeklyHabitProgress>[];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0x331E293B)
            : const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in days.take(7)) _DayPill(day: day),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day});

  final WeeklyHabitProgress day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final parsedDate = DateTime.tryParse(day.date);
    final now = DateTime.now();
    final isToday = parsedDate != null &&
        parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day;

    final label = _dayLabel(day.date);
    final dayName = label.isNotEmpty ? label[0] : '';
    final dayNum = label.length > 1 ? label.substring(1) : '';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: isToday
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.03 : 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: day.completed
                      ? theme.colorScheme.secondary.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isToday
                    ? Colors.white.withOpacity(0.85)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayNum,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isToday
                    ? Colors.white
                    : (day.completed ? theme.colorScheme.secondary : theme.colorScheme.onSurface),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (day.completed && !isToday) ...[
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MomentumCard extends StatelessWidget {
  const MomentumCard({
    required this.checkedInCount,
    required this.total,
    required this.longestStreak,
    super.key,
  });

  final int checkedInCount;
  final int total;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final value = total == 0 ? 0.0 : checkedInCount / total;

    return DayForgeCard(
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Opacity(
              opacity: isDark ? 0.08 : 0.04,
              child: Icon(
                Icons.trending_up,
                size: 130,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Momentum',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$checkedInCount of $total habits completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          color: theme.colorScheme.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$longestStreak Day Streak',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(value: value, label: 'Complete', size: 100),
            ],
          ),
        ],
      ),
    );
  }
}

class HabitTile extends StatelessWidget {
  const HabitTile({
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    this.onCheckIn,
    super.key,
  });

  final HabitItem habit;
  final VoidCallback? onCheckIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completed = habit.checkedInToday;

    final catColor = _catColor(habit);
    final iconData = _catIcon(habit);
    final iconColor = catColor;

    final completionRate = habit.weeklyProgress.isEmpty
        ? 0.0
        : habit.weeklyProgress.where((day) => day.completed).length /
              habit.weeklyProgress.length;

    return Container(
      decoration: BoxDecoration(
        color: completed
            ? (isDark
                ? theme.colorScheme.secondary.withOpacity(0.06)
                : theme.colorScheme.secondary.withOpacity(0.04))
            : (isDark ? const Color(0x730F172A) : const Color(0x73FFFFFF)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? theme.colorScheme.secondary.withOpacity(0.4)
              : Colors.white.withOpacity(isDark ? 0.08 : 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.12) : const Color(0x0A1F2687),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: completed
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (habit.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                habit.category!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              completed
                                  ? 'Done for today!'
                                  : (habit.description ?? 'Daily routine'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: completed
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: completionRate,
                          backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completed ? theme.colorScheme.secondary : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DayForgeBadge('${habit.currentStreak}d'),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onCheckIn,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed
                              ? theme.colorScheme.secondary
                              : Colors.white.withOpacity(isDark ? 0.05 : 0.3),
                          border: Border.all(
                            color: completed
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.outline,
                            width: 2,
                          ),
                          boxShadow: completed
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.secondary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: completed
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Icon(
                                Icons.check,
                                color: theme.colorScheme.outline.withOpacity(0.5),
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HabitFormDialog extends ConsumerStatefulWidget {
  const HabitFormDialog({this.habit, super.key});

  final HabitItem? habit;

  @override
  ConsumerState<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends ConsumerState<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _selectedCategory;
  int _targetFrequency = 7;

  static const _categories = ['Work', 'Health', 'Mind', 'Lifestyle', 'Custom'];
  static const _freqOptions = [
    (label: 'Daily (7/7)', value: 7),
    (label: 'Weekdays (5/7)', value: 5),
    (label: 'Weekends (2/7)', value: 2),
    (label: '3× a week', value: 3),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _selectedCategory = widget.habit?.category;
    _targetFrequency = widget.habit?.targetFrequency ?? 7;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsControllerProvider);
    final isEditing = widget.habit != null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Habit title',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory =
                              selected ? null : cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Frequency Goal',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _freqOptions.map((opt) {
                    final selected = _targetFrequency == opt.value;
                    return FilterChip(
                      label: Text(opt.label),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _targetFrequency = opt.value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.isSaving ? null : _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = HabitDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      targetFrequency: _targetFrequency,
    );

    final notifier = ref.read(habitsControllerProvider.notifier);
    final habit = widget.habit;
    final success = habit == null
        ? await notifier.createHabit(draft)
        : await notifier.updateHabit(habit.id, draft);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

int _longestStreak(List<HabitItem> habits) {
  if (habits.isEmpty) return 0;
  return habits
      .map((habit) => habit.currentStreak)
      .reduce((a, b) => a > b ? a : b);
}

Color _catColor(HabitItem h) {
  switch (h.category?.toLowerCase()) {
    case 'work':
      return const Color(0xFF3B82F6);
    case 'health':
      return const Color(0xFF10B981);
    case 'mind':
      return const Color(0xFF8B5CF6);
    case 'lifestyle':
      return const Color(0xFFF59E0B);
    default:
      final t = h.title.toLowerCase();
      if (t.contains('water') || t.contains('hydr')) return const Color(0xFF3B82F6);
      if (t.contains('run') || t.contains('workout') || t.contains('gym')) return const Color(0xFF10B981);
      if (t.contains('med') || t.contains('mind') || t.contains('journal')) return const Color(0xFF8B5CF6);
      if (t.contains('sleep') || t.contains('wake')) return const Color(0xFFF59E0B);
      return const Color(0xFF64748B);
  }
}

IconData _catIcon(HabitItem h) {
  switch (h.category?.toLowerCase()) {
    case 'work': return Icons.work_outline;
    case 'health': return Icons.favorite_outline;
    case 'mind': return Icons.self_improvement;
    case 'lifestyle': return Icons.wb_sunny_outlined;
    default:
      final t = h.title.toLowerCase();
      if (t.contains('water')) return Icons.water_drop;
      if (t.contains('read')) return Icons.menu_book;
      if (t.contains('run') || t.contains('workout')) return Icons.fitness_center;
      if (t.contains('sleep') || t.contains('wake')) return Icons.bedtime;
      if (t.contains('journal') || t.contains('write')) return Icons.edit_note;
      return Icons.star;
  }
}

String _dayLabel(String raw) {
  try {
    final date = DateTime.parse(raw);
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return '${names[date.weekday - 1]}${date.day}';
  } catch (_) {
    return raw.length >= 10 ? raw.substring(5, 10) : raw;
  }
}

String _todayLabel() {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final now = DateTime.now();
  return '${months[now.month - 1]} ${now.day}, ${now.year}';
}
