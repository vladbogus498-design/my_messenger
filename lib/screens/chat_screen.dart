import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'single_chat_screen.dart';
import 'new_chat_screen.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text('DarkKick Chats')),
        body: Center(child: Text('Not signed in')),
      );
    }

    final chatsQuery = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('DarkKick Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NewChatScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsQuery,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет чатов'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final chatId = docs[i].id;
              final name = d['groupName'] ?? d['name'] ?? 'Chat';
              final last = d['lastMessage'] ?? '';
              final ts = (d['lastMessageTime'] as Timestamp?)?.toDate();
              return ListTile(
                leading:
                    CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
                title: Text(name),
                subtitle: Text(last),
                trailing: Text(ts != null
                    ? '${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                    : ''),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SingleChatScreen(chatId: chatId, chatName: name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
