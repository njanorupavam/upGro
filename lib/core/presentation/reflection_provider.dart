import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _reflectionsKey = 'focusflow_reflections';

class DailyReflection {
  final String dateKey; // yyyy-MM-dd
  final int mood;       // 1 to 5
  final String note;

  const DailyReflection({
    required this.dateKey,
    required this.mood,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'mood': mood,
        'note': note,
      };

  factory DailyReflection.fromJson(Map<String, dynamic> json) {
    return DailyReflection(
      dateKey: json['dateKey'] as String,
      mood: json['mood'] as int,
      note: json['note'] as String,
    );
  }
}

class ReflectionState {
  final Map<String, DailyReflection> reflections;
  final bool isLoading;

  const ReflectionState({
    this.reflections = const {},
    this.isLoading = false,
  });

  ReflectionState copyWith({
    Map<String, DailyReflection>? reflections,
    bool? isLoading,
  }) {
    return ReflectionState(
      reflections: reflections ?? this.reflections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReflectionNotifier extends Notifier<ReflectionState> {
  @override
  ReflectionState build() {
    _loadReflections();
    return const ReflectionState();
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadReflections() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_reflectionsKey);
      if (dataStr != null) {
        final decoded = json.decode(dataStr) as Map<String, dynamic>;
        final reflections = decoded.map((key, value) => MapEntry(
              key,
              DailyReflection.fromJson(value as Map<String, dynamic>),
            ));
        state = state.copyWith(reflections: reflections);
      }
    } catch (_) {} finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveReflection({required int mood, required String note}) async {
    final todayKey = _dateKey(DateTime.now());
    final updated = Map<String, DailyReflection>.from(state.reflections);
    updated[todayKey] = DailyReflection(
      dateKey: todayKey,
      mood: mood,
      note: note,
    );

    state = state.copyWith(reflections: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = updated.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_reflectionsKey, json.encode(encoded));
    } catch (_) {}
  }

  DailyReflection? get todayReflection {
    return state.reflections[_dateKey(DateTime.now())];
  }
}

final reflectionProvider =
    NotifierProvider<ReflectionNotifier, ReflectionState>(ReflectionNotifier.new);
