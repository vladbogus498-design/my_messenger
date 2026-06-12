import 'package:file_selector/file_selector.dart';

import '../models/selected_media.dart';
import '../utils/logger.dart';
import 'chat_service.dart';
import 'storage_service.dart';

class WindowsMessagingAdapter {
  const WindowsMessagingAdapter._();

  static const _imageTypeGroup = XTypeGroup(
    label: 'Images',
    extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    mimeTypes: <String>[
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/bmp',
    ],
  );

  static Future<SelectedMedia?> pickImage() async {
    try {
      final file = await openFile(acceptedTypeGroups: const [_imageTypeGroup]);
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected image is empty');
      }

      return SelectedMedia(bytes: bytes, name: file.name, path: file.path);
    } catch (error) {
      appLogger.e('Windows image picker failed', error: error);
      rethrow;
    }
  }

  static Future<void> sendText({
    required String chatId,
    required String text,
    String? replyToId,
    String? replyToText,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await ChatService.sendMessage(
      chatId: chatId,
      text: trimmed,
      type: 'text',
      replyToId: replyToId,
      replyToText: replyToText,
    );
  }

  static Future<void> sendImage({
    required String chatId,
    required SelectedMedia image,
    String? replyToId,
    String? replyToText,
  }) async {
    if (image.isEmpty) {
      throw Exception('Selected image is empty');
    }

    await ChatService.setSendingPhotoStatus(chatId, true);
    try {
      final messageId = ChatService.createMessageId(chatId);
      final imageUrl = await StorageService.uploadChatImage(
        image,
        chatId,
        messageId: messageId,
      );

      await ChatService.sendMessage(
        chatId: chatId,
        text: '',
        type: 'image',
        imageUrl: imageUrl,
        messageId: messageId,
        replyToId: replyToId,
        replyToText: replyToText,
        encrypt: false,
      );
    } finally {
      await ChatService.setSendingPhotoStatus(chatId, false);
    }
  }

  static Future<void> sendSticker({
    required String chatId,
    required String stickerId,
  }) async {
    final trimmed = stickerId.trim();
    if (trimmed.isEmpty) {
      throw Exception('Sticker id is empty');
    }

    await ChatService.sendMessage(
      chatId: chatId,
      text: '',
      type: 'sticker',
      stickerId: trimmed,
    );
  }
}
