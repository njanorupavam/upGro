import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/analytics/data/analytics_models.dart';
import 'package:dayforge/features/analytics/presentation/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(analyticsControllerProvider);
    final analytics = controller.analytics;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadAnalytics,
        child: DayForgePage(
          title: 'Progress Analytics',
          subtitle: 'See where your momentum is building.',
          trailing: IconButton.filledTonal(
            tooltip: 'Refresh',
            onPressed: controller.loadAnalytics,
            icon: const Icon(Icons.refresh),
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
              else if (analytics == null)
                const DayForgeCard(child: Text('No analytics available yet.'))
              else ...[
                AnalyticsSummary(analytics: analytics),
                const SizedBox(height: 16),
                AnalyticsChart(analytics: analytics),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AnalyticsChart extends StatelessWidget {
  const AnalyticsChart({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return DayForgeCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity rates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: dayforgeInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 25,
                        getTitlesWidget: (value, meta) =>
                            Text('${value.round()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final labels = ['Tasks', 'Habits', 'Goals'];
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[index]),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    _bar(0, analytics.taskCompletionRate, color),
                    _bar(1, analytics.habitCompletionRate, color),
                    _bar(2, analytics.goalProgress, color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 34,
          borderRadius: BorderRadius.circular(6),
          color: color,
        ),
      ],
    );
  }
}

class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        SummaryTile(
          icon: Icons.task_alt,
          label: 'Tasks completed',
          value: '${analytics.tasksCompleted}/${analytics.totalTasks}',
        ),
        SummaryTile(
          icon: Icons.speed,
          label: 'Task completion',
          value: '${analytics.taskCompletionRate}%',
        ),
        SummaryTile(
          icon: Icons.repeat,
          label: 'Habit completion',
          value: '${analytics.habitCompletionRate}%',
        ),
        SummaryTile(
          icon: Icons.flag,
          label: 'Goal progress',
          value: '${analytics.goalProgress}%',
        ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({
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
    return DayForgeCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBubble(icon: icon),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: dayforgeInk,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: dayforgeMuted),
            ),
          ],
        ),
      ),
    );
  }
}
