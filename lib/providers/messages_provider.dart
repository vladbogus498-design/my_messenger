import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/e2e_encryption_service.dart';
import '../utils/logger.dart';

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
            appLogger.e('Error decrypting message in chat: $chatId', error: e);
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

// Примечание: Логика отправки сообщений унифицирована в ChatService.sendMessage
// Этот провайдер используется только для получения сообщений

