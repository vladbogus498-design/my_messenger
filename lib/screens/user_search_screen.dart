import 'package:flutter/material.dart';
import '../services/user_search_service.dart';
import '../services/friend_service.dart';
import '../models/user_model.dart';

class UserSearchScreen extends StatefulWidget {
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    final res = await UserSearchService.searchByUsernameOrEmail(_controller.text.trim());
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Поиск пользователей')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Имя пользователя или email'),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _search, child: Text('Найти')),
              ],
            ),
          ),
          if (_loading) LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final u = _results[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')),
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  trailing: IconButton(
                    icon: Icon(Icons.person_add),
                    onPressed: () => FriendService.sendFriendRequest(u.uid),
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
