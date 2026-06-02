import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/core_providers.dart';
import '../auth/auth_screen.dart';
import '../models/chat.dart';
import '../utils/navigation_animations.dart';
import 'single_chat_screen.dart';

/// REFACTORED: ChatScreen using new Repository Pattern
/// This shows the NEW approach - gradually replace old ChatScreen
class ChatScreenRefactored extends ConsumerWidget {
  const ChatScreenRefactored({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }

        // Use new repository-based provider
        final chatsAsync = ref.watch(userChatsProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Чаты'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_comment),
                tooltip: 'Новый чат',
                onPressed: () {
                  // Navigate to new chat screen
                  // Navigator.push(context, ...)
                },
              ),
            ],
          ),
          body: chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Чаты не найдены',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _ChatTile(
                    chat: chat,
                    onTap: () => _openChat(context, chat),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки чатов'),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userChatsProvider(user.uid)),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Auth error: $error'),
        ),
      ),
    );
  }

  void _openChat(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(
        SingleChatScreen(chat: chat),
      ),
    );
  }
}

/// Individual chat tile
class _ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        chat.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageTime),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          if (chat.lastMessageStatus != 'read')
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн.';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

/// MIGRATION NOTES:
/// 
/// 1. This component uses `userChatsProvider` which:
///    - Returns data from local cache first (instant load)
///    - Syncs with Firestore in background
///    - Handles offline by showing cached data
///
/// 2. Replace old ChatScreen gradually:
///    - Option A: Create new ChatScreenRefactored, swap in main.dart
///    - Option B: Keep both, add toggle for testing
///    - Option C: Gradually copy-paste logic into old component
///
/// 3. Error handling is built-in via AsyncValue.error
///
/// 4. No direct Firestore calls - all through repository!
///
/// 5. Automatic realtime updates via Stream subscription
///
/// BENEFITS OVER OLD APPROACH:
/// ✅ Works offline (shows cached data)
/// ✅ Better error handling (specific error states)
/// ✅ Type-safe (Result<T> pattern)
/// ✅ No memory leaks (Riverpod manages subscriptions)
/// ✅ Testable (repository is dependency-injected)
/// ✅ Scales well (same pattern for all data)
