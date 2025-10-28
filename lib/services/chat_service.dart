import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // СОЗДАНИЕ ТЕСТОВОГО ЧАТА
  static Future<void> createTestChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ createTestChat: пользователь не авторизован');
        throw Exception('Пользователь не авторизован');
      }

      final userId = user.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final chatRef = _firestore.collection('chats').doc();

      // ФИКС: УНИКАЛЬНОЕ ИМЯ И ПРАВИЛЬНЫЕ ДАННЫЕ
      final chatData = {
        'id': chatRef.id, // ДОБАВЛЕНО: явно сохраняем ID
        'name': 'Тестовый чат ${timestamp % 10000}', // Короткое имя
        'participants': [userId],
        'lastMessage': 'Чат создан! Начните общение 🚀',
        'lastMessageStatus': 'read',
        'lastMessageTime': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'createdBy': userId, // ДОБАВЛЕНО: кто создал
      };

      print('🔄 Создаем чат с данными: $chatData');

      await chatRef.set(chatData);

      // ФИКС: СОЗДАЕМ ПЕРВОЕ СООБЩЕНИЕ
      await _firestore
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .doc()
          .set({
        'text': 'Чат создан! Начните общение 🚀',
        'senderId': userId,
        'senderName': user.email?.split('@').first ?? 'User',
        'timestamp': Timestamp.now(),
        'status': 'read',
        'type': 'system',
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
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ getUserChats: пользователь не авторизован');
        return [];
      }

      final userId = user.uid;
      print('🔄 getUserChats: запрашиваем чаты для пользователя $userId');

      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ getUserChats: получено ${querySnapshot.docs.length} чатов');

      // ДЕБАГ: выводим все полученные чаты
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print(
            '📨 Чат: ${data['name']} | ID: ${doc.id} | participants: ${data['participants']}');
      }

      final chats = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Chat(
          id: doc.id, // ФИКС: используем doc.id вместо data['id']
          name: data['name']?.toString() ?? 'Без названия',
          participants: List<String>.from(data['participants'] ?? []),
          lastMessage: data['lastMessage']?.toString() ?? 'Нет сообщений',
          lastMessageStatus: data['lastMessageStatus']?.toString() ?? 'sent',
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
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ DEBUG: пользователь не авторизован');
        return;
      }

      final userId = user.uid;
      final allChats = await _firestore.collection('chats').get();

      print('\n🔍 === DARKKICK DEBUG ===');
      print('👤 Текущий пользователь: $userId');
      print('📊 Всего чатов в базе: ${allChats.docs.length}');
      int userChatsCount = 0;
      for (final doc in allChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final hasAccess = participants.contains(userId);

        if (hasAccess) userChatsCount++;

        print(
            '${hasAccess ? '✅' : '❌'} Чат: "${data['name']}" | ID: ${doc.id}');
        print('   👥 Участники: $participants');
        print('   🕐 Создан: ${(data['createdAt'] as Timestamp?)?.toDate()}');
      }

      print('🎯 Пользователь $userId имеет доступ к $userChatsCount чатам');
      print('🔚 === DEBUG END ===\n');
    } catch (e) {
      print('❌ DEBUG error: $e');
    }
  }
}
