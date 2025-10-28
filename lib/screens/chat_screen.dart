import 'package:flutter/material.dart';
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

  void _loadChats() async {
    print('🔄 Загружаем чаты...');
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

  Future<void> _handleRefresh() async {
    ChatService.createTestChat();
  }

  void _createTestChat() async {
    try {
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

      // ФИКС: убрал await
      ChatService.createTestChat();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Тестовый чат создан!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadChats();
    } catch (e) {
      print('❌ Ошибка создания тестового чата: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Ошибка: $e'),
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
        title: Text('Chats'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createTestChat,
            tooltip: 'Создать тестовый чат',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChats,
            tooltip: 'Обновить чаты',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
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
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            chat.name.isNotEmpty ? chat.name[0] : '?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          chat.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Участников: ${chat.participants.length}',
                          style: TextStyle(color: Colors.grey),
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
                      );
                    },
                  ),
      ),
    );
  }
}
