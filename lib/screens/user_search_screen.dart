import 'package:flutter/material.dart';

class UserSearchScreen extends StatefulWidget {
  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  // Временный фикс - убираем ChatService
  void _searchUsers(String query) {
    // Твой код поиска
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: Center(
        child: Text('Search Screen - fix later'),
      ),
    );
  }
}
