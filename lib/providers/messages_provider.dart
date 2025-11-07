import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/e2e_encryption_service.dart';

/// Провайдер для получения сообщений чата
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final messages = <Message>[];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      var messageText = data['text'] ?? '';
      final isEncrypted = data['isEncrypted'] ?? false;

      // Дешифруем сообщение, если оно зашифровано
      if (isEncrypted && messageText.isNotEmpty) {
        try {
          messageText = await E2EEncryptionService.decryptMessage(messageText);
        } catch (e) {
          print('❌ Error decrypting message: $e');
        }
      }

      messages.add(Message(
        id: doc.id,
        chatId: chatId,
        senderId: data['senderId'] ?? '',
        text: messageText,
        type: data['type'] ?? 'text',
        imageUrl: data['imageUrl'],
        voiceAudioBase64: data['voiceAudioBase64'],
        voiceDuration: data['voiceDuration'],
        stickerId: data['stickerId'],
        isEncrypted: isEncrypted,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        replyToId: data['replyToId'],
        replyToText: data['replyToText'],
        isForwarded: data['isForwarded'] ?? false,
        originalSender: data['originalSender'],
        reactions: Map<String, String>.from(data['reactions'] ?? {}),
        isTyping: data['isTyping'] ?? false,
        status: data['status'] ?? 'sent',
      ));
    }
    return messages;
  });
});

/// Провайдер для управления отправкой сообщений с повторной попыткой
class MessageSenderNotifier extends StateNotifier<AsyncValue<void>> {
  MessageSenderNotifier() : super(const AsyncValue.data(null));

  /// Отправить сообщение с повторной попыткой при ошибке
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String type,
    String? imageUrl,
    String? voiceAudioBase64,
    int? voiceDuration,
    String? stickerId,
    String? replyToId,
    String? replyToText,
    bool isForwarded = false,
    String? originalSender,
    bool encrypt = false,
    List<String>? recipientIds,
    int maxRetries = 3,
  }) async {
    state = const AsyncValue.loading();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        var messageText = text;
        var isEncrypted = false;

        // Шифруем сообщение, если требуется
        if (encrypt && messageText.isNotEmpty && recipientIds != null && recipientIds.isNotEmpty) {
          try {
            messageText = await E2EEncryptionService.encryptMessage(messageText, recipientIds[0]);
            isEncrypted = true;
          } catch (e) {
            print('❌ Error encrypting message: $e');
          }
        }

        final messageData = {
          'text': messageText,
          'type': type,
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (voiceAudioBase64 != null) 'voiceAudioBase64': voiceAudioBase64,
          if (voiceDuration != null) 'voiceDuration': voiceDuration,
          if (stickerId != null) 'stickerId': stickerId,
          'isEncrypted': isEncrypted,
          if (replyToId != null) 'replyToId': replyToId,
          if (replyToText != null) 'replyToText': replyToText,
          'isForwarded': isForwarded,
          if (originalSender != null) 'originalSender': originalSender,
          'reactions': {},
          'isTyping': false,
          'status': 'sent', // Начинаем со статуса "отправляется"
        };

        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(messageData);

        // Обновляем последнее сообщение в чате
        await firestore.collection('chats').doc(chatId).update({
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        // Успешно отправлено
        state = const AsyncValue.data(null);
        return;
      } catch (e, stack) {
        if (attempt == maxRetries) {
          // Последняя попытка не удалась
          state = AsyncValue.error(e, stack);
          rethrow;
        }
        // Ждем перед повторной попыткой
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }
}

final messageSenderProvider =
    StateNotifierProvider<MessageSenderNotifier, AsyncValue<void>>((ref) {
  return MessageSenderNotifier();
});

