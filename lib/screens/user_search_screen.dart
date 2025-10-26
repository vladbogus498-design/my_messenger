import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';

class UserSearchScreen extends StatefulWidget {
  final String language;

  UserSearchScreen({required this.language});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  late String _currentLanguage;

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'search_users': 'Поиск пользователей...',
      'no_users': 'Пользователи не найдены',
      'start_chat': 'Начать чат',
    },
    'en': {
      'search_users': 'Search users...',
      'no_users': 'No users found',
      'start_chat': 'Start chat',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;

    _users = [
      AppUser(
          id: '1',
          name: 'Алексей',
          email: 'alex@mail.com',
          bio: 'Люблю кодить и пить кофе'),
      AppUser(
          id: '2',
          name: 'Мария',
          email: 'maria@mail.com',
          bio: 'Дизайнер и художник'),
      AppUser(
          id: '3',
          name: 'Дмитрий',
          email: 'dima@mail.com',
          bio: 'Разработчик игр'),
      AppUser(
          id: '4',
          name: 'Анна',
          email: 'anna@mail.com',
          bio: 'Фотограф и путешественник'),
      AppUser(
          id: '5',
          name: 'Сергей',
          email: 'sergey@mail.com',
          bio: 'Музыкант и продюсер'),
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
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    language: _currentLanguage,
                                    otherUser: user.toUserModel(),
                                  ),
                                ),
                              );
                            },
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
