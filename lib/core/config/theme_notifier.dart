import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final isDarkMode = box.get(AppConstants.keyThemeMode);
      if (isDarkMode == null) {
        state = ThemeMode.system;
      } else {
        state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(AppConstants.hiveSettingsBox);
    if (mode == ThemeMode.system) {
      await box.delete(AppConstants.keyThemeMode);
    } else {
      await box.put(AppConstants.keyThemeMode, mode == ThemeMode.dark);
    }
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
