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
      setState(() => _isLoading = false);
    }
  }

  // СОЗДАНИЕ ТЕСТОВОГО ЧАТА
  void _createTestChat() async {
    try {
      await ChatService.createTestChat();
      _loadChats(); // Перезагружаем список
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Тестовый чат создан!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SingleChatScreen(chatId: chat.id)),
    );
  }

  // ИКОНКА СТАТУСА СООБЩЕНИЯ
  Widget _buildMessageStatus(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, size: 16, color: Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: Colors.grey);
      case 'read':
        return Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return Icon(Icons.access_time, size: 16, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createTestChat, // ТЕСТОВЫЙ ЧАТ
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
                      subtitle: Row(
                        children: [
                          Expanded(child: Text(chat.lastMessage ?? '')),
                          _buildMessageStatus(chat.lastMessageStatus), // СТАТУС
                        ],
                      ),
                      trailing: Text('12:30'), // Время
                      onTap: () => _openChat(chat),
                    );
                  },
                ),
    );
  }
}
