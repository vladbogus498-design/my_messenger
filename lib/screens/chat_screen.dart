import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'single_chat_screen.dart';
import 'new_chat_screen.dart';
import 'group_create_screen.dart';
import '../utils/navigation_animations.dart';
import '../utils/time_formatter.dart';
import '../services/group_chat_service.dart';
import '../models/chat.dart';

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

    // Используем lastMessage.timestamp для сортировки
    // Если запрос не работает (нет индекса), ошибка будет обработана в StreamBuilder
    final chatsQuery = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessage.timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsQuery,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Обработка ошибок запроса (например, отсутствие индекса)
          if (snapshot.hasError) {
            print('⚠️ Error loading chats: ${snapshot.error}');
            // Fallback на запрос с lastMessageTime
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, fallbackSnapshot) {
                if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.docs.isEmpty) {
                  return _EmptyState(
                    onCreateGroup: () => _showCreateGroupSheet(context, uid),
                  );
                }
                return _buildChatList(fallbackSnapshot.data!.docs, uid);
              },
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              onCreateGroup: () => _showCreateGroupSheet(context, uid),
            );
          }
          
          return _buildChatList(snapshot.data!.docs, uid);
        },
      ),
    );
  }

  Widget _buildChatList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String uid) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final d = docs[i].data();
        final chatId = docs[i].id;
        final name = d['groupName'] ?? d['name'] ?? 'Chat';
        
        // Обработка lastMessage: может быть объектом или строкой (для обратной совместимости)
        String last = '';
        DateTime? ts;
        
        if (d['lastMessage'] is Map) {
          // Новая структура: lastMessage = {text: '', timestamp: Timestamp}
          final lastMsg = d['lastMessage'] as Map<String, dynamic>;
          last = lastMsg['text'] ?? '';
          final lastMsgTs = lastMsg['timestamp'];
          if (lastMsgTs != null && lastMsgTs is Timestamp) {
            ts = lastMsgTs.toDate();
          }
        } else {
          // Старая структура: lastMessage = строка, lastMessageTime = Timestamp
          last = d['lastMessage'] ?? '';
          ts = (d['lastMessageTime'] as Timestamp?)?.toDate();
        }
        
        // Fallback для timestamp если null
        ts ??= DateTime.now().subtract(Duration(days: 365)); // Старый чат без сообщений
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
          onTap: () {
            // Защита от дублирования - проверяем, не открыт ли уже этот чат
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              final currentRoute = ModalRoute.of(context);
              if (currentRoute?.settings.arguments == chatId) {
                return; // Уже открыт этот чат
              }
            }
            
            Navigator.push(
              context,
              NavigationAnimations.slideFadeRoute(
                SingleChatScreen(chatId: chatId, chatName: name),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateGroupSheet(BuildContext context, String? uid) {
    if (uid == null) return;
    // Navigate to full group creation screen with user selection
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(GroupCreateScreen()),
    ).then((result) {
      if (result != null && result is Chat) {
        // Navigate immediately to the new group
        Navigator.push(
          context,
          NavigationAnimations.slideFadeRoute(
            SingleChatScreen(
              chatId: result.id,
              chatName: result.groupName ?? result.name,
            ),
          ),
        );
      }
    });
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
              'Создай первую группу 🔥',
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
