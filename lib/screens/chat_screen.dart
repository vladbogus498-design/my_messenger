import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import 'user_search_screen.dart'; // Добавь этот импорт

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
      print('✅ Загружено ${chats.length} чатов');
    } catch (e) {
      print('❌ Ошибка загрузки чатов: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openChat(Chat chat) {
    print('🟢 Открываем чат: ${chat.id}');
    // Твой код открытия чата
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Создать новый чат
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSearchScreen()),
              );
            },
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
              ? Center(child: Text('Нет чатов'))
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(chat.name[0]),
                      ),
                      title: Text(chat.name),
                      subtitle: Text(chat.lastMessage ?? ''),
                      onTap: () => _openChat(chat),
                    );
                  },
                ),
    );
  }
}
