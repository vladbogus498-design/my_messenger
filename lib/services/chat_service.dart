import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/message_type.dart';
import '../models/chat.dart';
import '../models/typing_status.dart';
import 'e2e_encryption_service.dart';
import '../utils/logger.dart';
import '../utils/input_validator.dart';
import '../utils/rate_limiter.dart';

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

      final chats = snapshot.docs.map<Chat>((doc) => Chat.fromFirestore(doc)).toList();
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    } catch (e) {
      // Если запрос с lastMessage.timestamp не работает, пробуем fallback
      appLogger.w('Error loading chats with lastMessage.timestamp, trying fallback', error: e);
      try {
        final snapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: userId)
            .get();
        final chats = snapshot.docs.map<Chat>((doc) => Chat.fromFirestore(doc)).toList();
        chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return chats;
      } catch (e2) {
        appLogger.e('Error loading chats (fallback failed)', error: e2);
        return [];
      }
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
            appLogger.e('Error decrypting message in chat: $chatId', error: e);
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
      appLogger.e('Error loading messages for chat: $chatId', error: e);
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
      // Rate limiting: проверка лимита на отправку сообщений
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      if (!AppRateLimiters.messageLimiter.tryRequest('send_message_$userId')) {
        throw Exception('Превышен лимит отправки сообщений. Попробуйте позже.');
      }

      // Валидация типа сообщения
      if (!MessageType.isValid(type)) {
        throw Exception('Invalid message type: $type');
      }

      // Валидация входных данных
      if (!InputValidator.isValidChatId(chatId)) {
        throw Exception('Invalid chatId');
      }

      // Валидация и санитизация текста сообщения
      if (type == 'text' || type == 'image' || type == 'voice') {
        final validationError = InputValidator.validateMessage(text);
        if (validationError != null) {
          throw Exception(validationError);
        }
      }
      var messageText = text.isEmpty ? '' : InputValidator.sanitizeMessage(text);
      var isEncrypted = false;

      // Шифруем сообщение, если требуется
      if (encrypt && messageText.isNotEmpty && recipientIds != null && recipientIds.isNotEmpty) {
        try {
          // Для простоты шифруем для первого получателя (в групповых чатах нужна более сложная логика)
          messageText = await E2EEncryptionService.encryptMessage(messageText, recipientIds[0]);
          isEncrypted = true;
        } catch (e) {
          appLogger.e('Error encrypting message for chat: $chatId', error: e);
          // Продолжаем с незашифрованным сообщением
        }
      }

      // Validate sticker type
      if (type == 'sticker' && (stickerId == null || stickerId.isEmpty)) {
        appLogger.e('Sticker type requires stickerId');
        throw Exception('Sticker type requires stickerId');
      }

      // Валидация голосового сообщения
      if (type == 'voice' && voiceAudioBase64 != null) {
        // Примерная проверка размера base64 (реальный размер будет меньше)
        final base64Size = voiceAudioBase64.length * 3 ~/ 4; // Примерный размер в байтах
        final sizeError = InputValidator.validateFileSize(base64Size, isVoice: true);
        if (sizeError != null) {
          throw Exception(sizeError);
        }
      }

      // Валидация replyToId
      if (replyToId != null && !InputValidator.isValidChatId(replyToId)) {
        appLogger.w('Invalid replyToId: $replyToId');
        replyToId = null; // Игнорируем невалидный ID
      }

      // Валидация recipientIds
      if (recipientIds != null) {
        recipientIds = recipientIds.where((id) => InputValidator.isValidUserId(id)).toList();
        if (recipientIds.isEmpty && encrypt) {
          appLogger.w('No valid recipient IDs for encryption');
          encrypt = false;
        }
      }

      final messageData = {
        'chatId': chatId,
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
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          'text': text,
          'timestamp': now,
        },
        'lastMessageTime': now, // Для обратной совместимости
      });

      // Автоматически обновляем статус на "доставлено" через небольшую задержку
      // (в реальном приложении это должно происходить при получении сообщения на устройстве получателя)
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await messageRef.update({'status': 'delivered'});
        } catch (e) {
          appLogger.e('Error updating message status to delivered', error: e);
        }
      });
      appLogger.d('Message sent successfully to chat: $chatId');
    } catch (e) {
      appLogger.e('Error sending message to chat: $chatId', error: e);
      rethrow;
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
        appLogger.d('Reaction added: $emoji to message: $messageId');
      }
    } catch (e) {
      appLogger.e('Error adding reaction to message: $messageId', error: e);
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
      appLogger.e('Error setting typing status for chat: $chatId', error: e);
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
      appLogger.e('Error setting photo status for chat: $chatId', error: e);
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
      appLogger.e('Error setting voice status for chat: $chatId', error: e);
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

  /// Создание нового приватного чата между двумя пользователями
  /// Возвращает ID созданного чата или существующего, если чат уже есть
  static Future<String> createChat({
    required String otherUserId,
    String? chatName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      appLogger.w('Cannot create chat: user not authenticated');
      throw Exception('User not authenticated');
    }

    // Валидация входных данных
    if (!InputValidator.isValidUserId(otherUserId)) {
      appLogger.w('Invalid otherUserId: $otherUserId');
      throw Exception('Invalid otherUserId');
    }

    if (userId == otherUserId) {
      appLogger.w('Cannot create chat with yourself');
      throw Exception('Cannot create chat with yourself');
    }

    try {
      // Rate limiting: проверка лимита на создание чатов
      if (!AppRateLimiters.chatCreationLimiter.tryRequest('create_chat_$userId')) {
        throw Exception('Превышен лимит создания чатов. Попробуйте позже.');
      }

      // Проверяем, существует ли уже чат между этими пользователями
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in existingChats.docs) {
        final data = doc.data();
        if (data['isGroup'] == true) continue;

        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.toSet().containsAll({userId, otherUserId}) && 
            participants.length == 2) {
          appLogger.d('Chat already exists: ${doc.id}');
          return doc.id;
        }
      }

      // Создаем новый чат
      final now = FieldValue.serverTimestamp();
      final participants = [userId, otherUserId];
      
      final chatDoc = await _firestore.collection('chats').add({
        'name': chatName ?? 'Chat',
        'isGroup': false,
        'participants': participants,
        'admins': [],
        'lastMessage': {
          'text': '',
          'timestamp': now,
        },
        'lastMessageStatus': 'sent',
        'lastMessageTime': now, // Для обратной совместимости
        'createdAt': now,
        'createdBy': userId,
      });

      final chatId = chatDoc.id;
      appLogger.d('Chat created successfully: $chatId');

      // Создаем записи в подколлекциях пользователей (опционально, для быстрого доступа)
      try {
        final batch = _firestore.batch();
        
        // Добавляем чат в список чатов первого пользователя
        batch.set(
          _firestore.collection('users').doc(userId).collection('chats').doc(chatId),
          {
            'chatId': chatId,
            'addedAt': now,
          },
          SetOptions(merge: true),
        );
        
        // Добавляем чат в список чатов второго пользователя
        batch.set(
          _firestore.collection('users').doc(otherUserId).collection('chats').doc(chatId),
          {
            'chatId': chatId,
            'addedAt': now,
          },
          SetOptions(merge: true),
        );
        
        await batch.commit();
        appLogger.d('User chat references created for chat: $chatId');
      } catch (e) {
        // Не критично, если не удалось создать ссылки
        appLogger.w('Failed to create user chat references', error: e);
      }

      return chatId;
    } catch (e) {
      appLogger.e('Error creating chat with user: $otherUserId', error: e);
      rethrow;
    }
  }

  static void createTestChat() {
    appLogger.d('Creating test chat...');
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
      appLogger.d('Message marked as read: $messageId');
    } catch (e) {
      appLogger.e('Error marking message as read: $messageId', error: e);
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
      appLogger.d('All messages marked as read in chat: $chatId');
    } catch (e) {
      appLogger.e('Error marking all messages as read in chat: $chatId', error: e);
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
      appLogger.d('Message marked as delivered: $messageId');
    } catch (e) {
      appLogger.e('Error marking message as delivered: $messageId', error: e);
    }
  }
}
