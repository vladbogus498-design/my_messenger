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

  // ФИКС: ПЕРЕЗАГРУЗКА СПИСКА ЧАТОВ
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

  // ФИКС: СОЗДАНИЕ ЧАТА С МГНОВЕННЫМ ОБНОВЛЕНИЕМ
  void _createTestChat() async {
    try {
      print('🔄 Создаем тестовый чат...');
      await ChatService.createTestChat();
      print('✅ Чат создан, обновляем список...');

      // НЕМЕДЛЕННОЕ ОБНОВЛЕНИЕ после создания
      _loadChats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Тестовый чат создан!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Ошибка создания чата: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
            onPressed: _createTestChat,
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
                      Icon(Icons.chat, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет чатов',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createTestChat,
                        child: Text('Создать тестовый чат'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadChats(),
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Text(
                              chat.name.isNotEmpty ? chat.name[0] : '?',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            chat.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(chat.lastMessage ?? 'Нет сообщений'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _openChat(chat),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
