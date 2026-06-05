import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'biometric_service.dart';
import '../utils/logger.dart';

/// Сервис для генерации, хранения и обмена RSA ключами
class RSAKeyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _privateKeyPrefix = 'rsa_private_key_v2_';
  static const String _legacyPrivateKeyPrefix = 'rsa_private_key_';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Генерация RSA ключевой пары (2048 бит)
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair() {
    final random = Random.secure();

    // Генерируем seed для SecureRandom
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }

    final secureRandom = SecureRandom('Fortuna');
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          secureRandom,
        ),
      );

    final keyPair = keyGen.generateKeyPair();
    // Приводим типы к RSAPublicKey и RSAPrivateKey
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      keyPair.publicKey as RSAPublicKey,
      keyPair.privateKey as RSAPrivateKey,
    );
  }

  // Сохранение приватного ключа локально (в безопасном хранилище)
  static Future<void> savePrivateKey(RSAPrivateKey privateKey) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      appLogger.e('Cannot save private key: user not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      // Конвертируем приватный ключ в PEM формат
      final keyBytes = _encodeRSAPrivateKeyToPEM(privateKey);
      await _secureStorage.write(
        key: _privateKeyStorageKey(userId),
        value: keyBytes,
      );
      appLogger.i('Private key saved securely for user: $userId');
    } catch (e) {
      appLogger.e('Error saving private key', error: e);
      rethrow;
    }
  }

  // Загрузка приватного ключа из безопасного хранилища
  static Future<RSAPrivateKey?> loadPrivateKey() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      appLogger.w('Cannot load private key: user not authenticated');
      return null;
    }

    try {
      await _unlockPrivateKeyIfRequired();
      final keyString = await _readPrivateKeyString(userId);
      if (keyString == null) {
        appLogger.d('No private key found for user: $userId');
        return null;
      }

      final key = _decodeRSAPrivateKeyFromPEM(keyString);
      appLogger.d('Private key loaded successfully for user: $userId');
      return key;
    } catch (e) {
      appLogger.e('Error loading private key', error: e);
      return null;
    }
  }

  // Local private key storage helpers.
  static Future<String?> _readPrivateKeyString(String userId) async {
    final storageKey = _privateKeyStorageKey(userId);
    final keyString = await _secureStorage.read(key: storageKey);
    if (keyString != null) return keyString;

    final legacyStorageKey = '$_legacyPrivateKeyPrefix$userId';
    final legacyKeyString = await _secureStorage.read(key: legacyStorageKey);
    if (legacyKeyString == null) return null;

    await _secureStorage.write(key: storageKey, value: legacyKeyString);
    await _secureStorage.delete(key: legacyStorageKey);
    appLogger.i('Migrated RSA private key to scoped storage key');
    return legacyKeyString;
  }

  static String _privateKeyStorageKey(String userId) {
    final digest = sha256.convert(
      utf8.encode('darkkick:rsa_private_key:$userId'),
    );
    return '$_privateKeyPrefix$digest';
  }

  static Future<void> _unlockPrivateKeyIfRequired() async {
    final useBiometrics = await BiometricService.getUseBiometrics();
    if (!useBiometrics) return;

    final unlocked = await BiometricService.authenticate(
      reason: 'Unlock your Darkkick encryption key',
    );
    if (!unlocked) {
      throw Exception('Private key unlock failed');
    }
  }

  static Future<void> publishPublicKey(RSAPublicKey publicKey) async {
    final user = _auth.currentUser;
    final userId = user?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final publicKeyPEM = _encodeRSAPublicKeyToPEM(publicKey);

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final publicProfileRef = _firestore
          .collection('publicProfiles')
          .doc(userId);
      final userDoc = await userRef.get();
      final existingData = userDoc.data() ?? const <String, dynamic>{};
      final email = (existingData['email'] ?? user?.email ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final rawName = (existingData['name'] ?? user?.displayName ?? '')
          .toString()
          .trim();
      final fallbackName = email.isNotEmpty ? email.split('@').first : 'User';
      final name = rawName.isEmpty ? fallbackName : rawName;
      final now = FieldValue.serverTimestamp();
      final keyData = {'publicKey': publicKeyPEM, 'publicKeyUpdatedAt': now};
      final userData = userDoc.exists
          ? keyData
          : {
              'uid': userId,
              'email': email,
              'emailLower': email,
              'name': name,
              'nameLower': name.toLowerCase(),
              ...keyData,
            };
      final batch = _firestore.batch();
      // Пытаемся обновить, если документа нет - создаем
      batch.set(userRef, userData, SetOptions(merge: true));
      batch.set(publicProfileRef, {
        'uid': userId,
        'name': name,
        'nameLower': name.toLowerCase(),
        ...keyData,
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      // Если документа нет, создаем его
      appLogger.e('Error publishing public key', error: e);
      rethrow;
    }
    appLogger.i('Public key published to Firestore for user: $userId');
  }

  // Получение публичного ключа пользователя из Firestore
  static Future<RSAPublicKey?> getUserPublicKey(String userId) async {
    try {
      final doc = await _firestore
          .collection('publicProfiles')
          .doc(userId)
          .get();
      if (!doc.exists) return null;

      final publicKeyPEM = doc.data()?['publicKey'] as String?;
      if (publicKeyPEM == null) return null;

      return _decodeRSAPublicKeyFromPEM(publicKeyPEM);
    } catch (e) {
      appLogger.e('Error getting public key for user: $userId', error: e);
      return null;
    }
  }

  // Инициализация ключей при регистрации
  static Future<void> initializeKeys() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Проверяем, есть ли уже ключи
    final existingPrivateKey = await loadPrivateKey();
    if (existingPrivateKey != null) {
      appLogger.i('RSA keys already initialized for user: $userId');
      return;
    }

    // Генерируем новую пару ключей
    appLogger.d('Generating new RSA key pair for user: $userId');
    final keyPair = generateKeyPair();

    // Сохраняем приватный ключ локально
    await savePrivateKey(keyPair.privateKey);

    // Публикуем публичный ключ
    await publishPublicKey(keyPair.publicKey);

    appLogger.i('RSA keys initialized and saved for user: $userId');
  }

  // Кодирование приватного ключа в простой формат (JSON-like base64)
  static String _encodeRSAPrivateKeyToPEM(RSAPrivateKey key) {
    final keyData = {
      'n': key.n.toString(),
      'd': key.privateExponent!.toString(),
      'p': key.p!.toString(),
      'q': key.q!.toString(),
    };
    final jsonString = jsonEncode(keyData);
    final dataBase64 = base64Encode(utf8.encode(jsonString));
    return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
  }

  // Декодирование приватного ключа из PEM формата
  static RSAPrivateKey _decodeRSAPrivateKeyFromPEM(String pemString) {
    // Удаляем заголовки PEM
    final lines = pemString
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .trim();

    final keyBytes = base64Decode(lines);
    final jsonString = utf8.decode(keyBytes);
    final keyData = jsonDecode(jsonString) as Map<String, dynamic>;

    final modulus = BigInt.parse(keyData['n'] as String);
    final exponent = BigInt.parse(keyData['d'] as String);
    final p = BigInt.parse(keyData['p'] as String);
    final q = BigInt.parse(keyData['q'] as String);

    return RSAPrivateKey(modulus, exponent, p, q);
  }

  // Кодирование публичного ключа в простой формат
  static String _encodeRSAPublicKeyToPEM(RSAPublicKey key) {
    final keyData = {'n': key.n.toString(), 'e': key.exponent.toString()};
    final jsonString = jsonEncode(keyData);
    final dataBase64 = base64Encode(utf8.encode(jsonString));
    return '-----BEGIN RSA PUBLIC KEY-----\n$dataBase64\n-----END RSA PUBLIC KEY-----';
  }

  // Декодирование публичного ключа из PEM формата
  static RSAPublicKey _decodeRSAPublicKeyFromPEM(String pemString) {
    final lines = pemString
        .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
        .replaceAll('-----END RSA PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .trim();

    final keyBytes = base64Decode(lines);
    final jsonString = utf8.decode(keyBytes);
    final keyData = jsonDecode(jsonString) as Map<String, dynamic>;

    final modulus = BigInt.parse(keyData['n'] as String);
    final exponent = BigInt.parse(keyData['e'] as String);

    return RSAPublicKey(modulus, exponent);
  }
}
