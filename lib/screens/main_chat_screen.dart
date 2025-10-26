import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class MainChatScreen extends StatefulWidget {
  @override
  _MainChatScreenState createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  String _currentLanguage = 'ru';
  final ChatService _chatService = ChatService();

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'chats': 'Чаты',
      'search': 'Поиск',
      'no_chats': 'Нет чатов',
      'start_chat': 'Начните общение',
      'logout': 'Выйти',
    },
    'en': {
      'chats': 'Chats',
      'search': 'Search',
      'no_chats': 'No chats',
      'start_chat': 'Start chatting',
      'logout': 'Logout',
    },
  };

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizations[_currentLanguage]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(texts[_currentIndex == 0 ? 'chats' : 'search']!),
        backgroundColor: Colors.black,
        foregroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Text(
              _currentLanguage == 'ru' ? 'EN' : 'RU',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: _switchLanguage,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildChatsScreen(texts)
          : UserSearchScreen(language: _currentLanguage),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserSearchScreen(language: _currentLanguage)),
                );
              },
              child: Icon(Icons.chat, color: Colors.white),
              backgroundColor: Colors.red,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: texts['chats']!,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: texts['search']!,
          ),
        ],
      ),
    );
  }

  Widget _buildChatsScreen(Map<String, String> texts) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Ошибка загрузки чатов',
                  style: TextStyle(color: Colors.white)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(texts['no_chats']!,
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                SizedBox(height: 8),
                Text(
                  'Начните новый чат с помощью кнопки ниже',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return Container(
          color: Colors.grey[900],
          child: ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              // Временная заглушка - показываем тестового пользователя
              final otherUser = UserModel(
                uid: 'user_1',
                email: 'ttdvlvd@gmail.com',
                name: 'Подруга',
                bio: 'Тестируем мессенджер',
              );

              return Card(
                color: Colors.grey[800],
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(
                      otherUser.name[0],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(otherUser.name,
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    data['lastMessage'] ?? 'Нет сообщений',
                    style: TextStyle(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(data['lastMessageTime']?.toDate()),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      if ((data['unreadCount'] ?? 0) > 0)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${data['unreadCount']}',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatScreen(
                                language: _currentLanguage,
                                otherUser: otherUser,
                                chatId: chat.id,
                              )),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
