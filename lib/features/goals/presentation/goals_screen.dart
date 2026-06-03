import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/presentation/goals_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalsControllerProvider);
    final notifier = ref.read(goalsControllerProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: notifier.loadGoals,
        child: DayForgePage(
          title: 'Goal Studio',
          subtitle: 'Track outcomes without losing the day.',
          action: FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => _openGoalDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (state.isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.goals.isEmpty)
                const DayForgeCard(child: Text('No goals yet.'))
              else
                Column(
                  children: [
                    for (final goal in state.goals) ...[
                      GoalTile(
                        goal: goal,
                        onEdit: () => _openGoalDialog(context, goal: goal),
                        onDelete: () => _deleteGoal(context, notifier, goal),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.isSaving ? null : () => _openGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openGoalDialog(BuildContext context, {GoalItem? goal}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => GoalFormDialog(goal: goal),
    );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    GoalsNotifier notifier,
    GoalItem goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal'),
        content: Text('Delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteGoal(goal.id);
    }
  }
}

class GoalTile extends ConsumerStatefulWidget {
  const GoalTile({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final GoalItem goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends ConsumerState<GoalTile> {
  bool _showWhy = false;
  int? _localProgress;

  @override
  void didUpdateWidget(GoalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goal.progress != oldWidget.goal.progress) {
      _localProgress = null;
    }
  }

  int get displayProgress => _localProgress ?? widget.goal.progress;

  Future<void> _saveProgress(int newProgress) async {
    setState(() {
      _localProgress = newProgress;
    });

    final draft = GoalDraft(
      title: widget.goal.title,
      progress: newProgress,
      description: widget.goal.description,
      targetDate: widget.goal.targetDate,
      motivationNote: widget.goal.motivationNote,
    );

    final success = await ref
        .read(goalsControllerProvider.notifier)
        .updateGoal(widget.goal.id, draft);

    if (!success) {
      setState(() {
        _localProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final currentProgressVal = displayProgress;
    final progressFraction = currentProgressVal / 100;
    
    final hasNote = goal.motivationNote != null &&
        goal.motivationNote!.isNotEmpty;

    return DayForgeCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.dayforgeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (goal.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: context.dayforgeMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasNote)
                  IconButton(
                    tooltip: _showWhy ? 'Hide motivation' : 'Remind me why',
                    onPressed: () => setState(() => _showWhy = !_showWhy),
                    icon: Icon(
                      _showWhy ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: _showWhy
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                IconButton(
                  tooltip: 'Edit goal',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete goal',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            // Motivation note expand
            if (hasNote && _showWhy) ...[
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(isDark ? 0.1 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.motivationNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: currentProgressVal > 0
                      ? () => _saveProgress((currentProgressVal - 5).clamp(0, 100))
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: theme.sliderTheme.copyWith(
                      trackHeight: 6,
                      activeTrackColor: progressFraction >= 1.0 ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      thumbColor: progressFraction >= 1.0 ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      overlayColor: (progressFraction >= 1.0 ? theme.colorScheme.secondary : theme.colorScheme.primary).withOpacity(0.12),
                      valueIndicatorColor: progressFraction >= 1.0 ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    child: Slider(
                      value: currentProgressVal.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$currentProgressVal%',
                      onChanged: (val) {
                        setState(() {
                          _localProgress = val.round();
                        });
                      },
                      onChangeEnd: (val) {
                        _saveProgress(val.round());
                      },
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: currentProgressVal < 100
                      ? () => _saveProgress((currentProgressVal + 5).clamp(0, 100))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: DayForgeBadge(
                    '$currentProgressVal% complete',
                    color: progressFraction >= 1.0
                        ? theme.colorScheme.secondary.withOpacity(0.15)
                        : null,
                    textColor: progressFraction >= 1.0
                        ? theme.colorScheme.secondary
                        : null,
                  ),
                ),
                const Spacer(),
                if (goal.targetDate != null)
                  Text(
                    'Target ${_formatDate(goal.targetDate!)}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: context.dayforgeMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class GoalFormDialog extends ConsumerStatefulWidget {
  const GoalFormDialog({this.goal, super.key});

  final GoalItem? goal;

  @override
  ConsumerState<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends ConsumerState<GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _whyController;
  late int _progress;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    _whyController = TextEditingController(
      text: goal?.motivationNote ?? '',
    );
    _progress = goal?.progress ?? 0;
    _targetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsControllerProvider);
    final isEditing = widget.goal != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit goal' : 'Create goal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
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
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Text('Progress: $_progress%')),
                    SizedBox(
                      width: 220,
                      child: Slider(
                        value: _progress.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '$_progress%',
                        onChanged: (value) {
                          setState(() => _progress = value.round());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _whyController,
                  decoration: const InputDecoration(
                    labelText: '💡 Why do you want this?',
                    hintText: 'Your motivation note — shown as a reminder on your goal card',
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickTargetDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _targetDate == null
                        ? 'Set target date'
                        : _formatDate(_targetDate!),
                  ),
                ),
                if (_targetDate != null)
                  TextButton(
                    onPressed: () => setState(() => _targetDate = null),
                    child: const Text('Clear target date'),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.isSaving ? null : _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selected != null) {
      setState(() => _targetDate = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = GoalDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      targetDate: _targetDate,
      progress: _progress,
      motivationNote: _whyController.text.trim().isEmpty
          ? null
          : _whyController.text.trim(),
    );

    final notifier = ref.read(goalsControllerProvider.notifier);
    final goal = widget.goal;
    final success = goal == null
        ? await notifier.createGoal(draft)
        : await notifier.updateGoal(goal.id, draft);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
