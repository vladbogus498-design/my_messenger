import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'single_chat_screen.dart';
import 'new_chat_screen.dart';
import '../utils/navigation_animations.dart';
import '../utils/time_formatter.dart';

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
              NavigationAnimations.slideFadeRoute(NewChatScreen()),
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
              final avatarUrl = d['avatarUrl'];
              return ListTile(
                leading: Hero(
                  tag: 'avatar_$chatId',
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          placeholder: (context, url) => CircleAvatar(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                          ),
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            backgroundImage: imageProvider,
                          ),
                        )
                      : CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                        ),
                ),
                title: Text(name),
                subtitle: Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ts != null ? TimeFormatter.formatChatTime(ts) : '',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (d['unreadCount'] != null && d['unreadCount'] > 0)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${d['unreadCount']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  NavigationAnimations.slideFadeRoute(
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
