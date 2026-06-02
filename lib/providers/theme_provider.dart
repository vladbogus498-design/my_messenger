import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

/// Состояние темы приложения
class ThemeState {
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  ThemeState({
    this.themeMode = ThemeMode.dark,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  })  : lightTheme = lightTheme ?? AppTheme.light(),
        darkTheme = darkTheme ?? AppTheme.dark();

  ThemeData get theme =>
      themeMode == ThemeMode.light ? lightTheme : darkTheme;

  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// Провайдер для управления темой приложения
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState()) {
    _loadTheme();
  }

  static const String _prefKey = 'app_theme_mode';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefKey) ?? ThemeMode.dark.index;
      final mode = ThemeMode.values[modeIndex];
      state = state.copyWith(themeMode: mode);
      appLogger.d('Theme loaded: $mode');
    } catch (e) {
      appLogger.e('Error loading theme', error: e);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, mode.index);
      state = state.copyWith(themeMode: mode);
      appLogger.d('Theme changed to: $mode');
    } catch (e) {
      appLogger.e('Error saving theme', error: e);
    }
  }

  Future<void> setTheme(String key) async {
    // Для обратной совместимости
    ThemeMode mode;
    if (key == 'light') {
      mode = ThemeMode.light;
    } else if (key == 'dark') {
      mode = ThemeMode.dark;
    } else {
      mode = ThemeMode.system;
    }
    await setThemeMode(mode);
  }

  void toggleTheme() {
    final nextMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(nextMode);
  }

  List<String> get availableKeys => const ['dark', 'light', 'system'];

  String get currentKey {
    switch (state.themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Провайдер для доступа к ThemeNotifier
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Провайдер для получения текущей темы
final themeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeNotifierProvider);
  return themeState.theme;
});

/// Провайдер для получения светлой темы
final lightThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeNotifierProvider);
  return themeState.lightTheme;
});

/// Провайдер для получения тёмной темы
final darkThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeNotifierProvider);
  return themeState.darkTheme;
});

/// Провайдер для получения режима темы
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeNotifierProvider);
  return themeState.themeMode;
});

