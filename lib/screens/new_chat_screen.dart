import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'single_chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    final q = _controller.text.trim();
    final fs = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> merged = [];

    if (q.isNotEmpty) {
      final byUsername = await fs
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThan: q + '\uf8ff')
          .limit(20)
          .get();

      final byEmail = await fs
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: q)
          .where('email', isLessThan: q + '\uf8ff')
          .limit(20)
          .get();

      final byPhone = await fs
          .collection('users')
          .where('phone', isGreaterThanOrEqualTo: q)
          .where('phone', isLessThan: q + '\uf8ff')
          .limit(20)
          .get();

      final seen = <String>{};
      for (final d in [...byUsername.docs, ...byEmail.docs, ...byPhone.docs]) {
        if (seen.add(d.id) && d.id != uid) {
          merged.add(d);
        }
      }
    }

    setState(() {
      _results = merged;
      _loading = false;
    });
  }

  Future<void> _openOrCreateChat(String otherUserId, String otherName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Проверяем, не открыт ли уже этот чат
    if (Navigator.canPop(context)) {
      final currentRoute = ModalRoute.of(context);
      if (currentRoute?.settings.arguments != null) {
        // Уже открыт чат, не открываем повторно
        return;
      }
    }
    
    final fs = FirebaseFirestore.instance;
    // Ищем существующий приватный чат
    final existing = await fs
        .collection('chats')
        .where('isGroup', isEqualTo: false)
        .where('participants', arrayContains: uid)
        .get();
    
    String? chatId;
    for (final d in existing.docs) {
      final parts = List<String>.from(d['participants'] ?? []);
      if (parts.toSet().containsAll({uid, otherUserId}) && parts.length == 2) {
        chatId = d.id;
        break;
      }
    }
    
    // НЕ создаем чат сразу - создадим только при отправке первого сообщения
    // Передаем информацию о получателе в SingleChatScreen
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleChatScreen(
          chatId: chatId ?? '', // Пустой ID означает новый чат
          chatName: otherName,
          otherUserId: otherUserId, // Передаем ID получателя для создания чата при отправке
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Новый чат')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'поиск: @username, email или телефон'),
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
                final name = (u['name'] ?? '') as String;
                final uname = (u['username'] ?? '') as String;
                return ListTile(
                  leading: CircleAvatar(
                      child:
                          Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                  title: Text(name.isNotEmpty ? name : uname),
                  subtitle: Text(uname),
                  onTap: () =>
                      _openOrCreateChat(u.id, name.isNotEmpty ? name : uname),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
