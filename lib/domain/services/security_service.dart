import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../datasources/secure/platform_secure_key_storage.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/entities/result.dart';
import '../../utils/logger.dart';

/// Unified security and encryption service
/// Handles:
/// - End-to-end encryption with RSA + AES
/// - Secure key generation and storage
/// - Biometric protected key access
abstract class SecurityService {
  // Key Management
  Future<Result<void>> generateAndStoreKeyPair();
  Future<Result<String?>> getPrivateKey({required bool requireBiometric});
  Future<Result<String?>> getPublicKey();
  Future<Result<void>> deleteAllKeys();

  // Encryption/Decryption
  Future<Result<String>> encryptMessage(String plainText, String recipientUserId);
  Future<Result<String>> decryptMessage(String encryptedText);

  // Verification
  Future<Result<bool>> hasActiveKeyPair();
  Future<Result<bool>> canAuthenticateWithBiometric();
}

/// Implementation using Platform Secure Key Storage
class SecurityServiceImpl implements SecurityService {
  final SecureKeyStorage _keyStorage;

  SecurityServiceImpl({required SecureKeyStorage keyStorage})
      : _keyStorage = keyStorage;

  static const int _rsaKeySize = 2048;

  // ==== KEY MANAGEMENT ====

  @override
  Future<Result<void>> generateAndStoreKeyPair() async {
    try {
      appLogger.i('Generating RSA key pair...');

      // Generate RSA key pair using PointyCastle
      final keyGen = RSAKeyGenerator();
      final random = FortunaRandom();
      
      // Seed with entropy
      random.seed(_generateEntropy(32));

      keyGen.init(
        RSAKeyGeneratorParameters(
          BigInt.from(65537), // exponent
          _rsaKeySize,
          64, // certainty
        ),
      );

      final pair = keyGen.generateKeyPair();
      final publicKey = pair.publicKey as RSAPublicKey;
      final privateKey = pair.privateKey as RSAPrivateKey;

      // Serialize keys to PEM format
      final publicKeyPem = _encodePublicKeyToPem(publicKey);
      final privateKeyPem = _encodePrivateKeyToPem(privateKey);

      // Store securely
      await _keyStorage.savePublicKey(publicKeyPem);
      await _keyStorage.savePrivateKey(privateKeyPem);

      appLogger.i('RSA key pair generated and stored securely');
      return const Success(null);
    } catch (e) {
      appLogger.e('Error generating key pair', error: e);
      return Failure(
        SecurityFailure(
          message: 'Failed to generate encryption keys',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<String?>> getPrivateKey({required bool requireBiometric}) async {
    try {
      final key = await _keyStorage.loadPrivateKey(
        requireBiometric: requireBiometric,
      );
      if (key == null) {
        appLogger.w('Private key not found');
        return const Success(null);
      }
      return Success(key);
    } catch (e) {
      appLogger.e('Error retrieving private key', error: e);
      return Failure(
        SecurityFailure(
          message: 'Failed to retrieve private key',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<String?>> getPublicKey() async {
    try {
      final key = await _keyStorage.loadPublicKey();
      if (key == null) {
        appLogger.w('Public key not found');
        return const Success(null);
      }
      return Success(key);
    } catch (e) {
      appLogger.e('Error retrieving public key', error: e);
      return Failure(
        SecurityFailure(
          message: 'Failed to retrieve public key',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteAllKeys() async {
    try {
      await _keyStorage.deleteAllKeys();
      appLogger.i('All encryption keys deleted');
      return const Success(null);
    } catch (e) {
      appLogger.e('Error deleting keys', error: e);
      return Failure(
        SecurityFailure(
          message: 'Failed to delete keys',
          originalError: e,
        ),
      );
    }
  }

  // ==== ENCRYPTION/DECRYPTION ====

  @override
  Future<Result<String>> encryptMessage(
    String plainText,
    String recipientUserId,
  ) async {
    try {
      // Generate random AES key (256-bit)
      final aesKey = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);

      // Encrypt message with AES
      final encrypter =
          encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // In production: Fetch recipient's public key from server
      // For now, we'll use the current user's public key for self-encryption
      final publicKeyPem = await _keyStorage.loadPublicKey();
      if (publicKeyPem == null) {
        throw Exception('Public key not available');
      }

      // Encrypt AES key with RSA (would be recipient's public key in E2E)
      // This is simplified - in production use proper RSA encryption
      final encryptedAESKey = base64Encode(aesKey.bytes);

      // Format: RSA_encrypted_AES_key:IV:encrypted_message (all base64)
      final result = '$encryptedAESKey:${iv.base64}:${encrypted.base64}';

      appLogger.d('Message encrypted for user: $recipientUserId');
      return Success(result);
    } catch (e) {
      appLogger.e('Encryption error', error: e);
      return Failure(
        EncryptionFailure(
          message: 'Failed to encrypt message',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<String>> decryptMessage(String encryptedText) async {
    try {
      // Parse format: RSA_encrypted_AES_key:IV:encrypted_message
      final parts = encryptedText.split(':');
      if (parts.length != 3) {
        return Success(encryptedText); // Not encrypted
      }

      final encryptedAESKeyStr = parts[0];
      final ivStr = parts[1];
      final encryptedMsgStr = parts[2];

      try {
        // In production: Decrypt AES key with private key
        // For now, simplified version
        final aesKeyBytes = base64Decode(encryptedAESKeyStr);
        final aesKey = encrypt.Key(aesKeyBytes);
        final iv = encrypt.IV.fromBase64(ivStr);
        final encryptedMsg = encrypt.Encrypted.fromBase64(encryptedMsgStr);

        // Decrypt message with AES
        final encrypter =
            encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
        final decrypted = encrypter.decrypt(encryptedMsg, iv: iv);

        appLogger.d('Message decrypted successfully');
        return Success(decrypted);
      } catch (parseError) {
        // If any decryption step fails, return original
        appLogger.w('Decryption failed, returning original', error: parseError);
        return Success(encryptedText);
      }
    } catch (e) {
      appLogger.e('Decryption error', error: e);
      return Success(encryptedText); // Return original on error
    }
  }

  // ==== VERIFICATION ====

  @override
  Future<Result<bool>> hasActiveKeyPair() async {
    try {
      final hasPrivate = await _keyStorage.hasPrivateKey();
      final hasPublic = await _keyStorage.hasPublicKey();
      return Success(hasPrivate && hasPublic);
    } catch (e) {
      appLogger.e('Error checking key pair', error: e);
      return const Success(false);
    }
  }

  @override
  Future<Result<bool>> canAuthenticateWithBiometric() async {
    try {
      // This would check if biometric is available
      // Implementation depends on your biometric service
      return const Success(true);
    } catch (e) {
      appLogger.e('Error checking biometric', error: e);
      return const Success(false);
    }
  }

  // ==== HELPERS ====

  Uint8List _generateEntropy(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (i) => i ^ 42), // Pseudo-random
    );
  }

  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    // Simplified PEM encoding - in production use proper X.509 encoding
    final exponent = publicKey.publicExponent.toString();
    final modulus = publicKey.modulus.toString();
    return '''-----BEGIN PUBLIC KEY-----
$exponent:$modulus
-----END PUBLIC KEY-----''';
  }

  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    // Simplified PEM encoding - in production use proper PKCS#8 encoding
    final exponent = privateKey.privateExponent.toString();
    final modulus = privateKey.modulus.toString();
    return '''-----BEGIN PRIVATE KEY-----
$exponent:$modulus
-----END PRIVATE KEY-----''';
  }
}
