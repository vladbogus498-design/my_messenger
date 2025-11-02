import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';
import '../services/rsa_key_service.dart';

/// Сервис для End-to-End шифрования с использованием RSA + AES
class E2EEncryptionService {
  // Шифрование сообщения для конкретного получателя (RSA + AES)
  static Future<String> encryptMessage(String plainText, String recipientUserId) async {
    try {
      // Получаем публичный ключ получателя
      final recipientPublicKey = await RSAKeyService.getUserPublicKey(recipientUserId);
      if (recipientPublicKey == null) {
        throw Exception('Public key not found for user: $recipientUserId');
      }

      // Генерируем случайный AES ключ (256 бит)
      final aesKey = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);

      // Шифруем сообщение с помощью AES
      final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Шифруем AES ключ с помощью RSA публичного ключа получателя
      final encryptedAESKey = _encryptWithRSA(aesKey.bytes, recipientPublicKey);

      // Формат: RSA_encrypted_AES_key:IV:encrypted_message (все в base64)
      return '${base64Encode(encryptedAESKey)}:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('❌ E2E Encryption error: $e');
      // В случае ошибки возвращаем оригинальный текст (для обратной совместимости)
      return plainText;
    }
  }

  // Дешифрование сообщения с помощью приватного ключа
  static Future<String> decryptMessage(String encryptedMessage) async {
    try {
      // Получаем приватный ключ текущего пользователя
      final privateKey = await RSAKeyService.loadPrivateKey();
      if (privateKey == null) {
        throw Exception('Private key not found');
      }

      // Разбираем формат: RSA_encrypted_AES_key:IV:encrypted_message
      final parts = encryptedMessage.split(':');
      if (parts.length != 3) {
        // Если формат неправильный, возможно это незашифрованное сообщение
        return encryptedMessage;
      }

      final encryptedAESKey = base64Decode(parts[0]);
      final iv = encrypt.IV.fromBase64(parts[1]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[2]);

      // Дешифруем AES ключ с помощью RSA приватного ключа
      final aesKeyBytes = _decryptWithRSA(encryptedAESKey, privateKey);
      final aesKey = encrypt.Key(aesKeyBytes);

      // Дешифруем сообщение с помощью AES
      final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      print('❌ E2E Decryption error: $e');
      // В случае ошибки возвращаем зашифрованный текст
      return encryptedMessage;
    }
  }

  // Проверка, зашифровано ли сообщение
  static bool isEncrypted(String message) {
    // Проверяем формат: base64:base64:base64
    final parts = message.split(':');
    if (parts.length != 3) return false;
    
    try {
      // Проверяем, что все части валидный base64
      base64Decode(parts[0]);
      base64Decode(parts[1]);
      base64Decode(parts[2]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Шифрование данных с помощью RSA (публичный ключ)
  static Uint8List _encryptWithRSA(Uint8List data, RSAPublicKey publicKey) {
    final encrypter = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    // RSA может зашифровать только данные меньше размера ключа минус padding
    // Для 2048-битного ключа это примерно 245 байт
    // Разбиваем данные на чанки
    final chunkSize = 245;
    final output = <int>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final chunk = data.sublist(
        i,
        i + chunkSize > data.length ? data.length : i + chunkSize,
      );
      final encrypted = encrypter.process(chunk);
      output.addAll(encrypted);
    }

    return Uint8List.fromList(output);
  }

  // Дешифрование данных с помощью RSA (приватный ключ)
  static Uint8List _decryptWithRSA(Uint8List encryptedData, RSAPrivateKey privateKey) {
    final decrypter = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    // Размер зашифрованного чанка для 2048-битного ключа
    final chunkSize = 256;
    final output = <int>[];

    for (var i = 0; i < encryptedData.length; i += chunkSize) {
      final chunk = encryptedData.sublist(
        i,
        i + chunkSize > encryptedData.length ? encryptedData.length : i + chunkSize,
      );
      final decrypted = decrypter.process(chunk);
      output.addAll(decrypted);
    }

    return Uint8List.fromList(output);
  }

  // Шифрование сообщения для группового чата (шифруем для всех участников)
  static Future<Map<String, String>> encryptForMultipleRecipients(
    String plainText,
    List<String> recipientIds,
  ) async {
    final encryptedMessages = <String, String>{};

    for (final recipientId in recipientIds) {
      try {
        final encrypted = await encryptMessage(plainText, recipientId);
        encryptedMessages[recipientId] = encrypted;
      } catch (e) {
        print('❌ Error encrypting for $recipientId: $e');
      }
    }

    return encryptedMessages;
  }
}

