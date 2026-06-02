import 'package:dayforge/features/dashboard/presentation/dashboard_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: dashboard.loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: dashboard.loadDashboard,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
            if (dashboard.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    dashboard.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            if (dashboard.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    DashboardMetrics(controller: dashboard),
                    const SizedBox(height: 14),
                    TodayTasksCard(tasks: dashboard.todaysTasks),
                    const SizedBox(height: 14),
                    ActiveHabitsCard(habits: dashboard.activeHabits),
                    const SizedBox(height: 14),
                    GoalProgressCard(goals: dashboard.goals),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DashboardMetrics extends StatelessWidget {
  const DashboardMetrics({required this.controller, super.key});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth < 720;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: useTwoColumns ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: useTwoColumns ? 1.65 : 1.9,
          children: [
            MetricCard(
              icon: Icons.pending_actions,
              label: 'Pending tasks',
              value: '${controller.pendingTaskCount}',
            ),
            MetricCard(
              icon: Icons.task_alt,
              label: 'Done tasks',
              value: '${controller.completedTaskCount}',
            ),
            MetricCard(
              icon: Icons.repeat,
              label: 'Habits today',
              value: '${controller.completedHabitCount}/${controller.habits.length}',
            ),
            MetricCard(
              icon: Icons.flag,
              label: 'Goal progress',
              value: '${controller.averageGoalProgress}%',
            ),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({required this.tasks, super.key});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: "Today's tasks",
      actionLabel: 'Open tasks',
      onAction: () => context.go('/tasks'),
      child: tasks.isEmpty
          ? const EmptyDashboardText('No tasks due today.')
          : Column(
              children: [
                for (final task in tasks.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      task.status == TaskStatus.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(task.title),
                    subtitle: Text(task.priority.label),
                  ),
              ],
            ),
    );
  }
}

class ActiveHabitsCard extends StatelessWidget {
  const ActiveHabitsCard({required this.habits, super.key});

  final List<HabitItem> habits;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Active habits',
      actionLabel: 'Open habits',
      onAction: () => context.go('/habits'),
      child: habits.isEmpty
          ? const EmptyDashboardText('No active habits yet.')
          : Column(
              children: [
                for (final habit in habits.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      habit.checkedInToday
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(habit.title),
                    subtitle: Text(
                      'Current streak ${habit.currentStreak}, best ${habit.bestStreak}',
                    ),
                  ),
              ],
            ),
    );
  }
}

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({required this.goals, super.key});

  final List<GoalItem> goals;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Goal progress',
      actionLabel: 'Open goals',
      onAction: () => context.go('/goals'),
      child: goals.isEmpty
          ? const EmptyDashboardText('No goals yet.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final goal in goals.take(5)) ...[
                  Row(
                    children: [
                      Expanded(child: Text(goal.title)),
                      Text('${goal.progress}%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: goal.progress / 100),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyDashboardText extends StatelessWidget {
  const EmptyDashboardText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text),
    );
  }
}
