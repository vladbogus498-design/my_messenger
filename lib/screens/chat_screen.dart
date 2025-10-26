import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';

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
      print('Ошибка загрузки чатов: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openChat(Chat chat) {
    // ТВОЙ КОД ДЛЯ ОТКРЫТИЯ ЧАТА
    print('Открываем чат: ${chat.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
        actions: [
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
