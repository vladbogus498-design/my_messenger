import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeData {
  final String key;
  final ThemeData themeData;
  const AppThemeData({required this.key, required this.themeData});
}

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'app_theme_key';

  final Map<String, AppThemeData> _themes = {
    'dark': AppThemeData(
      key: 'dark',
      themeData: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.deepPurple,
              secondary: Colors.deepPurpleAccent,
            ),
        scaffoldBackgroundColor: Colors.black,
      ),
    ),
    'amoled': AppThemeData(
      key: 'amoled',
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
      ),
    ),
    'light': AppThemeData(
      key: 'light',
      themeData: ThemeData.light().copyWith(
        colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
      ),
    ),
    'blueGradient': AppThemeData(
      key: 'blueGradient',
      themeData: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.blueAccent,
              secondary: Colors.lightBlueAccent,
            ),
      ),
    ),
    'purpleDeep': AppThemeData(
      key: 'purpleDeep',
      themeData: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.deepPurple,
              secondary: Colors.purpleAccent,
            ),
      ),
    ),
    'custom': AppThemeData(
      key: 'custom',
      themeData: ThemeData.dark(),
    ),
  };

  String _currentKey = 'dark';
  ThemeData get theme => _themes[_currentKey]?.themeData ?? ThemeData.dark();
  String get currentKey => _currentKey;
  List<String> get availableKeys => _themes.keys.toList();

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

  // Allow custom color overrides for 'custom'
  Future<void> setCustomColors(
      {required Color primary,
      required Color secondary,
      Color? scaffoldBg}) async {
    final base = ThemeData.dark();
    _themes['custom'] = AppThemeData(
      key: 'custom',
      themeData: base.copyWith(
        colorScheme:
            base.colorScheme.copyWith(primary: primary, secondary: secondary),
        scaffoldBackgroundColor: scaffoldBg ?? base.scaffoldBackgroundColor,
      ),
    );
    await setTheme('custom');
  }
}
