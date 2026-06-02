import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/goals/presentation/goals_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(goalsControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadGoals,
        child: DayForgePage(
          title: 'Goal Studio',
          subtitle: 'Track outcomes without losing the day.',
          action: FilledButton.icon(
            onPressed: controller.isSaving
                ? null
                : () => _openGoalDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.errorMessage != null) ...[
                Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (controller.isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.goals.isEmpty)
                const DayForgeCard(child: Text('No goals yet.'))
              else
                Column(
                  children: [
                    for (final goal in controller.goals) ...[
                      GoalTile(
                        goal: goal,
                        onEdit: () => _openGoalDialog(context, goal: goal),
                        onDelete: () => _deleteGoal(context, controller, goal),
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
        onPressed: controller.isSaving ? null : () => _openGoalDialog(context),
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
    GoalsController controller,
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
      await controller.deleteGoal(goal.id);
    }
  }
}

class GoalTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final progress = goal.progress / 100;

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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: dayforgeInk,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (goal.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: dayforgeMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit goal',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete goal',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress,
                backgroundColor: dayforgeSoftBlue,
                valueColor: const AlwaysStoppedAnimation<Color>(dayforgeBlue),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DayForgeBadge('${goal.progress}% complete'),
                const Spacer(),
                if (goal.targetDate != null)
                  Text(
                    'Target ${_formatDate(goal.targetDate!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: dayforgeMuted),
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
    _progress = goal?.progress ?? 0;
    _targetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(goalsControllerProvider);
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
          onPressed: controller.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: controller.isSaving ? null : _submit,
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
    );

    final controller = ref.read(goalsControllerProvider);
    final goal = widget.goal;
    final success = goal == null
        ? await controller.createGoal(draft)
        : await controller.updateGoal(goal.id, draft);

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
