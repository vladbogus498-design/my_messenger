import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с биометрической аутентификацией
/// Пока только структура, полная интеграция будет позже
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _useBiometricsKey = 'useBiometrics';

  /// Проверяет, доступна ли биометрическая аутентификация
  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Получает список доступных типов биометрии
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Аутентификация с помощью биометрии
  static Future<bool> authenticate({
    String reason = 'Пожалуйста, подтвердите вашу личность',
  }) async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        print('❌ Biometric authentication not available');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('❌ Error during biometric authentication: $e');
      return false;
    }
  }

  /// Сохраняет настройку использования биометрии
  static Future<void> setUseBiometrics(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useBiometricsKey, value);
    } catch (e) {
      print('❌ Error saving biometric preference: $e');
    }
  }

  /// Получает настройку использования биометрии
  static Future<bool> getUseBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useBiometricsKey) ?? false;
    } catch (e) {
      print('❌ Error getting biometric preference: $e');
      return false;
    }
  }
}
