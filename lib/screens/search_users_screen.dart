import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await UserService.searchUsersByTag(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка поиска: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Поиск пользователей'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени или тэгу...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _searchUsers(value);
                } else {
                  setState(() => _searchResults = []);
                }
              },
            ),
          ),
          if (_isSearching)
            Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Пользователи не найдены',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Введите имя или тэг для поиска',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(user.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.name, style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      user.bio ?? user.email,
                      style: TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: user.uid,
                            isMyProfile: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

