import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isAvailable = await _auth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (e) {
      print('Biometric check error: $e');
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Authenticate to access DarkKick',
      );
      return result;
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('Get biometrics error: $e');
      return [];
    }
  }
}
