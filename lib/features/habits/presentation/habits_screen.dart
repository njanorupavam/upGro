import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/habits/presentation/habits_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(habitsControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadHabits,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Habits',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: controller.isSaving
                          ? null
                          : () => _openHabitDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New habit'),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    controller.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            if (controller.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.habits.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No habits yet.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: controller.habits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final habit = controller.habits[index];
                    return HabitTile(
                      habit: habit,
                      onCheckIn: habit.checkedInToday
                          ? null
                          : () => controller.checkIn(habit.id),
                      onEdit: () => _openHabitDialog(context, habit: habit),
                      onDelete: () => _deleteHabit(context, controller, habit),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.isSaving ? null : () => _openHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openHabitDialog(BuildContext context, {HabitItem? habit}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => HabitFormDialog(habit: habit),
    );
  }

  Future<void> _deleteHabit(
    BuildContext context,
    HabitsController controller,
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
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteHabit(habit.id);
    }
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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        habit.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (habit.description != null) ...[
                        const SizedBox(height: 4),
                        Text(habit.description!),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit habit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete habit',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                HabitStat(label: 'Current', value: habit.currentStreak),
                const SizedBox(width: 12),
                HabitStat(label: 'Best', value: habit.bestStreak),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onCheckIn,
                  icon: Icon(
                    habit.checkedInToday
                        ? Icons.check_circle
                        : Icons.add_task,
                  ),
                  label: Text(habit.checkedInToday ? 'Done today' : 'Check in'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final day in habit.weeklyProgress)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: day.date,
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: day.completed
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HabitStat extends StatelessWidget {
  const HabitStat({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
      ],
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(habitsControllerProvider);
    final isEditing = widget.habit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit habit' : 'Create habit'),
      content: Form(
        key: _formKey,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: controller.isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: controller.isSaving ? null : _submit,
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
    );

    final controller = ref.read(habitsControllerProvider);
    final habit = widget.habit;
    final success = habit == null
        ? await controller.createHabit(draft)
        : await controller.updateHabit(habit.id, draft);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}
