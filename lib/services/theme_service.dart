import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeData get lightTheme => AppTheme.light();
  ThemeData get darkTheme => AppTheme.dark();
  ThemeData get theme =>
      _themeMode == ThemeMode.light ? lightTheme : darkTheme;
  ThemeMode get themeMode => _themeMode;
  bool get isSystem => _themeMode == ThemeMode.system;

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
