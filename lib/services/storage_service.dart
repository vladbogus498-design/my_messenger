import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import '../utils/input_validator.dart';
import '../utils/rate_limiter.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Загрузка изображения чата
  static Future<String> uploadChatImage(File imageFile, String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Rate limiting: проверка лимита на загрузку файлов
      if (!AppRateLimiters.uploadLimiter.tryRequest('upload_file_$userId')) {
        throw Exception('Превышен лимит загрузки файлов. Попробуйте позже.');
      }

      // Валидация размера файла
      final fileSize = await imageFile.length();
      final sizeError = InputValidator.validateFileSize(fileSize, isImage: true);
      if (sizeError != null) {
        throw Exception(sizeError);
      }

      // Валидация chatId
      if (!InputValidator.isValidChatId(chatId)) {
        throw Exception('Invalid chatId');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_$chatId/${userId}_$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      appLogger.e('Error uploading chat image for chatId: $chatId', error: e);
      rethrow;
    }
  }

  // Загрузка аватара пользователя
  static Future<String> uploadUserAvatar(File imageFile) async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

    try {
      // Rate limiting: проверка лимита на загрузку файлов
      if (!AppRateLimiters.uploadLimiter.tryRequest('upload_avatar_$userId')) {
        throw Exception('Превышен лимит загрузки файлов. Попробуйте позже.');
      }

      // Валидация размера файла
      final fileSize = await imageFile.length();
      final sizeError = InputValidator.validateFileSize(fileSize, isImage: true);
      if (sizeError != null) {
        throw Exception(sizeError);
      }

      final fileName = 'avatars/$userId.jpg';
      final ref = _storage.ref().child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      appLogger.e('Error uploading avatar for userId: $userId', error: e);
      rethrow;
    }
  }

  // Удаление аватара
  static Future<void> deleteUserAvatar() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

    try {
      final fileName = 'avatars/$userId.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.delete();
    } catch (e) {
      appLogger.e('Error deleting avatar for userId: $userId', error: e);
    }
  }
}
