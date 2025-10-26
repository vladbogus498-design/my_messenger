import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ru';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  String get loginButtonText => _currentLanguage == 'ru' ? 'ВОЙТИ' : 'LOGIN';
  String get registerButtonText =>
      _currentLanguage == 'ru' ? 'СОЗДАТЬ АККАУНТ' : 'CREATE ACCOUNT';
  String get loginTabText => _currentLanguage == 'ru' ? 'Вход' : 'Login';
  String get registerTabText =>
      _currentLanguage == 'ru' ? 'Регистрация' : 'Register';
  String get emailLabel => 'Email';
  String get passwordLabel => _currentLanguage == 'ru' ? 'Пароль' : 'Password';
  String get appTitle => 'DARKKICK';
}
