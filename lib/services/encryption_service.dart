import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

/// Сервис для шифрования и дешифрования сообщений
class EncryptionService {
  // Генерация ключа на основе пароля пользователя
  static encrypt.Key generateKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Генерация IV (Initialization Vector)
  static encrypt.IV generateIV() {
    return encrypt.IV.fromSecureRandom(16);
  }

  /// Шифрование текста
  static String encryptText(String plainText, String password) {
    try {
      final key = generateKey(password);
      final iv = generateIV();
      final encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Возвращаем IV + зашифрованный текст (разделенные :)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('❌ Encryption error: $e');
      return plainText; // В случае ошибки возвращаем оригинальный текст
    }
  }

  /// Дешифрование текста
  static String decryptText(String encryptedText, String password) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        return encryptedText; // Если формат неправильный, возвращаем как есть
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final key = generateKey(password);
      final encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      print('❌ Decryption error: $e');
      return encryptedText; // В случае ошибки возвращаем зашифрованный текст
    }
  }

  /// Хеширование пароля для хранения
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Проверка пароля
  static bool verifyPassword(String password, String hashedPassword) {
    final hash = hashPassword(password);
    return hash == hashedPassword;
  }

  /// Генерация случайного безопасного пароля для чата
  static String generateSecurePassword({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    return String.fromCharCodes(List.generate(
        length, (index) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
