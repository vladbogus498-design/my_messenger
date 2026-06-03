import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../utils/input_validator.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';

class StorageService {
  static const String _cloudName = 'do4bvuj43';
  static const String _uploadPreset = 'darkkick_uploads';
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Uri get _uploadUri =>
      Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload');

  static Future<String> uploadChatImage(
    File imageFile,
    String chatId, {
    required String messageId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      if (!AppRateLimiters.uploadLimiter.tryRequest('upload_file_$userId')) {
        throw Exception('Превышен лимит загрузки файлов. Попробуй позже.');
      }

      final fileSize = await imageFile.length();
      final sizeError = InputValidator.validateFileSize(
        fileSize,
        isImage: true,
      );
      if (sizeError != null) throw Exception(sizeError);

      if (!InputValidator.isValidChatId(chatId)) {
        throw Exception('Invalid chatId');
      }

      if (messageId.contains('/')) {
        throw Exception('Invalid messageId');
      }

      return _uploadUnsignedImage(
        imageFile,
        folder: 'darkkick/chats/$chatId/images',
        publicId: messageId,
      );
    } catch (e) {
      appLogger.e(
        'Error uploading chat image to Cloudinary: $chatId',
        error: e,
      );
      rethrow;
    }
  }

  static Future<String> uploadUserAvatar(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      if (!AppRateLimiters.uploadLimiter.tryRequest('upload_avatar_$userId')) {
        throw Exception('Превышен лимит загрузки файлов. Попробуй позже.');
      }

      final fileSize = await imageFile.length();
      final sizeError = InputValidator.validateFileSize(
        fileSize,
        isImage: true,
      );
      if (sizeError != null) throw Exception(sizeError);

      return _uploadUnsignedImage(
        imageFile,
        folder: 'darkkick/avatars',
        publicId: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      appLogger.e('Error uploading avatar to Cloudinary: $userId', error: e);
      rethrow;
    }
  }

  static Future<void> deleteUserAvatar() async {
    // Unsigned Cloudinary uploads cannot delete assets safely from the client.
    // Deleting requires a signed backend/API secret, which must not be in APK.
    appLogger.w(
      'Cloudinary unsigned upload does not support client-side delete',
    );
  }

  static Future<String> _uploadUnsignedImage(
    File imageFile, {
    required String folder,
    required String publicId,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response does not contain secure_url');
    }

    return secureUrl;
  }
}
