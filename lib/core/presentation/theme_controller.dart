import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeStorageKey = 'focusflow_theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restoreTheme();
    return ThemeMode.dark;
  }

  Future<void> _restoreTheme() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedMode = preferences.getString(_themeStorageKey);
      if (storedMode != null) {
        final mode = ThemeMode.values.firstWhere(
          (e) => e.toString() == storedMode,
          orElse: () => ThemeMode.dark,
        );
        state = mode;
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeStorageKey, mode.toString());
    } catch (_) {
      // Ignore errors
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

