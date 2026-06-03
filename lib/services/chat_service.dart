import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/message_type.dart';
import '../models/typing_status.dart';
import '../utils/input_validator.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';
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

      final chats = snapshot.docs.map(Chat.fromFirestore).toList();
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    } catch (e) {
      appLogger.e('Error loading chats', error: e);
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

      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        var messageText = data['text'] ?? '';
        final isEncrypted = data['isEncrypted'] ?? false;

        if (isEncrypted && messageText.isNotEmpty) {
          try {
            messageText = await E2EEncryptionService.decryptMessage(messageText);
          } catch (e) {
            appLogger.e('Error decrypting message in chat: $chatId', error: e);
          }
        }

        return Message.fromMap({
          ...data,
          'chatId': chatId,
          'text': messageText,
        }, doc.id);
      }));
    } catch (e) {
      appLogger.e('Error loading messages for chat: $chatId', error: e);
      return [];
    }
  }

  static String createMessageId(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;
  }

  static Future<void> sendMessage({
    required String chatId,
    required String text,
    required String type,
    String? imageUrl,
    String? voiceAudioBase64,
    int? voiceDuration,
    String? stickerId,
    String? stickerUrl,
    String? replyToId,
    String? replyToText,
    bool isForwarded = false,
    String? originalSender,
    bool encrypt = false,
    List<String>? recipientIds,
    String? messageId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (!AppRateLimiters.messageLimiter.tryRequest('send_message_$userId')) {
        throw Exception('Превышен лимит отправки сообщений. Попробуй позже.');
      }

      if (!MessageType.isValid(type)) {
        throw Exception('Invalid message type: $type');
      }

      if (!InputValidator.isValidChatId(chatId)) {
        throw Exception('Invalid chatId');
      }

      if (messageId != null && messageId.contains('/')) {
        throw Exception('Invalid messageId');
      }

      if (type == 'text') {
        final validationError = InputValidator.validateMessage(text);
        if (validationError != null) throw Exception(validationError);
      }

      if (type == 'image' && (imageUrl == null || imageUrl.isEmpty)) {
        throw Exception('Image message requires imageUrl');
      }

      if (type == 'sticker' &&
          ((stickerId == null || stickerId.isEmpty) &&
              (stickerUrl == null || stickerUrl.isEmpty))) {
        throw Exception('Sticker message requires stickerId or stickerUrl');
      }

      if (type == 'voice' && voiceAudioBase64 != null) {
        final base64Size = voiceAudioBase64.length * 3 ~/ 4;
        final sizeError =
            InputValidator.validateFileSize(base64Size, isVoice: true);
        if (sizeError != null) throw Exception(sizeError);
      }

      if (replyToId != null && !InputValidator.isValidChatId(replyToId)) {
        appLogger.w('Invalid replyToId: $replyToId');
        replyToId = null;
      }

      if (recipientIds != null) {
        recipientIds =
            recipientIds.where(InputValidator.isValidUserId).toList();
        if (recipientIds.isEmpty && encrypt) {
          encrypt = false;
        }
      }

      final originalText = text.trim();
      var messageText =
          originalText.isEmpty ? '' : InputValidator.sanitizeMessage(text);
      final previewText = _lastMessagePreview(type, messageText);
      var isEncrypted = false;

      if (encrypt &&
          messageText.isNotEmpty &&
          recipientIds != null &&
          recipientIds.isNotEmpty) {
        try {
          messageText =
              await E2EEncryptionService.encryptMessage(messageText, recipientIds[0]);
          isEncrypted = true;
        } catch (e) {
          appLogger.e('Error encrypting message for chat: $chatId', error: e);
        }
      }

      final now = FieldValue.serverTimestamp();
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef
          .collection('messages')
          .doc(messageId ?? createMessageId(chatId));

      final messageData = <String, dynamic>{
        'chatId': chatId,
        'text': messageText,
        'type': type,
        'senderId': userId,
        'timestamp': now,
        'createdAt': now,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (voiceAudioBase64 != null) 'voiceAudioBase64': voiceAudioBase64,
        if (voiceDuration != null) 'voiceDuration': voiceDuration,
        if (stickerId != null) 'stickerId': stickerId,
        if (stickerUrl != null) 'stickerUrl': stickerUrl,
        'isEncrypted': isEncrypted,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToText != null) 'replyToText': replyToText,
        'isForwarded': isForwarded,
        if (originalSender != null) 'originalSender': originalSender,
        'reactions': <String, String>{},
        'isTyping': false,
        'status': 'sent',
        'readBy': [userId],
      };

      final chatUpdate = <String, dynamic>{
        'lastMessage': previewText,
        'lastMessageType': type,
        'lastMessageAt': now,
        'lastMessageTime': now,
        'lastMessageId': messageRef.id,
        'lastMessageStatus': 'sent',
        'lastMessageReadBy': [userId],
        'lastSenderId': userId,
        'updatedAt': now,
      };

      final batch = _firestore.batch();
      batch.set(messageRef, messageData);
      batch.update(chatRef, chatUpdate);
      await batch.commit();

      appLogger.d('Message sent successfully to chat: $chatId');
    } catch (e) {
      appLogger.e('Error sending message to chat: $chatId', error: e);
      rethrow;
    }
  }

  static Future<void> forwardMessage(
    Message message,
    String targetChatId,
  ) async {
    await sendMessage(
      chatId: targetChatId,
      text: message.text,
      type: message.type,
      imageUrl: message.imageUrl,
      voiceAudioBase64: message.voiceAudioBase64,
      voiceDuration: message.voiceDuration,
      stickerId: message.stickerId,
      stickerUrl: message.stickerUrl,
      isForwarded: true,
      originalSender: message.senderId,
    );
  }

  static Future<void> addReaction(
    String chatId,
    String messageId,
    String emoji,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final doc = await messageRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final reactions = Map<String, String>.from(data['reactions'] ?? const {});
      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      await messageRef.update({'reactions': reactions});
    } catch (e) {
      appLogger.e('Error adding reaction to message: $messageId', error: e);
    }
  }

  static Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('typingStatus').doc(chatId).set({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error setting typing status for chat: $chatId', error: e);
    }
  }

  static Future<void> setSendingPhotoStatus(
    String chatId,
    bool isSending,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('typingStatus').doc(chatId).set({
        'sendingPhotoUsers': isSending
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error setting photo status for chat: $chatId', error: e);
    }
  }

  static Future<void> setRecordingVoiceStatus(
    String chatId,
    bool isRecording,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('typingStatus').doc(chatId).set({
        'recordingVoiceUsers': isRecording
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error setting voice status for chat: $chatId', error: e);
    }
  }

  static Stream<List<String>> getTypingUsers(String chatId) {
    return _typingStatusField(chatId, 'typingUsers');
  }

  static Stream<List<String>> getSendingPhotoUsers(String chatId) {
    return _typingStatusField(chatId, 'sendingPhotoUsers');
  }

  static Stream<List<String>> getRecordingVoiceUsers(String chatId) {
    return _typingStatusField(chatId, 'recordingVoiceUsers');
  }

  static Stream<TypingStatus> getTypingStatus(String chatId) {
    return _firestore.collection('typingStatus').doc(chatId).snapshots().map(
      (doc) {
        final data = doc.data();
        return TypingStatus(
          typingUsers:
              (data?['typingUsers'] as List<dynamic>?)?.cast<String>() ??
                  const [],
          sendingPhotoUsers:
              (data?['sendingPhotoUsers'] as List<dynamic>?)?.cast<String>() ??
                  const [],
          recordingVoiceUsers:
              (data?['recordingVoiceUsers'] as List<dynamic>?)
                      ?.cast<String>() ??
                  const [],
        );
      },
    );
  }

  static Future<String> createChat({
    required String otherUserId,
    String? chatName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (!InputValidator.isValidUserId(otherUserId)) {
      throw Exception('Invalid otherUserId');
    }

    if (userId == otherUserId) {
      throw Exception('Cannot create chat with yourself');
    }

    try {
      if (!AppRateLimiters.chatCreationLimiter
          .tryRequest('create_chat_$userId')) {
        throw Exception('Превышен лимит создания чатов. Попробуй позже.');
      }

      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in existingChats.docs) {
        final data = doc.data();
        if (data['isGroup'] == true) continue;

        final participants = List<String>.from(data['participants'] ?? const []);
        if (participants.length == 2 &&
            participants.toSet().containsAll({userId, otherUserId})) {
          return doc.id;
        }
      }

      final now = FieldValue.serverTimestamp();
      final participants = [userId, otherUserId];
      final chatRef = _firestore.collection('chats').doc();
      final batch = _firestore.batch();

      batch.set(chatRef, {
        'name': chatName ?? 'Chat',
        'isGroup': false,
        'participants': participants,
        'admins': [],
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageAt': now,
        'lastMessageTime': now,
        'lastMessageStatus': 'sent',
        'lastMessageReadBy': <String>[],
        'lastSenderId': null,
        'createdAt': now,
        'updatedAt': now,
        'createdBy': userId,
      });

      for (final participant in participants) {
        batch.set(
          _firestore
              .collection('users')
              .doc(participant)
              .collection('chats')
              .doc(chatRef.id),
          {
            'chatId': chatRef.id,
            'createdAt': now,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      appLogger.d('Chat created successfully: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      appLogger.e('Error creating chat with user: $otherUserId', error: e);
      rethrow;
    }
  }

  static void createTestChat() {
    appLogger.d('Creating test chat...');
  }

  static Future<void> markMessageAsRead(
    String chatId,
    String messageId,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
        'status': 'read',
      });
    } catch (e) {
      appLogger.e('Error marking message as read: $messageId', error: e);
    }
  }

  static Future<void> markAllMessagesAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messagesRef = chatRef.collection('messages');
      final snapshot = await messagesRef.get();
      final batch = _firestore.batch();
      var changed = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        final readBy = List<String>.from(data['readBy'] ?? const []);
        if (senderId == userId || readBy.contains(userId)) continue;

        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': 'read',
        });
        changed++;
      }

      if (changed == 0) return;

      final chatDoc = await chatRef.get();
      final chatData = chatDoc.data();
      if (chatData != null && chatData['lastSenderId'] != userId) {
        batch.update(chatRef, {
          'lastMessageReadBy': FieldValue.arrayUnion([userId]),
          'lastMessageStatus': 'read',
        });
      }

      await batch.commit();
      appLogger.d('Marked $changed messages as read in chat: $chatId');
    } catch (e) {
      appLogger.e('Error marking all messages as read in chat: $chatId', error: e);
    }
  }

  static Future<void> markMessageAsDelivered(
    String chatId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'sent'});
    } catch (e) {
      appLogger.e('Error marking message as delivered: $messageId', error: e);
    }
  }

  static Stream<List<String>> _typingStatusField(
    String chatId,
    String field,
  ) {
    return _firestore.collection('typingStatus').doc(chatId).snapshots().map(
      (doc) {
        final data = doc.data();
        return (data?[field] as List<dynamic>?)?.cast<String>() ?? const [];
      },
    );
  }

  static String _lastMessagePreview(String type, String text) {
    switch (type) {
      case 'image':
        return 'Фото';
      case 'sticker':
        return 'Стикер';
      case 'voice':
        return 'Голосовое сообщение';
      default:
        return text;
    }
  }
}
