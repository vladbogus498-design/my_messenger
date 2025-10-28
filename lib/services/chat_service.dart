import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ФИКС: СОЗДАНИЕ ЧАТА С ПРОВЕРКОЙ
  static Future<void> createTestChat() async {
    try {
      final userId = _auth.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final chatRef = _firestore.collection('chats').doc();

      // ФИКС: УНИКАЛЬНОЕ ИМЯ ЧАТА
      final chatData = {
        'name': 'Тестовый чат $timestamp',
        'participants': [userId],
        'lastMessage': 'Привет! Это тестовое сообщение',
        'lastMessageStatus': 'read',
        'lastMessageTime': Timestamp.now(),
        'createdAt': Timestamp.now(),
      };

      print('🔄 Создаем чат с данными: $chatData');

      await chatRef.set(chatData);

      // ФИКС: СООБЩЕНИЕ ДЛЯ ЧАТА
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

      print('✅ Чат создан успешно: ${chatRef.id}');
    } catch (e) {
      print('❌ Ошибка создания тестового чата: $e');
      rethrow;
    }
  }

  // ФИКС: ЗАГРУЗКА ЧАТОВ С ДЕБАГОМ
  static Future<List<Chat>> getUserChats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ Пользователь не авторизован');
        return [];
      }

      print('🔄 Запрашиваем чаты для пользователя: $userId');

      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      print('✅ Получено ${querySnapshot.docs.length} чатов из Firestore');

      final chats = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📨 Чат ${doc.id}: ${data['name']}');

        return Chat(
          id: doc.id,
          name: data['name'] ?? 'Без названия',
          participants: List<String>.from(data['participants'] ?? []),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );
      }).toList();

      return chats;
    } catch (e) {
      print('❌ Firestore error: $e');
      return [];
    }
  }
}
