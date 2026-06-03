import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _matrixView = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksControllerProvider);
    final notifier = ref.read(tasksControllerProvider.notifier);
    final activeCount = state.tasks
        .where((task) => task.status != TaskStatus.completed)
        .length;
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: state.isSaving
            ? null
            : () => _openTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadTasks,
        child: DayForgePage(
          title: 'Daily Tasks',
          subtitle: _todayLabel(),
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle between list / matrix view
              Tooltip(
                message: _matrixView ? 'List view' : 'Eisenhower matrix',
                child: IconButton(
                  onPressed: () => setState(() => _matrixView = !_matrixView),
                  icon: Icon(
                    _matrixView ? Icons.list : Icons.grid_4x4,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _matrixView
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.primaryContainer.withOpacity(0.3),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: notifier.loadTasks,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_matrixView) const TaskFilters(),
              if (!_matrixView) const SizedBox(height: 16),
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (_matrixView)
                EisenhowerMatrix(
                  tasks: state.tasks,
                  onToggleComplete: (task) => notifier.toggleComplete(task),
                  onEdit: (task) => _openTaskDialog(context, ref, task: task),
                  onDelete: (task) => _deleteTask(context, notifier, task),
                )
              else ...[
                TodayLogCard(
                  tasks: state.tasks,
                  activeCount: activeCount,
                  onAddTask: state.isSaving
                      ? null
                      : () => _openTaskDialog(context, ref),
                ),
                const SizedBox(height: 16),
                const FocusZoneCard(),
                const SizedBox(height: 16),
                const PulseCard(),
                const SizedBox(height: 16),
                if (state.isLoading)
                  const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.tasks.isEmpty)
                  const DayForgeCard(
                    child: Text('No tasks match the current filters.'),
                  )
                else
                  Column(
                    children: [
                      for (final task in state.tasks) ...[
                        TaskTile(
                          task: task,
                          onToggleComplete: () =>
                              notifier.toggleComplete(task),
                          onEdit: () =>
                              _openTaskDialog(context, ref, task: task),
                          onDelete: () =>
                              _deleteTask(context, notifier, task),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ],
          ),
        ),
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
    TasksNotifier notifier,
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
      await notifier.deleteTask(task.id);
    }
  }
}

class TaskFilters extends ConsumerWidget {
  const TaskFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksControllerProvider);
    final notifier = ref.read(tasksControllerProvider.notifier);

    return DayForgeCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilterChip(
            selected: state.statusFilter == null,
            label: const Text('All'),
            onSelected: (_) => notifier.setStatusFilter(null),
          ),
          for (final status in TaskStatus.values)
            FilterChip(
              selected: state.statusFilter == status,
              label: Text(status.label),
              onSelected: (_) => notifier.setStatusFilter(status),
            ),
          FilterChip(
            selected: state.priorityFilter == null,
            label: const Text('Priority'),
            onSelected: (_) => notifier.setPriorityFilter(null),
          ),
          for (final priority in TaskPriority.values)
            FilterChip(
              selected: state.priorityFilter == priority,
              label: Text(priority.label),
              onSelected: (_) => notifier.setPriorityFilter(priority),
            ),
        ],
      ),
    );
  }
}

class TodayLogCard extends StatelessWidget {
  const TodayLogCard({
    required this.tasks,
    required this.activeCount,
    required this.onAddTask,
    super.key,
  });

  final List<TaskItem> tasks;
  final int activeCount;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final highlighted = tasks.isNotEmpty ? tasks.first : null;

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: Icons.format_list_bulleted_add),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s Log',
                  style: TextStyle(
                    color: context.dayforgeText,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              DayForgeBadge('$activeCount Active'),
            ],
          ),
          const SizedBox(height: 16),
          if (highlighted != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          highlighted.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.dayforgeText,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (highlighted.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            highlighted.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.dayforgeMuted),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DayForgeBadge(highlighted.priority.label),
                            DayForgeBadge(highlighted.status.label),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'No tasks match the current filter.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add),
            label: const Text('Log a new task'),
          ),
        ],
      ),
    );
  }
}

class FocusZoneCard extends ConsumerWidget {
  const FocusZoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksControllerProvider);
    final total = state.tasks.length;
    final completed = state.tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final completion = total == 0 ? 0.0 : completed / total;

    return DayForgeCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Zone',
                  style: TextStyle(
                    color: context.dayforgeText,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(completion * 100).round()}% complete',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: context.dayforgeText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total tasks are done.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: context.dayforgeMuted),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: completion,
                    backgroundColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const IconBubble(icon: Icons.timer_outlined),
        ],
      ),
    );
  }
}

class PulseCard extends ConsumerWidget {
  const PulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksControllerProvider);
    final completed = state.tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final priorityCount = state.tasks
        .where((task) => task.priority == TaskPriority.high)
        .length;

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pulse',
            style: TextStyle(
              color: context.dayforgeText,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 14),
          _PulseRow(
            icon: Icons.check_circle_outline,
            label: 'Completed',
            value: completed,
            tint: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 10),
          _PulseRow(
            icon: Icons.bolt_outlined,
            label: 'Priority',
            value: priorityCount,
            tint: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.dayforgeText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.dayforgeText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: isComplete ? 'Mark incomplete' : 'Mark complete',
            onPressed: onToggleComplete,
            icon: Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isComplete ? Theme.of(context).colorScheme.secondary : context.dayforgeMuted,
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
                    color: context.dayforgeText,
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
                    ).textTheme.bodySmall?.copyWith(color: context.dayforgeMuted),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TaskBadge(task.status.label),
                    TaskBadge(
                      task.priority.label,
                      color: task.priority == TaskPriority.high
                          ? Theme.of(context).colorScheme.error.withOpacity(0.12)
                          : (task.priority == TaskPriority.medium
                              ? Theme.of(context).colorScheme.tertiary.withOpacity(0.12)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.12)),
                      textColor: task.priority == TaskPriority.high
                          ? Theme.of(context).colorScheme.error
                          : (task.priority == TaskPriority.medium
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Eisenhower Matrix (2×2 quadrant view)
// ─────────────────────────────────────────────────────────────────────────────

class EisenhowerMatrix extends StatelessWidget {
  const EisenhowerMatrix({
    required this.tasks,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<TaskItem> tasks;
  final void Function(TaskItem) onToggleComplete;
  final void Function(TaskItem) onEdit;
  final void Function(TaskItem) onDelete;

  // Map priority → quadrant for auto-assignment when quadrant not set
  static TaskQuadrant _inferQuadrant(TaskItem t) {
    if (t.priority == TaskPriority.high) return TaskQuadrant.doFirst;
    if (t.priority == TaskPriority.medium) return TaskQuadrant.schedule;
    return TaskQuadrant.delegate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final q1 = tasks.where((t) => _inferQuadrant(t) == TaskQuadrant.doFirst).toList();
    final q2 = tasks.where((t) => _inferQuadrant(t) == TaskQuadrant.schedule).toList();
    final q3 = tasks.where((t) => _inferQuadrant(t) == TaskQuadrant.delegate).toList();
    final q4 = tasks.where((t) => _inferQuadrant(t) == TaskQuadrant.eliminate).toList();

    final quadrants = [
      (q: TaskQuadrant.doFirst, tasks: q1, color: theme.colorScheme.error),
      (q: TaskQuadrant.schedule, tasks: q2, color: theme.colorScheme.primary),
      (q: TaskQuadrant.delegate, tasks: q3, color: theme.colorScheme.tertiary),
      (q: TaskQuadrant.eliminate, tasks: q4, color: theme.colorScheme.onSurfaceVariant),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header legend
      Padding(padding: const EdgeInsets.only(bottom: 12), child:
        Row(children: [
          Expanded(child: Center(child: Text('URGENT', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w800, letterSpacing: 1)))),
          Expanded(child: Center(child: Text('NOT URGENT', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1)))),
        ]),
      ),
      // Row 1: Q1 (Urgent+Important) | Q2 (Not Urgent+Important)
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _QuadrantCell(quadrant: quadrants[0], tasks: q1, onToggle: onToggleComplete, onEdit: onEdit, onDelete: onDelete, rowLabel: 'IMPORTANT')),
        const SizedBox(width: 10),
        Expanded(child: _QuadrantCell(quadrant: quadrants[1], tasks: q2, onToggle: onToggleComplete, onEdit: onEdit, onDelete: onDelete, rowLabel: '')),
      ])),
      const SizedBox(height: 10),
      // Row 2: Q3 (Urgent+Not Important) | Q4 (Not Urgent+Not Important)
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _QuadrantCell(quadrant: quadrants[2], tasks: q3, onToggle: onToggleComplete, onEdit: onEdit, onDelete: onDelete, rowLabel: 'NOT IMPORTANT')),
        const SizedBox(width: 10),
        Expanded(child: _QuadrantCell(quadrant: quadrants[3], tasks: q4, onToggle: onToggleComplete, onEdit: onEdit, onDelete: onDelete, rowLabel: '')),
      ])),
    ]);
  }
}

class _QuadrantCell extends StatelessWidget {
  const _QuadrantCell({
    required this.quadrant,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.rowLabel,
  });

  final ({TaskQuadrant q, List<TaskItem> tasks, Color color}) quadrant;
  final List<TaskItem> tasks;
  final void Function(TaskItem) onToggle, onEdit, onDelete;
  final String rowLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = quadrant.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                quadrant.q.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(
              quadrant.q.description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          if (rowLabel.isNotEmpty) ...[const SizedBox(height: 4), Text(rowLabel, style: theme.textTheme.labelSmall?.copyWith(color: color.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5))],
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Text('No tasks', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), fontStyle: FontStyle.italic))
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onToggle(task),
                  child: Row(
                    children: [
                      Icon(
                        task.status == TaskStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: task.status == TaskStatus.completed ? theme.colorScheme.secondary : color.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: task.status == TaskStatus.completed
                                ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────────────────────────────────────
// TaskBadge
// ─────────────────────────────────────────────────────────────────────────────

class TaskBadge extends StatelessWidget {
  const TaskBadge(
    this.label, {
    this.color,
    this.textColor,
    super.key,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return DayForgeBadge(label, color: color, textColor: textColor);
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
    final state = ref.watch(tasksControllerProvider);
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

    final notifier = ref.read(tasksControllerProvider.notifier);
    final task = widget.task;
    final success = task == null
        ? await notifier.createTask(draft)
        : await notifier.updateTask(task.id, draft);

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
