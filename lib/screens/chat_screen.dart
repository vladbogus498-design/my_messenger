import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'single_chat_screen.dart';
import 'new_chat_screen.dart';
import 'group_create_screen.dart';
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
        title: Text('Темные чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment),
            tooltip: 'Новый чат',
            onPressed: () => Navigator.push(
              context,
              NavigationAnimations.slideFadeRoute(NewChatScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          NavigationAnimations.slideFadeRoute(GroupCreateScreen()),
        ),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Создать группу'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsQuery,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              onCreateGroup: () => Navigator.push(
                context,
                NavigationAnimations.slideFadeRoute(GroupCreateScreen()),
              ),
            );
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Здесь пока пусто',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первую группу, чтобы начать диалог.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Создать группу'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
