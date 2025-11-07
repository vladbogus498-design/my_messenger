import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;

  // Светлая тема
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardColor: const Color(0xFFF5F5F5),
    primaryColor: Colors.blue,
    useMaterial3: true,
  );

  // Тёмная тема
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.deepPurple,
      secondary: Colors.deepPurpleAccent,
      surface: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: const Color(0xFF1E1E1E),
    primaryColor: Colors.deepPurple,
    useMaterial3: true,
  );

  // Текущая тема (для обратной совместимости)
  ThemeData get theme => _themeMode == ThemeMode.light ? lightTheme : darkTheme;
  ThemeMode get themeMode => _themeMode;

  // Совместимость со старым API
  List<String> get availableKeys => const ['dark', 'light', 'system'];

  String get currentKey {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_prefKey) ?? ThemeMode.dark.index;
    _themeMode = ThemeMode.values[modeIndex];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, mode.index);
    notifyListeners();
  }

  Future<void> setTheme(String key) async {
    // Для обратной совместимости
    if (key == 'light') {
      await setThemeMode(ThemeMode.light);
    } else if (key == 'dark') {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
