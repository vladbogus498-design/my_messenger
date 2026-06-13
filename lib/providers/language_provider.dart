import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Состояние языка приложения
class LanguageState {
  final String currentLanguage;

  const LanguageState({this.currentLanguage = 'ru'});

  LanguageState copyWith({String? currentLanguage}) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }
}

/// Провайдер для управления языком приложения
class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier()
    : super(LanguageState(currentLanguage: _deviceLanguage())) {
    _loadLanguage();
  }

  static const String _prefKey = 'app_language';

  static String _deviceLanguage() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code == 'ru' || code == 'pl' || code == 'en') return code;
    return 'en';
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'ru' || saved == 'pl' || saved == 'en') {
        state = state.copyWith(currentLanguage: saved);
      }
      appLogger.d('Language loaded: ${state.currentLanguage}');
    } catch (e) {
      appLogger.e('Error loading language', error: e);
    }
  }

  Future<void> setLanguage(String language) async {
    final normalized =
        (language == 'ru' || language == 'pl' || language == 'en')
        ? language
        : 'en';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, normalized);
      state = state.copyWith(currentLanguage: normalized);
      appLogger.d('Language changed to: $normalized');
    } catch (e) {
      appLogger.e('Error saving language', error: e);
      rethrow;
    }
  }

  String get loginButtonText =>
      state.currentLanguage == 'ru' ? 'ВОЙТИ' : 'LOGIN';
  String get registerButtonText =>
      state.currentLanguage == 'ru' ? 'СОЗДАТЬ АККАУНТ' : 'CREATE ACCOUNT';
  String get loginTabText => state.currentLanguage == 'ru' ? 'Вход' : 'Login';
  String get registerTabText =>
      state.currentLanguage == 'ru' ? 'Регистрация' : 'Register';
  String get emailLabel => 'Email';
  String get passwordLabel =>
      state.currentLanguage == 'ru' ? 'Пароль' : 'Password';
  String get appTitle => 'DARKKICK';
}

/// Провайдер для доступа к LanguageNotifier
final languageNotifierProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
      return LanguageNotifier();
    });
