import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List> getUserChats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          chatId: chatId,
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          type: data['type'] ?? 'text',
          imageUrl: data['imageUrl'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          replyToId: data['replyToId'],
          replyToText: data['replyToText'],
          isForwarded: data['isForwarded'] ?? false,
          originalSender: data['originalSender'],
          reactions: Map<String, String>.from(data['reactions'] ?? {}),
          isTyping: data['isTyping'] ?? false,
        );
      }).toList();
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
    String? replyToId,
    String? replyToText,
    bool isForwarded = false,
    String? originalSender,
  }) async {
    try {
      final messageData = {
        'text': text,
        'type': type,
        'senderId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToText != null) 'replyToText': replyToText,
        'isForwarded': isForwarded,
        if (originalSender != null) 'originalSender': originalSender,
        'reactions': {},
        'isTyping': false,
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
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

  static void createTestChat() {
    print('Creating test chat...');
  }
}
