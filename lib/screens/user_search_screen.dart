import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class UserSearchScreen extends StatefulWidget {
  final String language;

  const UserSearchScreen({required this.language});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  late String _currentLanguage;
  bool _isCreatingChat = false;

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'search_users': 'Поиск пользователей...',
      'no_users': 'Пользователи не найдены',
      'start_chat': 'Начать чат',
      'creating_chat': 'Создаём чат...',
    },
    'en': {
      'search_users': 'Search users...',
      'no_users': 'No users found',
      'start_chat': 'Start chat',
      'creating_chat': 'Creating chat...',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;

    _users = [
      AppUser(
          id: '16', // Твой тест-аккаунт 2
          name: 'Test User 16',
          email: 'test16@mail.com',
          bio: 'Тестовый аккаунт 16'),
      AppUser(
          id: '17', // Твой тест-аккаунт 1
          name: 'Test User 17',
          email: 'test17@mail.com',
          bio: 'Тестовый аккаунт 17'),
      AppUser(
          id: 'user_1',
          name: 'Подруга',
          email: 'ttdvlvd@gmail.com',
          bio: 'Тестируем мессенджер'),
    ];
    _filteredUsers = _users;
  }

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  void _searchUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _startChat(AppUser user) async {
    if (_isCreatingChat) return;

    setState(() => _isCreatingChat = true);

    try {
      print('🔄 Создаём чат с ${user.name}...');

      // Создаём чат в Firestore
      await _chatService.createChat(user.id);

      // Получаем ID чата
      final chatId = _chatService.getChatId(user.id);

      print('✅ Чат создан: $chatId');

      // Немного задержки для стабильности
      await Future.delayed(Duration(milliseconds: 300));

      // Переходим в чат
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            language: _currentLanguage,
            otherUser: user.toUserModel(),
            chatId: chatId,
          ),
        ),
        (route) => false, // Закрываем все предыдущие экраны
      );
    } catch (e) {
      print('❌ Ошибка создания чата: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания чата')),
      );
    } finally {
      setState(() => _isCreatingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizations[_currentLanguage]!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentLanguage == 'ru' ? 'Поиск' : 'Search'),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: texts['search_users']!,
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      texts['no_users']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        color: Colors.grey[800],
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Text(
                              user.name[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user.name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(user.email,
                              style: TextStyle(color: Colors.grey)),
                          trailing: _isCreatingChat
                              ? CircularProgressIndicator(color: Colors.red)
                              : ElevatedButton(
                                  onPressed: () => _startChat(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    texts['start_chat']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? bio;

  AppUser(
      {required this.id, required this.name, required this.email, this.bio});
  UserModel toUserModel() {
    return UserModel(
      uid: id,
      email: email,
      name: name,
      bio: bio,
    );
  }
}
