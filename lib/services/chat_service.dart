import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ФИКС: СОЗДАНИЕ ТЕСТОВОГО ЧАТА
  static Future<void> createTestChat() async {
    try {
      final userId = _auth.currentUser!.uid;
      final chatRef = _firestore.collection('chats').doc();

      // Создаем чат с самим собой для теста
      await chatRef.set({
        'name': 'Тестовый чат',
        'participants': [userId], // Только текущий пользователь
        'lastMessage': 'Привет! Это тестовое сообщение',
        'lastMessageStatus': 'read',
        'lastMessageTime': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Добавляем тестовое сообщение
      await _firestore
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .add({
        'text': 'Привет! Это тестовое сообщение',
        'senderId': userId,
        'timestamp': Timestamp.now(),
        'status': 'read',
      });

      print('✅ Тестовый чат создан: ${chatRef.id}');
    } catch (e) {
      print('❌ Ошибка создания тестового чата: $e');
      rethrow;
    }
  }

  // ФИКС: ПОЛУЧЕНИЕ ЧАТОВ ПОЛЬЗОВАТЕЛЯ
  static Future<List<Chat>> getUserChats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Chat(
          id: doc.id,
          name: data['name'] ?? 'Chat',
          participants: List<String>.from(data['participants'] ?? []),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('❌ Firestore error: $e');
      return [];
    }
  }
}
