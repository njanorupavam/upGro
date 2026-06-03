import 'dart:ui';
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
    final state = ref.watch(analyticsControllerProvider);
    final notifier = ref.read(analyticsControllerProvider.notifier);
    final analytics = state.analytics;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: notifier.loadAnalytics,
        child: DayForgePage(
          title: 'Progress Insights',
          subtitle: "Momentum is building. You're in the flow.",
          action: IconButton(
            tooltip: 'Refresh',
            onPressed: notifier.loadAnalytics,
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
              if (state.isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (analytics == null)
                const DayForgeCard(child: Text('No analytics available yet.'))
              else ...[
                AnalyticsSummary(analytics: analytics),
                const SizedBox(height: 18),
                WeeklyFlowCard(analytics: analytics),
                const SizedBox(height: 18),
                OverallConsistencyCard(analytics: analytics),
                const SizedBox(height: 18),
                MonthlyRitualsCard(analytics: analytics),
                const SizedBox(height: 24),
                const RecentWinsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12,
      children: [
        // Card 1: Tasks Completed (Focus Blue theme)
        DayForgeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks Completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${analytics.tasksCompleted}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${analytics.totalTasks}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: analytics.totalTasks == 0 ? 0 : analytics.tasksCompleted / analytics.totalTasks,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        // Card 2: Completion Rate (Success Green theme)
        DayForgeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion Rate',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${analytics.taskCompletionRate}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: analytics.taskCompletionRate / 100.0,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
        // Card 3: Habit Consistency (Neutral theme)
        DayForgeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habit Consistency',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${analytics.habitCompletionRate}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: analytics.habitCompletionRate / 100.0,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        // Card 4: Goal Progress (Progress Amber theme)
        DayForgeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal Progress',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${analytics.goalProgress}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 14, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    'New Record',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WeeklyFlowCard extends StatelessWidget {
  const WeeklyFlowCard({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DayForgeBadge(
                'Focus Hours',
                color: theme.colorScheme.primary.withOpacity(0.12),
                textColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _bar(context, 0, analytics.taskCompletionRate, true),
                  _bar(context, 1, analytics.habitCompletionRate, false),
                  _bar(context, 2, analytics.goalProgress, true),
                  _bar(context, 3, (analytics.taskCompletionRate + analytics.habitCompletionRate) ~/ 2, false),
                  _bar(context, 4, analytics.goalProgress - 8 > 0 ? analytics.goalProgress - 8 : 20, true),
                  _bar(context, 5, analytics.habitCompletionRate - 12 > 0 ? analytics.habitCompletionRate - 12 : 30, false),
                  _bar(context, 6, analytics.taskCompletionRate - 4 > 0 ? analytics.taskCompletionRate - 4 : 40, true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(BuildContext context, int x, int value, bool isHighlighted) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryBarColor = theme.colorScheme.primary;
    final fallbackBarColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.clamp(10, 100).toDouble(),
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          color: isHighlighted ? primaryBarColor : fallbackBarColor,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          ),
        ),
      ],
    );
  }
}

class OverallConsistencyCard extends StatelessWidget {
  const OverallConsistencyCard({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consistency = analytics.taskCompletionRate;

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Consistency',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're outperforming most users in your cohort.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elite Performance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: consistency / 100,
                        backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$consistency%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ConsistencyStat(
                  label: 'Consistency',
                  value: '+12%',
                  color: theme.colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _ConsistencyStat(
                  label: 'Peak Flow',
                  value: '4.2h',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsistencyStat extends StatelessWidget {
  const _ConsistencyStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MonthlyRitualsCard extends StatelessWidget {
  const MonthlyRitualsCard({required this.analytics, super.key});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Rituals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consistency visualization for the last 35 days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Less',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              for (int i = 0; i < 4; i++) ...[
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _getCellColor(theme, i),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Text(
                'More',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final intensity = (index * 7 + 13) % 4;
              return Container(
                decoration: BoxDecoration(
                  color: _getCellColor(theme, intensity),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.05 : 0.2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getCellColor(ThemeData theme, int intensity) {
    final isDark = theme.brightness == Brightness.dark;
    if (intensity == 0) {
      return isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    } else if (intensity == 1) {
      return theme.colorScheme.primary.withOpacity(0.2);
    } else if (intensity == 2) {
      return theme.colorScheme.primary.withOpacity(0.5);
    } else {
      return theme.colorScheme.primary;
    }
  }
}

class RecentWinsSection extends StatelessWidget {
  const RecentWinsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recent Wins',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Win 1
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x730F172A) : const Color(0x73FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up, color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productivity Peak',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You\'ve completed "Deep Work" 5 days in a row.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Win 2
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x730F172A) : const Color(0x73FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.nightlight_round, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evening Consistency',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"Meditation" habit is becoming a stable ritual.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
