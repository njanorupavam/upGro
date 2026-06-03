import 'dart:async';
import 'dart:js' as js;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayforge/features/tasks/presentation/tasks_controller.dart';
import 'package:dayforge/features/tasks/data/task_models.dart';
import 'package:dayforge/features/habits/presentation/habits_controller.dart';
import 'package:dayforge/features/habits/data/habit_models.dart';
import 'package:dayforge/features/goals/presentation/goals_controller.dart';
import 'package:dayforge/features/goals/data/goal_models.dart';
import 'package:dayforge/core/presentation/reflection_provider.dart';

class VoiceAssistantService {
  static dynamic _recognitionHandle;
  static bool _isActive = false;

  static bool get isSupported {
    return js.context.hasProperty('webkitSpeechRecognition') ||
        js.context.hasProperty('SpeechRecognition');
  }

  static bool get isActive => _isActive;

  static void startListening({
    required Function(String text) onTranscribed,
    required Function(String status) onStatusChanged,
    required Function(String error) onError,
  }) {
    if (!isSupported) {
      onError("Speech recognition not supported in this browser.");
      return;
    }

    _isActive = true;

    // Define JS wrappers
    final jsOnResult = js.allowInterop((String text) => onTranscribed(text));
    final jsOnStatus = js.allowInterop((String status) => onStatusChanged(status));
    final jsOnError = js.allowInterop((String error) => onError(error));

    if (!js.context.hasProperty('startSpeechRecognition')) {
      js.context.callMethod('eval', [
        """
        window.startSpeechRecognition = function(onResult, onStatus, onError) {
          var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
          var recognition = new SpeechRecognition();
          recognition.continuous = false;
          recognition.interimResults = false;
          recognition.lang = 'en-US';
          var active = true;

          recognition.onresult = function(event) {
            var last = event.results.length - 1;
            var text = event.results[last][0].transcript;
            onResult(text);
          };

          recognition.onstart = function() {
            onStatus("listening");
          };

          recognition.onend = function() {
            if (active) {
              try {
                recognition.start();
              } catch(e) {}
            } else {
              onStatus("stopped");
            }
          };

          recognition.onerror = function(event) {
            if (event.error !== 'no-speech') {
              onError(event.error);
            }
          };

          try {
            recognition.start();
          } catch(e) {
            onError(e.toString());
          }

          return {
            stop: function() {
              active = false;
              try {
                recognition.abort();
              } catch(e) {}
            }
          };
        };
        """
      ]);
    }

    try {
      _recognitionHandle = js.context.callMethod('startSpeechRecognition', [
        jsOnResult,
        jsOnStatus,
        jsOnError,
      ]);
    } catch (e) {
      onError(e.toString());
    }
  }

  static void stopListening() {
    _isActive = false;
    if (_recognitionHandle != null) {
      try {
        _recognitionHandle.callMethod('stop');
      } catch (_) {}
      _recognitionHandle = null;
    }
  }

  static void speak(String text) {
    try {
      if (js.context.hasProperty('speechSynthesis')) {
        if (!js.context.hasProperty('speakConfirmation')) {
          js.context.callMethod('eval', [
            """
            window.speakConfirmation = function(text) {
              var msg = new SpeechSynthesisUtterance(text);
              msg.rate = 1.0;
              msg.lang = 'en-US';
              window.speechSynthesis.speak(msg);
            };
            """
          ]);
        }
        js.context.callMethod('speakConfirmation', [text]);
      }
    } catch (_) {}
  }

  static Future<String> processCommand(WidgetRef ref, String speechText) async {
    final text = speechText.trim().toLowerCase();

    // 1. Add Task
    // Pattern: add task [title] / create task [title]
    final addTaskReg = RegExp(r'^(?:add|create)\s+task\s+(.+)$');
    if (addTaskReg.hasMatch(text)) {
      final title = addTaskReg.firstMatch(text)!.group(1)!.trim();
      final draft = TaskDraft(
        title: _capitalize(title),
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
      );
      final success = await ref.read(tasksControllerProvider.notifier).createTask(draft);
      if (success) {
        final reply = "Added task: $title";
        speak(reply);
        return reply;
      } else {
        return "Failed to create task.";
      }
    }

    // 2. Complete Task
    // Pattern: complete task [title] / done task [title] / finish task [title]
    final completeTaskReg = RegExp(r'^(?:complete|done|finish)\s+task\s+(.+)$');
    if (completeTaskReg.hasMatch(text)) {
      final title = completeTaskReg.firstMatch(text)!.group(1)!.trim();
      final tasksState = ref.read(tasksControllerProvider);
      final matchedTask = _findBestMatch(tasksState.tasks, (TaskItem t) => t.title, title);

      if (matchedTask != null) {
        final success = await ref.read(tasksControllerProvider.notifier).toggleComplete(matchedTask);
        if (success) {
          final reply = "Completed task: ${matchedTask.title}";
          speak(reply);
          return reply;
        } else {
          return "Failed to complete task.";
        }
      } else {
        return "Task '$title' not found.";
      }
    }

    // 3. Check in Habit
    // Pattern: check in habit [title] / complete habit [title] / do habit [title] / check habit [title]
    final checkHabitReg = RegExp(r'^(?:check in|complete|do|check)\s+habit\s+(.+)$');
    if (checkHabitReg.hasMatch(text)) {
      final title = checkHabitReg.firstMatch(text)!.group(1)!.trim();
      final habitsState = ref.read(habitsControllerProvider);
      final matchedHabit = _findBestMatch(habitsState.habits, (HabitItem h) => h.title, title);

      if (matchedHabit != null) {
        final success = await ref.read(habitsControllerProvider.notifier).checkIn(matchedHabit.id);
        if (success) {
          final reply = "Checked in habit: ${matchedHabit.title}";
          speak(reply);
          return reply;
        } else {
          return "Failed to check in habit.";
        }
      } else {
        return "Habit '$title' not found.";
      }
    }

    // 4. Update Goal Progress
    // Pattern: update goal [title] to [percent] percent / set progress of goal [title] to [percent] / set goal [title] to [percent]
    final updateGoalReg = RegExp(r'^(?:update|set)\s+goal\s+(.+?)\s+to\s+(\d+)(?:\s*percent|\s*%)?$');
    if (updateGoalReg.hasMatch(text)) {
      final match = updateGoalReg.firstMatch(text)!;
      final title = match.group(1)!.trim();
      final progressVal = int.tryParse(match.group(2)!) ?? 0;

      final goalsState = ref.read(goalsControllerProvider);
      final matchedGoal = _findBestMatch(goalsState.goals, (GoalItem g) => g.title, title);

      if (matchedGoal != null) {
        final draft = GoalDraft(
          title: matchedGoal.title,
          progress: progressVal.clamp(0, 100),
          description: matchedGoal.description,
          targetDate: matchedGoal.targetDate,
          motivationNote: matchedGoal.motivationNote,
        );
        final success = await ref.read(goalsControllerProvider.notifier).updateGoal(matchedGoal.id, draft);
        if (success) {
          final reply = "Updated goal ${matchedGoal.title} to $progressVal percent";
          speak(reply);
          return reply;
        } else {
          return "Failed to update goal.";
        }
      } else {
        return "Goal '$title' not found.";
      }
    }

    // 5. Add Reflection
    // Pattern: log reflection mood [1-5] note [text]
    final reflectionReg = RegExp(r'^(?:log|add)\s+reflection\s+mood\s+(\d)\s+(?:note\s+)?(.+)$');
    if (reflectionReg.hasMatch(text)) {
      final match = reflectionReg.firstMatch(text)!;
      final moodVal = int.tryParse(match.group(1)!) ?? 4;
      final noteVal = match.group(2)!.trim();

      await ref.read(reflectionProvider.notifier).saveReflection(
        mood: moodVal.clamp(1, 5),
        note: _capitalize(noteVal),
      );
      final reply = "Logged daily reflection with mood $moodVal";
      speak(reply);
      return reply;
    }

    return "Sorry, I couldn't understand that command. Try saying 'Add task read book' or 'Check in habit exercise'.";
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static T? _findBestMatch<T>(List<T> items, String Function(T) getTitle, String searchTitle) {
    final search = searchTitle.toLowerCase().trim();
    if (search.isEmpty) return null;

    // Exact case-insensitive match
    for (final item in items) {
      if (getTitle(item).toLowerCase().trim() == search) {
        return item;
      }
    }

    // Starts with search term
    for (final item in items) {
      if (getTitle(item).toLowerCase().trim().startsWith(search)) {
        return item;
      }
    }

    // Contains search term
    for (final item in items) {
      if (getTitle(item).toLowerCase().trim().contains(search)) {
        return item;
      }
    }

    return null;
  }
}
