import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import '../../../utils/logger.dart';

/// Secure key storage using platform-specific secure storage
/// iOS: Keychain
/// Android: Keystore (via Flutter Secure Storage)
abstract class SecureKeyStorage {
  Future<void> init();
  
  /// Save RSA private key (42KB+ encrypted)
  Future<void> savePrivateKey(String key);
  
  /// Load RSA private key with biometric auth
  Future<String?> loadPrivateKey({required bool requireBiometric});
  
  /// Save RSA public key
  Future<void> savePublicKey(String key);
  
  /// Load RSA public key (no auth required)
  Future<String?> loadPublicKey();
  
  /// Delete all keys
  Future<void> deleteAllKeys();
  
  /// Check if keys exist
  Future<bool> hasPrivateKey();
  Future<bool> hasPublicKey();
}

/// Implementation using Flutter Secure Storage + Local Auth
class PlatformSecureKeyStorage implements SecureKeyStorage {
  static const String _privateKeyKey = 'rsa_private_key_v2';
  static const String _publicKeyKey = 'rsa_public_key_v2';
  
  late final FlutterSecureStorage _storage;
  late final LocalAuthentication _localAuth;
  
  static const String _keyChunk = 'key_chunk_';
  static const int _chunkSize = 1024; // 1KB chunks for better storage

  @override
  Future<void> init() async {
    try {
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          keyProperties: KeyProperties(
            encryptionPadding: KeyProperties.encPaddingPKCS7,
            blockMode: KeyProperties.blockModeCBC,
          ),
          resetOnError: false,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_this_device_this_app_only,
        ),
      );
      
      _localAuth = LocalAuthentication();
      appLogger.i('Secure storage initialized');
    } catch (e) {
      appLogger.e('Error initializing secure storage', error: e);
      rethrow;
    }
  }

  /// Save private key in chunks (for large keys)
  @override
  Future<void> savePrivateKey(String key) async {
    try {
      await _authenticateUser('Сохранить приватный ключ');
      
      // Разбиваем на чанки и сохраняем
      final chunks = <String>[];
      for (int i = 0; i < key.length; i += _chunkSize) {
        chunks.add(key.substring(
          i,
          (i + _chunkSize).clamp(0, key.length),
        ));
      }
      
      // Сохраняем количество чанков
      await _storage.write(
        key: '${_privateKeyKey}_count',
        value: chunks.length.toString(),
      );
      
      // Сохраняем каждый чанк
      for (int i = 0; i < chunks.length; i++) {
        await _storage.write(
          key: '$_keyChunk$_privateKeyKey$i',
          value: chunks[i],
        );
      }
      
      appLogger.i('Private key saved securely in ${chunks.length} chunks');
    } catch (e) {
      appLogger.e('Error saving private key', error: e);
      rethrow;
    }
  }

  /// Load private key with biometric authentication
  @override
  Future<String?> loadPrivateKey({required bool requireBiometric}) async {
    try {
      if (requireBiometric) {
        final authenticated = await _authenticateUser('Доступ к ключу для расшифровки');
        if (!authenticated) {
          appLogger.w('Biometric authentication failed for private key');
          return null;
        }
      }
      
      // Получаем количество чанков
      final countStr = await _storage.read(key: '${_privateKeyKey}_count');
      if (countStr == null) {
        appLogger.w('Private key not found');
        return null;
      }
      
      final count = int.parse(countStr);
      final chunks = <String>[];
      
      // Загружаем каждый чанк
      for (int i = 0; i < count; i++) {
        final chunk = await _storage.read(key: '$_keyChunk$_privateKeyKey$i');
        if (chunk != null) {
          chunks.add(chunk);
        }
      }
      
      if (chunks.length != count) {
        throw Exception('Invalid private key chunks: ${chunks.length}/$count');
      }
      
      final key = chunks.join();
      appLogger.i('Private key loaded from secure storage');
      return key;
    } catch (e) {
      appLogger.e('Error loading private key', error: e);
      return null;
    }
  }

  /// Save public key (no auth required)
  @override
  Future<void> savePublicKey(String key) async {
    try {
      // Public key может быть большим, но меньше private key
      // Разбиваем на чанки для безопасности
      final chunks = <String>[];
      for (int i = 0; i < key.length; i += _chunkSize) {
        chunks.add(key.substring(
          i,
          (i + _chunkSize).clamp(0, key.length),
        ));
      }
      
      await _storage.write(
        key: '${_publicKeyKey}_count',
        value: chunks.length.toString(),
      );
      
      for (int i = 0; i < chunks.length; i++) {
        await _storage.write(
          key: '$_keyChunk$_publicKeyKey$i',
          value: chunks[i],
        );
      }
      
      appLogger.i('Public key saved in ${chunks.length} chunks');
    } catch (e) {
      appLogger.e('Error saving public key', error: e);
      rethrow;
    }
  }

  /// Load public key (no auth required)
  @override
  Future<String?> loadPublicKey() async {
    try {
      final countStr = await _storage.read(key: '${_publicKeyKey}_count');
      if (countStr == null) {
        appLogger.w('Public key not found');
        return null;
      }
      
      final count = int.parse(countStr);
      final chunks = <String>[];
      
      for (int i = 0; i < count; i++) {
        final chunk = await _storage.read(key: '$_keyChunk$_publicKeyKey$i');
        if (chunk != null) {
          chunks.add(chunk);
        }
      }
      
      if (chunks.length != count) {
        throw Exception('Invalid public key chunks');
      }
      
      return chunks.join();
    } catch (e) {
      appLogger.e('Error loading public key', error: e);
      return null;
    }
  }

  @override
  Future<void> deleteAllKeys() async {
    try {
      // Удаляем private key chunks
      final privateCount = await _storage.read(key: '${_privateKeyKey}_count');
      if (privateCount != null) {
        final count = int.parse(privateCount);
        for (int i = 0; i < count; i++) {
          await _storage.delete(key: '$_keyChunk$_privateKeyKey$i');
        }
        await _storage.delete(key: '${_privateKeyKey}_count');
      }
      
      // Удаляем public key chunks
      final publicCount = await _storage.read(key: '${_publicKeyKey}_count');
      if (publicCount != null) {
        final count = int.parse(publicCount);
        for (int i = 0; i < count; i++) {
          await _storage.delete(key: '$_keyChunk$_publicKeyKey$i');
        }
        await _storage.delete(key: '${_publicKeyKey}_count');
      }
      
      appLogger.i('All keys deleted from secure storage');
    } catch (e) {
      appLogger.e('Error deleting keys', error: e);
    }
  }

  @override
  Future<bool> hasPrivateKey() async {
    try {
      final value = await _storage.read(key: '${_privateKeyKey}_count');
      return value != null;
    } catch (e) {
      appLogger.e('Error checking private key', error: e);
      return false;
    }
  }

  @override
  Future<bool> hasPublicKey() async {
    try {
      final value = await _storage.read(key: '${_publicKeyKey}_count');
      return value != null;
    } catch (e) {
      appLogger.e('Error checking public key', error: e);
      return false;
    }
  }

  /// Authenticate user with biometric or PIN
  Future<bool> _authenticateUser(String reason) async {
    try {
      final isDeviceSupported = await _localAuth.canCheckBiometrics;
      final isDeviceSecure = await _localAuth.deviceSupportsBiometrics;
      
      if (!isDeviceSupported && !isDeviceSecure) {
        appLogger.w('Device does not support biometric');
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      appLogger.e('Authentication error', error: e);
      return false;
    }
  }
}
