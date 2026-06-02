import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  LanguageNotifier() : super(const LanguageState());

  void setLanguage(String language) {
    state = state.copyWith(currentLanguage: language);
    appLogger.d('Language changed to: $language');
  }

  String get loginButtonText => state.currentLanguage == 'ru' ? 'ВОЙТИ' : 'LOGIN';
  String get registerButtonText =>
      state.currentLanguage == 'ru' ? 'СОЗДАТЬ АККАУНТ' : 'CREATE ACCOUNT';
  String get loginTabText => state.currentLanguage == 'ru' ? 'Вход' : 'Login';
  String get registerTabText =>
      state.currentLanguage == 'ru' ? 'Регистрация' : 'Register';
  String get emailLabel => 'Email';
  String get passwordLabel => state.currentLanguage == 'ru' ? 'Пароль' : 'Password';
  String get appTitle => 'DARKKICK';
}

/// Провайдер для доступа к LanguageNotifier
final languageNotifierProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});
