import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получить ID текущего пользователя
  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
  }

  // Создать новый чат
  Future<void> createChat(String otherUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty) return;

    final chatId = _generateChatId(currentUserId, otherUserId);

    try {
      await _firestore.collection('chats').doc(chatId).set({
        'id': chatId,
        'participants': [currentUserId, otherUserId],
        'lastMessage': 'Чат создан',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });
      print('✅ Чат создан: $chatId');
    } catch (e) {
      print('❌ Ошибка создания чата: $e');
    }
  }

  // Отправить сообщение
  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty) return;

    try {
      // Добавляем сообщение в подколлекцию
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

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('✅ Сообщение отправлено в чат: $chatId');
    } catch (e) {
      print('❌ Ошибка отправки сообщения: $e');
    }
  }

  // Получить поток чатов пользователя
  Stream<QuerySnapshot> getChatsStream() {
    final currentUserId = getCurrentUserId();
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Получить поток сообщений чата
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Генерация ID чата
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  // Получить ID чата для двух пользователей
  String getChatId(String otherUserId) {
    final currentUserId = getCurrentUserId();
    return _generateChatId(currentUserId, otherUserId);
  }
}
