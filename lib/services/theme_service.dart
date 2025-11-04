import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'app_theme_key';
  // Only two themes: light and dark, with high contrast colors
  final Map<String, ThemeData> _themes = {
    'dark': ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      cardColor: const Color(0xFF1E1E1E),
    ),
    'light': ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      cardColor: const Color(0xFFF2F2F2),
    ),
  };

  String _currentKey = 'dark';
  ThemeData get theme => _themes[_currentKey] ?? ThemeData.dark();
  String get currentKey => _currentKey;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentKey = prefs.getString(_prefKey) ?? 'dark';
    notifyListeners();
  }

  Future<void> setTheme(String key) async {
    if (!_themes.containsKey(key)) return;
    _currentKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
    notifyListeners();
  }
}
