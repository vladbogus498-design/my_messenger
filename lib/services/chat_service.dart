import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/typing_status.dart';
import 'e2e_encryption_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<Chat>> getUserChats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      return snapshot.docs.map<Chat>((doc) => Chat.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error loading chats: $e');
      return [];
    }
  }

  static Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = await Future.wait(snapshot.docs.map((doc) async {
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

        return Message(
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
        );
      }));

      return messages;
    } catch (e) {
      print('❌ Error loading messages: $e');
      return [];
    }
  }

  static Future<void> sendMessage({
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
  }) async {
    try {
      var messageText = text;
      var isEncrypted = false;

      // Шифруем сообщение, если требуется
      if (encrypt && messageText.isNotEmpty && recipientIds != null && recipientIds.isNotEmpty) {
        try {
          // Для простоты шифруем для первого получателя (в групповых чатах нужна более сложная логика)
          messageText = await E2EEncryptionService.encryptMessage(messageText, recipientIds[0]);
          isEncrypted = true;
        } catch (e) {
          print('❌ Error encrypting message: $e');
          // Продолжаем с незашифрованным сообщением
        }
      }

      // Validate sticker type
      if (type == 'sticker' && (stickerId == null || stickerId.isEmpty)) {
        print('❌ Error: sticker type requires stickerId');
        throw Exception('Sticker type requires stickerId');
      }

      final messageData = {
        'text': messageText,
        'type': type,
        'senderId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(), // Firestore автоматически использует UTC
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
        'status': 'sending', // Начинаем со статуса "отправляется"
      };

      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Обновляем статус на "отправлено" после успешной записи
      await messageRef.update({'status': 'sent'});

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Автоматически обновляем статус на "доставлено" через небольшую задержку
      // (в реальном приложении это должно происходить при получении сообщения на устройстве получателя)
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await messageRef.update({'status': 'delivered'});
        } catch (e) {
          print('❌ Error updating message status to delivered: $e');
        }
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      throw e;
    }
  }

  // 🔄 Пересылка сообщения
  static Future<void> forwardMessage(
      Message message, String targetChatId) async {
    await sendMessage(
      chatId: targetChatId,
      text: message.text,
      type: message.type,
      imageUrl: message.imageUrl,
      voiceAudioBase64: message.voiceAudioBase64,
      voiceDuration: message.voiceDuration,
      stickerId: message.stickerId,
      isForwarded: true,
      originalSender: message.senderId,
    );
  }

  // ❤️ Добавление реакции
  static Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final doc = await messageRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final reactions = Map<String, String>.from(data['reactions'] ?? {});

        if (reactions[userId] == emoji) {
          reactions.remove(userId); // убираем реакцию
        } else {
          reactions[userId] = emoji; // добавляем реакцию
        }

        await messageRef.update({'reactions': reactions});
      }
    } catch (e) {
      print('❌ Error adding reaction: $e');
    }
  }

  // ✍️ Статус "печатает"
  static Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('❌ Error setting typing status: $e');
    }
  }

  // 📸 Статус "отправляет фото"
  static Future<void> setSendingPhotoStatus(
      String chatId, bool isSending) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'sendingPhotoUsers': isSending
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('❌ Error setting photo status: $e');
    }
  }

  // 🎤 Статус "записывает голосовое"
  static Future<void> setRecordingVoiceStatus(
      String chatId, bool isRecording) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'recordingVoiceUsers': isRecording
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('❌ Error setting voice status: $e');
    }
  }

  // 👀 Получение статусов "печатает"
  static Stream<List<String>> getTypingUsers(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      final typingUsers = data?['typingUsers'] as List<dynamic>?;
      return typingUsers?.cast<String>() ?? [];
    });
  }

  // 📸 Получение статусов "отправляет фото"
  static Stream<List<String>> getSendingPhotoUsers(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      final sendingPhotoUsers = data?['sendingPhotoUsers'] as List<dynamic>?;
      return sendingPhotoUsers?.cast<String>() ?? [];
    });
  }

  // 🎤 Получение статусов "записывает голосовое"
  static Stream<List<String>> getRecordingVoiceUsers(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      final recordingVoiceUsers =
          data?['recordingVoiceUsers'] as List<dynamic>?;
      return recordingVoiceUsers?.cast<String>() ?? [];
    });
  }

  // 📊 Получение всех статусов активности в одном потоке
  static Stream<TypingStatus> getTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return TypingStatus(
        typingUsers: (data?['typingUsers'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        sendingPhotoUsers: (data?['sendingPhotoUsers'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        recordingVoiceUsers:
            (data?['recordingVoiceUsers'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
      );
    });
  }

  static void createTestChat() {
    print('Creating test chat...');
  }

  // ✅ Отметить сообщение как прочитанное
  static Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'read'});
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  // ✅ Отметить все сообщения в чате как прочитанные
  static Future<void> markAllMessagesAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('status', isEqualTo: 'sent')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
    }
  }

  // ✅ Обновить статус сообщения на "доставлено"
  static Future<void> markMessageAsDelivered(
      String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'delivered'});
    } catch (e) {
      print('❌ Error marking message as delivered: $e');
    }
  }
}
