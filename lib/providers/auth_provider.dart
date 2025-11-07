import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для отслеживания состояния авторизации
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = FirebaseAuth.instance;
  return auth.authStateChanges();
});

/// Провайдер текущего пользователя
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Провайдер для управления авторизацией
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  StreamSubscription<User?>? _authSubscription;

  void _init() {
    final auth = FirebaseAuth.instance;
    state = AsyncValue.data(auth.currentUser);
    
    _authSubscription = auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  /// Выход из аккаунта с закрытием всех слушателей
  Future<void> signOut() async {
    try {
      // Отменяем подписки
      await _authSubscription?.cancel();
      _authSubscription = null;
      
      // Выходим из аккаунта
      await FirebaseAuth.instance.signOut();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

