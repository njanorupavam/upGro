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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: controller.loadAnalytics,
                      icon: const Icon(Icons.refresh),
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
            else if (analytics == null)
              const SliverFillRemaining(
                child: Center(child: Text('No analytics available yet.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    AnalyticsChart(analytics: analytics),
                    const SizedBox(height: 14),
                    AnalyticsSummary(analytics: analytics),
                  ]),
                ),
              ),
          ],
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

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity rates',
              style: Theme.of(context).textTheme.titleMedium,
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
                        getTitlesWidget: (value, meta) => Text('${value.round()}'),
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
          label: 'Tasks completed',
          value: '${analytics.tasksCompleted}/${analytics.totalTasks}',
        ),
        SummaryTile(
          label: 'Task completion',
          value: '${analytics.taskCompletionRate}%',
        ),
        SummaryTile(
          label: 'Habit completion',
          value: '${analytics.habitCompletionRate}%',
        ),
        SummaryTile(
          label: 'Goal progress',
          value: '${analytics.goalProgress}%',
        ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({
    required this.label,
    required this.value,
    super.key,
  });

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
