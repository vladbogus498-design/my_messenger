import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Проверяет доступность биометрии на устройстве
  static Future<bool> canAuthenticate() async {
    try {
      final isAvailable = await _auth.isDeviceSupported();
      if (!isAvailable) return false;

      final canCheck = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();

      return canCheck && availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Biometric check error: $e');
      return false;
    }
  }

  /// Выполняет аутентификацию через биометрию
  /// Возвращает true при успехе, false при отмене или ошибке
  static Future<bool> authenticate({String? reason}) async {
    try {
      // Проверяем доступность перед попыткой аутентификации
      final canAuth = await canAuthenticate();
      if (!canAuth) {
        return false;
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();

      // Определяем тип биометрии для сообщения
      String biometricType = 'fingerprint';
      if (availableBiometrics.contains(BiometricType.face)) {
        biometricType = 'face';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricType = 'iris';
      }

      final defaultReason = reason ??
          (biometricType == 'face'
              ? 'Используйте Face ID для разблокировки DarkKick'
              : biometricType == 'iris'
                  ? 'Используйте сканер радужки для разблокировки DarkKick'
                  : 'Приложите палец для разблокировки DarkKick');

      // Используем новый API с AuthenticationOptions (поддерживается с версии 2.0.0+)
      // Если версия ниже, будет использован старый API
      final result = await _auth.authenticate(
        localizedReason: defaultReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return result;
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  /// Получает список доступных типов биометрии
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('Get biometrics error: $e');
      return [];
    }
  }

  /// Получает название типа биометрии для отображения
  static Future<String> getBiometricTypeName() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Сканер радужки';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Отпечаток пальца';
      }

      // Если есть любой другой тип биометрии
      if (availableBiometrics.isNotEmpty) {
        return 'Биометрия';
      }

      return 'Биометрическая аутентификация';
    } catch (e) {
      return 'Биометрия';
    }
  }
}
