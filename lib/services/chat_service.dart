import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // СОЗДАНИЕ ТЕСТОВОГО ЧАТА
  static Future<void> createTestChat() async {
    try {
      final userId = _auth.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final chatRef = _firestore.collection('chats').doc();

      // ФИКС: УНИКАЛЬНОЕ ИМЯ И ПРАВИЛЬНЫЕ ДАННЫЕ
      final chatData = {
        'name': 'Тестовый чат $timestamp',
        'participants': [userId],
        'lastMessage': 'Привет! Это тестовое сообщение',
        'lastMessageStatus': 'read',
        'lastMessageTime': Timestamp.now(),
        'createdAt': Timestamp.now(), // ВАЖНО: для сортировки
      };

      print('🔄 Создаем чат с данными: $chatData');

      await chatRef.set(chatData);

      // ФИКС: СОЗДАЕМ ПЕРВОЕ СООБЩЕНИЕ
      await _firestore
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .add({
        'text': 'Привет! Это тестовое сообщение',
        'senderId': userId,
        'timestamp': Timestamp.now(),
        'status': 'read',
        'type': 'text',
      });

      print('✅ Чат создан успешно: ${chatRef.id}');
    } catch (e) {
      print('❌ Ошибка создания тестового чата: $e');
      rethrow;
    }
  }

  // ФИКС: ЗАГРУЗКА ЧАТОВ С ПРАВИЛЬНОЙ СОРТИРОВКОЙ
  static Future<List<Chat>> getUserChats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ getUserChats: пользователь не авторизован');
        return [];
      }

      print('🔄 getUserChats: запрашиваем чаты для пользователя $userId');

      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true) // ФИКС: используем createdAt
          .get();

      print('✅ getUserChats: получено ${querySnapshot.docs.length} чатов');

      // ДЕБАГ: выводим все полученные чаты
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print(
            '📨 Чат: ${doc.id} | ${data['name']} | participants: ${data['participants']}');
      }

      final chats = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Chat(
          id: doc.id,
          name: data['name'] ?? 'Без названия',
          participants: List<String>.from(data['participants'] ?? []),
          lastMessage: data['lastMessage'] ?? 'Нет сообщений',
          lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );
      }).toList();

      return chats;
    } catch (e) {
      print('❌ getUserChats error: $e');
      return [];
    }
  }

  // ФИКС: ПРОВЕРКА СУЩЕСТВОВАНИЯ ЧАТОВ (для дебага)
  static Future<void> debugChats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final allChats = await _firestore.collection('chats').get();
      print('🔍 DEBUG: Всего чатов в базе: ${allChats.docs.length}');

      for (final doc in allChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        print(
            '🔍 Чат: ${data['name']} | participants: $participants | contains $userId: ${participants.contains(userId)}');
      }
    } catch (e) {
      print('❌ DEBUG error: $e');
    }
  }
}
