import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для генерации, хранения и обмена RSA ключами
class RSAKeyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        secureRandom,
      ));
    
    return keyGen.generateKeyPair();
  }

  // Сохранение приватного ключа локально (в SharedPreferences)
  static Future<void> savePrivateKey(RSAPrivateKey privateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Конвертируем приватный ключ в PEM формат
    final keyBytes = _encodeRSAPrivateKeyToPEM(privateKey);
    await prefs.setString('rsa_private_key_$userId', keyBytes);
    print('✅ Private key saved locally');
  }

  // Загрузка приватного ключа из локального хранилища
  static Future<RSAPrivateKey?> loadPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final keyString = prefs.getString('rsa_private_key_$userId');
    if (keyString == null) return null;

    try {
      return _decodeRSAPrivateKeyFromPEM(keyString);
    } catch (e) {
      print('❌ Error loading private key: $e');
      return null;
    }
  }

  // Публикация публичного ключа в Firestore
  static Future<void> publishPublicKey(RSAPublicKey publicKey) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final publicKeyPEM = _encodeRSAPublicKeyToPEM(publicKey);
    
    try {
      // Пытаемся обновить, если документа нет - создаем
      await _firestore.collection('users').doc(userId).update({
        'publicKey': publicKeyPEM,
        'publicKeyUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Если документа нет, создаем его
      await _firestore.collection('users').doc(userId).set({
        'publicKey': publicKeyPEM,
        'publicKeyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    print('✅ Public key published to Firestore');
  }

  // Получение публичного ключа пользователя из Firestore
  static Future<RSAPublicKey?> getUserPublicKey(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final publicKeyPEM = doc.data()?['publicKey'] as String?;
      if (publicKeyPEM == null) return null;

      return _decodeRSAPublicKeyFromPEM(publicKeyPEM);
    } catch (e) {
      print('❌ Error getting public key: $e');
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
      print('✅ Keys already initialized');
      return;
    }

    // Генерируем новую пару ключей
    final keyPair = generateKeyPair();
    
    // Сохраняем приватный ключ локально
    await savePrivateKey(keyPair.privateKey);
    
    // Публикуем публичный ключ
    await publishPublicKey(keyPair.publicKey);
    
    print('✅ RSA keys initialized and saved');
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
    final keyData = {
      'n': key.n.toString(),
      'e': key.exponent.toString(),
    };
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

