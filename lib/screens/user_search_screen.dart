import 'package:flutter/material.dart';
import 'chat_screen.dart';

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
      AppUser(name: 'Алексей', email: 'alex@mail.com', id: '1'),
      AppUser(name: 'Мария', email: 'maria@mail.com', id: '2'),
      AppUser(name: 'Дмитрий', email: 'dima@mail.com', id: '3'),
      AppUser(name: 'Анна', email: 'anna@mail.com', id: '4'),
      AppUser(name: 'Сергей', email: 'sergey@mail.com', id: '5'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentLanguage == 'ru' ? 'Поиск' : 'Search'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Text(
              _currentLanguage == 'ru' ? 'EN' : 'RU',
              style: TextStyle(
                color: Colors.white,
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
              decoration: InputDecoration(
                hintText: texts['search_users']!,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              user.name[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(user.email),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(language: _currentLanguage),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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

  AppUser({required this.id, required this.name, required this.email});
}
