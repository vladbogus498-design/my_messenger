import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import 'single_chat_screen.dart';
import 'user_search_screen.dart';

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

  void _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await ChatService.getUserChats();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки чатов: $e');
      setState(() => _isLoading = false);
    }
  }

  // ФИКС: СОЗДАНИЕ ТЕСТОВОГО ЧАТА
  void _createTestChat() async {
    try {
      await ChatService.createTestChat();
      _loadChats(); // Перезагружаем список

      // Показываем уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Тестовый чат создан!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ФИКС: ОТКРЫТИЕ ЧАТА
  void _openChat(Chat chat) {
    print('🟢 Открываем чат: ${chat.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SingleChatScreen(chatId: chat.id, chatName: chat.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createTestChat, // ФИКС: кнопка создания чата
            tooltip: 'Создать тестовый чат',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Нет чатов'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _createTestChat,
                        child: Text('Создать тестовый чат'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text(
                          chat.name[0],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(chat.name),
                      subtitle: Text(chat.lastMessage ?? 'Нет сообщений'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () => _openChat(chat), // ФИКС: открытие чата
                    );
                  },
                ),
    );
  }
}
