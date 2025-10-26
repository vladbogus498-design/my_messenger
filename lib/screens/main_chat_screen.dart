import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import '../models/user_model.dart';

class MainChatScreen extends StatefulWidget {
  @override
  _MainChatScreenState createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  String _currentLanguage = 'ru';

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'chats': 'Чаты',
      'search': 'Поиск',
      'no_chats': 'Нет чатов',
      'start_chat': 'Начните общение',
      'logout': 'Выйти',
      'new_chat': 'Новый чат',
    },
    'en': {
      'chats': 'Chats',
      'search': 'Search',
      'no_chats': 'No chats',
      'start_chat': 'Start chatting',
      'logout': 'Logout',
      'new_chat': 'New chat',
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
    return Container(
      color: Colors.grey[900],
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[800],
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red,
                child: Text(
                  'U${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text('Пользователь ${index + 1}',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Последнее сообщение в чате...',
                  style: TextStyle(color: Colors.grey)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('12:30',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text('1',
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(
                            language: _currentLanguage,
                            otherUser: UserModel(
                              uid: 'user_${index + 1}',
                              email: 'user${index + 1}@mail.com',
                              name: 'Пользователь ${index + 1}',
                              bio: 'Тестовый пользователь ${index + 1}',
                            ),
                          )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
