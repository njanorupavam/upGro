import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(tasksControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadTasks,
        child: DayForgePage(
          title: 'Daily Planner',
          subtitle: 'Turn your focus into a clear list.',
          action: FilledButton.icon(
            onPressed: controller.isSaving
                ? null
                : () => _openTaskDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskFilters(controller: controller),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              if (controller.isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.tasks.isEmpty)
                const DayForgeCard(
                  child: Text('No tasks match the current filters.'),
                )
              else
                Column(
                  children: [
                    for (final task in controller.tasks) ...[
                      TaskTile(
                        task: task,
                        onToggleComplete: () => controller.toggleComplete(task),
                        onEdit: () => _openTaskDialog(context, ref, task: task),
                        onDelete: () => _deleteTask(context, controller, task),
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
        onPressed: controller.isSaving
            ? null
            : () => _openTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openTaskDialog(
    BuildContext context,
    WidgetRef ref, {
    TaskItem? task,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    TasksController controller,
    TaskItem task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Delete "${task.title}"?'),
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
      await controller.deleteTask(task.id);
    }
  }
}

class TaskFilters extends StatelessWidget {
  const TaskFilters({required this.controller, super.key});

  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilterChip(
          selected: controller.statusFilter == null,
          label: const Text('All statuses'),
          onSelected: (_) => controller.setStatusFilter(null),
        ),
        for (final status in TaskStatus.values)
          FilterChip(
            selected: controller.statusFilter == status,
            label: Text(status.label),
            onSelected: (_) => controller.setStatusFilter(status),
          ),
        const SizedBox(width: 8),
        FilterChip(
          selected: controller.priorityFilter == null,
          label: const Text('All priorities'),
          onSelected: (_) => controller.setPriorityFilter(null),
        ),
        for (final priority in TaskPriority.values)
          FilterChip(
            selected: controller.priorityFilter == priority,
            label: Text(priority.label),
            onSelected: (_) => controller.setPriorityFilter(priority),
          ),
      ],
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final TaskItem task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isComplete = task.status == TaskStatus.completed;

    return DayForgeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: isComplete ? 'Mark incomplete' : 'Mark complete',
            onPressed: onToggleComplete,
            icon: Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isComplete ? dayforgeGreen : dayforgeMuted,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: dayforgeInk,
                    fontWeight: FontWeight.w800,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: dayforgeMuted),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TaskBadge(task.status.label),
                    TaskBadge(task.priority.label),
                    if (task.dueDate != null)
                      TaskBadge(_formatDate(task.dueDate!)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit task',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete task',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class TaskBadge extends StatelessWidget {
  const TaskBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DayForgeBadge(label);
  }
}

class TaskFormDialog extends ConsumerStatefulWidget {
  const TaskFormDialog({this.task, super.key});

  final TaskItem? task;

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tasksControllerProvider);
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit task' : 'Create task'),
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
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    for (final priority in TaskPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in TaskStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _dueDate == null ? 'Set due date' : _formatDate(_dueDate!),
                  ),
                ),
                if (_dueDate != null)
                  TextButton(
                    onPressed: () => setState(() => _dueDate = null),
                    child: const Text('Clear due date'),
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      dueDate: _dueDate,
    );

    final controller = ref.read(tasksControllerProvider);
    final task = widget.task;
    final success = task == null
        ? await controller.createTask(draft)
        : await controller.updateTask(task.id, draft);

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
