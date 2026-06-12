import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

final chatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final userId = ref
      .watch(authStateProvider)
      .maybeWhen(data: (user) => user?.uid, orElse: () => null);
  if (userId == null || userId.isEmpty) {
    return Stream.value(const <Chat>[]);
  }

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: userId)
      .snapshots()
      .map((snapshot) => _ownedSortedChats(snapshot.docs, userId))
      .handleError((Object error, StackTrace stackTrace) {
        appLogger.e('Chats stream failed', error: error);
        throw error;
      });
});

class ChatsNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  ChatsNotifier(this._currentUserId) : super(const AsyncValue.loading()) {
    _init();
  }

  final String? _currentUserId;
  StreamSubscription<List<Chat>>? _chatsSubscription;

  void _init() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => _ownedSortedChats(snapshot.docs, userId))
        .listen(
          (chats) => state = AsyncValue.data(chats),
          onError: (error, stack) {
            appLogger.e('Chats notifier stream failed', error: error);
            state = AsyncValue.error(error, stack);
          },
        );
  }

  void disposeListeners() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }
}

final chatsNotifierProvider =
    StateNotifierProvider.autoDispose<ChatsNotifier, AsyncValue<List<Chat>>>((
      ref,
    ) {
      final userId = ref
          .watch(authStateProvider)
          .maybeWhen(data: (user) => user?.uid, orElse: () => null);
      return ChatsNotifier(userId);
    });

List<Chat> _ownedSortedChats(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String userId,
) {
  final chats = docs
      .map((doc) => Chat.fromFirestore(doc))
      .where((chat) => chat.participants.contains(userId))
      .toList();
  chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return chats;
}
