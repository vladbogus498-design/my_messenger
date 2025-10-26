import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'unknown_user';
  }

  Future<void> createChat(String otherUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty || currentUserId == 'unknown_user') {
      print('❌ Неизвестный пользователь');
      return;
    }

    final chatId = _generateChatId(currentUserId, otherUserId);
    
    try {
      // Проверяем, существует ли уже чат
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'participants': [currentUserId, otherUserId],
          'lastMessage': 'Чат создан 🚀',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        print('✅ Чат создан: $chatId');
      } else {
        print('ℹ️ Чат уже существует: $chatId');
      }
    } catch (e) {
      print('❌ Ошибка создания чата: $e');
    }
  }

  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty || currentUserId == 'unknown_user') return;

    try {
      // Добавляем сообщение
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 0, // sent
      });

      // Обновляем последнее сообщение
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      });
      
      print('✅ Сообщение отправлено: "$text"');
    } catch (e) {
      print('❌ Ошибка отправки сообщения: $e');
    }
  }

  Stream<QuerySnapshot> getChatsStream() {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty || currentUserId == 'unknown_user') {
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  String getChatId(String otherUserId) {
    final currentUserId = getCurrentUserId();
    return _generateChatId(currentUserId, otherUserId);
  }
}