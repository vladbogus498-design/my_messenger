import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/chat.dart';

/// Провайдер для получения списка чатов пользователя
final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
  });
});

/// Провайдер для управления слушателями чатов
class ChatsNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  ChatsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  StreamSubscription<List<Chat>>? _chatsSubscription;
  String? _currentUserId;

  void _init() {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    _loadChats();
  }

  void _loadChats() {
    if (_currentUserId == null) return;

    final firestore = FirebaseFirestore.instance;
    _chatsSubscription = firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId!)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    }).listen(
      (chats) {
        state = AsyncValue.data(chats);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  /// Закрыть все слушатели
  void disposeListeners() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
  }

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }
}

final chatsNotifierProvider =
    StateNotifierProvider<ChatsNotifier, AsyncValue<List<Chat>>>((ref) {
  return ChatsNotifier();
});

