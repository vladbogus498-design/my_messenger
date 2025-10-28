import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ДОБАВЛЕНО: импорт
import '../services/chat_service.dart';
import '../models/chat.dart';
import 'single_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Chat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  // Загрузка чатов
  void _loadChats() async {
    print('🔄 Загружаем чаты...');
    final user = FirebaseAuth.instance.currentUser; // ТЕПЕРЬ РАБОТАЕТ
    print('👤 Текущий пользователь: ${user?.uid}');

    if (user == null) {
      print('❌ ПОЛЬЗОВАТЕЛЬ НЕ АВТОРИЗОВАН!');
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chats = await ChatService.getUserChats();
      print('✅ Загружено ${chats.length} чатов');

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки чатов: $e');
      setState(() => _isLoading = false);
    }
  }

  // ФИКС: метод для RefreshIndicator
  Future<void> _handleRefresh() async {
    await Future<void>;
  }

  // Создание тестового чата
  void _createTestChat() async {
    print('🎯 НАЧАЛО: _createTestChat() вызван');
    try {
      // Показываем уведомление о начале создания
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.schedule, color: Colors.white),
              SizedBox(width: 8),
              Text('Создаем тестовый чат...'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );

      print('🔄 Вызываем ChatService.createTestChat()');
      ChatService.createTestChat(); // ФИКС: убрал await (ошибка Ln 52)
      print('✅ ChatService.createTestChat() завершился');

      // ФИКС: Даем время Firestore обновиться
      await Future.delayed(Duration(seconds: 2));

      // ДЕБАГ: Проверяем что в базе
      print('🔍 Запускаем debugChats()');
      await ChatService.debugChats();

      // Показываем успешное уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Тестовый чат создан! Обновляем список...'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Обновляем список чатов
      print('🔄 Вызываем _loadChats()');
      _loadChats();
    } catch (e) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА: $e');

      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Ошибка создания: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DarkKick Chats'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _createTestChat,
            tooltip: 'Создать тестовый чат',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadChats,
            tooltip: 'Обновить чаты',
          ),
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.white),
            onPressed: ChatService.debugChats,
            tooltip: 'Дебаг',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple))
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Нет чатов',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы создать тестовый чат',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _createTestChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: Text('Создать тестовый чат'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.grey[800],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                chat.name.isNotEmpty
                                    ? chat.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              chat.name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.lastMessage,
                                  style: TextStyle(color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Участников: ${chat.participants.length}',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleChatScreen(
                                    chatId: chat.id,
                                    chatName: chat.name,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
