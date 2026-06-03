import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/dashboard/presentation/dashboard_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/core/presentation/badge_provider.dart';
import 'package:dayforge/core/presentation/focus_timer_provider.dart';
import 'package:dayforge/core/presentation/reflection_provider.dart';
import 'package:dayforge/core/presentation/challenge_provider.dart';
import 'package:dayforge/core/presentation/voice_assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAssistant = false;
  bool _isListening = false;
  String _transcriptText = "";
  String _statusMessage = "Click mic to speak";
  String _errorText = "";
  final List<String> _commandHistory = [];

  void _startSpeech() {
    if (!VoiceAssistantService.isSupported) {
      setState(() {
        _errorText = "Speech recognition is not supported in this browser.";
        _statusMessage = "Unsupported browser";
      });
      return;
    }

    setState(() {
      _isListening = true;
      _errorText = "";
      _statusMessage = "Listening...";
    });

    VoiceAssistantService.startListening(
      onTranscribed: (text) async {
        setState(() {
          _transcriptText = text;
          _statusMessage = "Processing...";
        });

        final result = await VoiceAssistantService.processCommand(ref, text);

        setState(() {
          _statusMessage = result;
          _commandHistory.insert(0, result);
        });
      },
      onStatusChanged: (status) {
        setState(() {
          if (status == "listening") {
            _isListening = true;
            _statusMessage = "Listening...";
          } else if (status == "stopped") {
            _isListening = false;
            if (_statusMessage == "Listening...") {
              _statusMessage = "Stopped listening";
            }
          }
        });
      },
      onError: (error) {
        setState(() {
          _errorText = "Error: $error";
          _isListening = false;
          _statusMessage = "Click mic to try again";
        });
      },
    );
  }

  void _stopSpeech() {
    VoiceAssistantService.stopListening();
    setState(() {
      _isListening = false;
      _statusMessage = "Mic turned off";
    });
  }

  @override
  void dispose() {
    VoiceAssistantService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final badgeState = ref.watch(badgeProvider);
    final theme = Theme.of(context);

    Widget screen = Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).loadDashboard(),
        child: DayForgePage(
          title: 'Daily Dashboard',
          subtitle: _todayLabel(),
          trailing: IconButton.filledTonal(
            tooltip: 'Refresh',
            onPressed: () => ref.read(dashboardControllerProvider.notifier).loadDashboard(),
            icon: const Icon(Icons.refresh),
          ),
          action: IconButton.filled(
            tooltip: 'Voice Assistant',
            onPressed: () {
              setState(() {
                _showAssistant = !_showAssistant;
              });
              if (_showAssistant) {
                _startSpeech();
              } else {
                _stopSpeech();
              }
            },
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            style: IconButton.styleFrom(
              backgroundColor: _isListening
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          child: dashboard.isLoading
              ? const SizedBox(
                  height: 420,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (dashboard.errorMessage != null) ...[
                      Text(
                        dashboard.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useRow = constraints.maxWidth >= 720;
                        final timerCard = const _FocusTimerCard();
                        final heroCard = HeroFocusCard(controller: dashboard);
                        if (useRow) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: heroCard),
                              const SizedBox(width: 16),
                              Expanded(child: timerCard),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heroCard,
                              const SizedBox(height: 16),
                              timerCard,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DashboardMetrics(controller: dashboard),
                    const SizedBox(height: 16),
                    TodayTasksCard(tasks: dashboard.todaysTasks),
                    const SizedBox(height: 16),
                    ActiveHabitsCard(habits: dashboard.activeHabits),
                    const SizedBox(height: 16),
                    GoalProgressCard(goals: dashboard.goals),
                    const SizedBox(height: 16),
                    const _ReflectionBentoCard(),
                  ],
                ),
        ),
      ),
    );

    if (badgeState.newlyUnlocked != null) {
      screen = Stack(
        children: [
          screen,
          _BadgeCelebrationOverlay(
            badge: badgeState.newlyUnlocked!,
            onDismiss: () => ref.read(badgeProvider.notifier).clearCelebration(),
          ),
        ],
      );
    }

    if (_showAssistant) {
      screen = Stack(
        children: [
          screen,
          _VoiceAssistantPanel(
            isListening: _isListening,
            statusMessage: _statusMessage,
            transcriptText: _transcriptText,
            errorText: _errorText,
            commandHistory: _commandHistory,
            onClose: () {
              setState(() {
                _showAssistant = false;
              });
              _stopSpeech();
            },
            onToggleListening: () {
              if (_isListening) {
                _stopSpeech();
              } else {
                _startSpeech();
              }
            },
          ),
        ],
      );
    }

    return screen;
  }
}

class HeroFocusCard extends StatelessWidget {
  const HeroFocusCard({required this.controller, super.key});

  final DashboardState controller;

  @override
  Widget build(BuildContext context) {
    final taskTarget =
        controller.pendingTaskCount + controller.completedTaskCount;
    final completion = taskTarget == 0
        ? 0.0
        : controller.completedTaskCount / taskTarget.clamp(1, 999);

    return DayForgeCard(
      color: focusFlowBlue,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DayForgeBadge(
                'Today focus',
                color: Color(0x2BFFFFFF),
                textColor: Colors.white,
              ),
              const Spacer(),
              const Icon(Icons.bolt, color: Colors.white),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            controller.todaysTasks.isEmpty
                ? 'Build a calm, useful day'
                : controller.todaysTasks.first.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks, habits, and goals are ready in one flow.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: completion,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetrics extends StatelessWidget {
  const DashboardMetrics({required this.controller, super.key});

  final DashboardState controller;

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
              value:
                  '${controller.completedHabitCount}/${controller.habits.length}',
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
    return DayForgeCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(icon: icon),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.dayforgeText,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: context.dayforgeMuted),
            ),
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
      title: "Today's Plan",
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
      title: 'Upcoming Habits',
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
      title: 'Progress Flow',
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: goal.progress / 100,
                    ),
                  ),
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
    return DayForgeCard(
      child: Padding(
        padding: EdgeInsets.zero,
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
                TextButton(onPressed: onAction, child: Text(actionLabel)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Focus Timer Card
// ─────────────────────────────────────────────────────────────────────────────

class _FocusTimerCard extends ConsumerWidget {
  const _FocusTimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(focusTimerProvider);
    final timerNotifier = ref.read(focusTimerProvider.notifier);
    final dashboard = ref.watch(dashboardControllerProvider);
    final theme = Theme.of(context);

    final associatedTaskId =
        dashboard.todaysTasks.isNotEmpty ? dashboard.todaysTasks.first.id : null;

    final isIdle = !timerState.isRunning &&
        !timerState.isBreak &&
        timerState.timeLeft == kWorkDuration;

    if (isIdle) {
      return DayForgeCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.timer_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Focus Session',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '25-minute Pomodoro timer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => timerNotifier.start(taskId: associatedTaskId),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalDuration = timerState.isBreak ? kBreakDuration : kWorkDuration;
    final progress = totalDuration > 0
        ? 1.0 - (timerState.timeLeft / totalDuration)
        : 0.0;

    final minutes = timerState.timeLeft ~/ 60;
    final seconds = timerState.timeLeft % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DayForgeBadge(
                timerState.isBreak ? 'Break Timer' : 'Focus Timer',
                color: timerState.isBreak
                    ? Colors.green.withOpacity(0.12)
                    : theme.colorScheme.primary.withOpacity(0.12),
                textColor: timerState.isBreak ? Colors.green : theme.colorScheme.primary,
              ),
              const Spacer(),
              if (timerState.totalCompleted > 0)
                Text(
                  'Sessions: ${timerState.totalCompleted}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProgressRing(
                value: progress,
                label: timerState.isBreak ? 'Break' : 'Focus',
                centerText: timeStr,
                size: 96,
                color: timerState.isBreak ? Colors.green : theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timerState.isBreak
                          ? 'Time to Relax!'
                          : (timerState.isRunning ? 'Keep Focusing!' : 'Start a Session'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timerState.isBreak
                          ? 'Take a breather to stay productive.'
                          : (dashboard.todaysTasks.isNotEmpty
                              ? 'Work on: ${dashboard.todaysTasks.first.title}'
                              : 'Linked to your top priority task.'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            if (timerState.isRunning) {
                              timerNotifier.pause();
                            } else {
                              timerNotifier.start(taskId: associatedTaskId);
                            }
                          },
                          icon: Icon(
                            timerState.isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: timerState.isBreak
                                ? Colors.green.withOpacity(0.12)
                                : theme.colorScheme.primary.withOpacity(0.12),
                            foregroundColor: timerState.isBreak ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () => timerNotifier.reset(),
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () => timerNotifier.skip(),
                          icon: const Icon(Icons.skip_next),
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reflection Bento Card
// ─────────────────────────────────────────────────────────────────────────────

const _moods = [
  (value: 1, emoji: '😢', label: 'Sad'),
  (value: 2, emoji: '😕', label: 'Meh'),
  (value: 3, emoji: '😐', label: 'Okay'),
  (value: 4, emoji: '🙂', label: 'Good'),
  (value: 5, emoji: '🤩', label: 'Awesome'),
];

class _ReflectionBentoCard extends StatefulWidget {
  const _ReflectionBentoCard();

  @override
  State<_ReflectionBentoCard> createState() => _ReflectionBentoCardState();
}

class _ReflectionBentoCardState extends State<_ReflectionBentoCard> {
  int _selectedMood = 4;
  final _noteController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(reflectionProvider); // trigger rebuild on save
        final todayReflection = ref.watch(reflectionProvider.notifier).todayReflection;

        if (todayReflection != null && !_isEditing) {
          final moodItem = _moods.firstWhere((m) => m.value == todayReflection.mood);
          return DayForgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DayForgeBadge(
                      'Daily Reflection',
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      textColor: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Edit Reflection',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        setState(() {
                          _selectedMood = todayReflection.mood;
                          _noteController.text = todayReflection.note;
                          _isEditing = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      moodItem.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feeling ${moodItem.label}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Today\'s Mood Check-in',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (todayReflection.note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      todayReflection.note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return DayForgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DayForgeBadge(
                    'Mood & Reflection',
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    textColor: theme.colorScheme.primary,
                  ),
                  if (_isEditing) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'How are you feeling today?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.map((m) {
                  final isSelected = _selectedMood == m.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = m.value;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        m.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 32 : 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind today? Write a reflection...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref.read(reflectionProvider.notifier).saveReflection(
                    mood: _selectedMood,
                    note: _noteController.text.trim(),
                  );
                  setState(() {
                    _noteController.clear();
                    _isEditing = false;
                  });
                },
                child: const Text('Save Entry'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Celebration Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeCelebrationOverlay extends StatelessWidget {
  const _BadgeCelebrationOverlay({
    required this.badge,
    required this.onDismiss,
  });

  final BadgeItem badge;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black.withOpacity(0.7),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: DayForgeCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.color,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: badge.color.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  badge.icon,
                  size: 40,
                  color: badge.color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Achievement Unlocked!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDismiss,
                  child: const Text('Claim Reward'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Microphone Icon
// ─────────────────────────────────────────────────────────────────────────────

class PulsingMic extends StatefulWidget {
  const PulsingMic({required this.isListening, super.key});
  final bool isListening;

  @override
  State<PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<PulsingMic> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.2);
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (widget.isListening ? Colors.red : theme.colorScheme.primary).withOpacity(0.15),
            border: Border.all(
              color: widget.isListening ? Colors.red : theme.colorScheme.primary,
              width: 2,
            ),
            boxShadow: widget.isListening
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12 * scale,
                      spreadRadius: 2 * scale,
                    )
                  ]
                : null,
          ),
          child: Icon(
            widget.isListening ? Icons.mic : Icons.mic_off,
            color: widget.isListening ? Colors.red : theme.colorScheme.primary,
            size: 32,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice Assistant Panel
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceAssistantPanel extends StatelessWidget {
  const _VoiceAssistantPanel({
    required this.isListening,
    required this.statusMessage,
    required this.transcriptText,
    required this.errorText,
    required this.commandHistory,
    required this.onClose,
    required this.onToggleListening,
  });

  final bool isListening;
  final String statusMessage;
  final String transcriptText;
  final String errorText;
  final List<String> commandHistory;
  final VoidCallback onClose;
  final VoidCallback onToggleListening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xEC1E293B) : const Color(0xECF1F5F9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upgro Voice Assistant',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onToggleListening,
                      child: PulsingMic(isListening: isListening),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transcriptText.isEmpty
                                ? 'Speak a command...'
                                : '"$transcriptText"',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: transcriptText.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: statusMessage.startsWith('Added') ||
                                      statusMessage.startsWith('Completed') ||
                                      statusMessage.startsWith('Checked') ||
                                      statusMessage.startsWith('Updated') ||
                                      statusMessage.startsWith('Logged')
                                  ? Colors.green
                                  : (errorText.isNotEmpty
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurfaceVariant),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (errorText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              errorText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useRow = constraints.maxWidth >= 600;
                    final suggestions = Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supported Voice Commands:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('• "Add task [title]"', style: theme.textTheme.bodySmall),
                          Text('• "Complete task [title]"', style: theme.textTheme.bodySmall),
                          Text('• "Check in habit [title]"', style: theme.textTheme.bodySmall),
                          Text('• "Update goal [title] to [0-100] percent"', style: theme.textTheme.bodySmall),
                          Text('• "Log reflection mood [1-5] note [text]"', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    );

                    final history = Container(
                      height: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Actions Log:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: commandHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'No actions yet',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: commandHistory.length,
                                    itemBuilder: (context, idx) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Text(
                                          '✓ ${commandHistory[idx]}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.green,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );

                    if (useRow) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: suggestions),
                          const SizedBox(width: 16),
                          Expanded(child: history),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          suggestions,
                          const SizedBox(height: 12),
                          history,
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
