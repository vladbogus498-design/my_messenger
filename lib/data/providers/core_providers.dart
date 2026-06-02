import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/hive_local_datasource.dart';
import '../datasources/remote/firebase_remote_datasource.dart';
import '../datasources/secure/platform_secure_key_storage.dart';
import '../repositories/chat_repository_impl.dart';
import '../domain/services/security_service.dart';
import '../domain/failures/app_failure.dart';
import '../domain/entities/result.dart';
import '../models/chat.dart';
import '../models/message.dart';

// ==== INFRASTRUCTURE PROVIDERS ====

/// Firebase Firestore instance
final firestoreProvider = Provider((ref) {
  return FirebaseFirestore.instance;
});

/// Firebase Auth instance
final firebaseAuthProvider = Provider((ref) {
  return FirebaseAuth.instance;
});

/// Local Hive data source
final localDataSourceProvider = FutureProvider((ref) async {
  final dataSource = HiveLocalDataSource();
  await dataSource.init();
  return dataSource;
});

/// Secure key storage
final secureKeyStorageProvider = FutureProvider((ref) async {
  final storage = PlatformSecureKeyStorage();
  await storage.init();
  return storage;
});

/// Remote data source
final remoteDataSourceProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FirebaseRemoteDataSource(firestore: firestore, auth: auth);
});

/// Security service
final securityServiceProvider = FutureProvider((ref) async {
  final storage = await ref.watch(secureKeyStorageProvider.future);
  return SecurityServiceImpl(keyStorage: storage);
});

// ==== REPOSITORY PROVIDERS ====

/// Chat repository
final chatRepositoryProvider = Provider((ref) {
  final remote = ref.watch(remoteDataSourceProvider);
  final localAsync = ref.watch(localDataSourceProvider);
  
  // This will require handling of async local datasource
  // In production, you'd initialize local on app startup
  return localAsync.whenData((local) {
    return ChatRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });
});

// ==== FEATURE PROVIDERS ====

/// Get user chats with offline support
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) async* {
  final chatRepoAsync = ref.watch(chatRepositoryProvider);
  
  await for (final chatRepo in chatRepoAsync.stream) {
    // Use streaming to get live updates
    await for (final result in chatRepo.watchChats(userId)) {
      switch (result) {
        case Success(:final value):
          yield value;
        case Failure(:final failure):
          yield const [];
          ref.read(errorNotifierProvider.notifier).setError(failure);
      }
    }
  }
});

/// Get messages for a specific chat
final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) async* {
  final chatRepoAsync = ref.watch(chatRepositoryProvider);
  
  await for (final chatRepo in chatRepoAsync.stream) {
    await for (final result in chatRepo.watchMessages(chatId)) {
      switch (result) {
        case Success(:final value):
          yield value;
        case Failure(:final failure):
          yield const [];
          ref.read(errorNotifierProvider.notifier).setError(failure);
      }
    }
  }
});

// ==== STATE MANAGEMENT ====

/// Global error notifier
class ErrorNotifier extends StateNotifier<AppFailure?> {
  ErrorNotifier() : super(null);

  void setError(AppFailure? failure) {
    state = failure;
  }

  void clearError() {
    state = null;
  }
}

final errorNotifierProvider =
    StateNotifierProvider<ErrorNotifier, AppFailure?>((ref) {
  return ErrorNotifier();
});

/// Loading state for operations
final loadingProvider = StateProvider((ref) {
  return false;
});

/// Send message mutation
final sendMessageProvider = FutureProvider.family<void, (String, Message)>(
  (ref, params) async {
    final (chatId, message) = params;
    ref.read(loadingProvider.notifier).state = true;
    
    try {
      final chatRepoAsync = ref.watch(chatRepositoryProvider);
      final chatRepo = await chatRepoAsync.future;
      
      final result = await chatRepo.sendMessage(chatId, message);
      
      result.fold(
        onSuccess: (_) {
          ref.read(errorNotifierProvider.notifier).clearError();
        },
        onFailure: (failure) {
          ref.read(errorNotifierProvider.notifier).setError(failure);
        },
      );
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  },
);

/// Create chat mutation
final createChatProvider = FutureProvider.family<void, Chat>(
  (ref, chat) async {
    ref.read(loadingProvider.notifier).state = true;
    
    try {
      final chatRepoAsync = ref.watch(chatRepositoryProvider);
      final chatRepo = await chatRepoAsync.future;
      
      final result = await chatRepo.createChat(chat);
      
      result.fold(
        onSuccess: (_) {
          ref.read(errorNotifierProvider.notifier).clearError();
        },
        onFailure: (failure) {
          ref.read(errorNotifierProvider.notifier).setError(failure);
        },
      );
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  },
);

/// Initialize security - generate keys if needed
final initializeSecurityProvider = FutureProvider((ref) async {
  final securityAsync = ref.watch(securityServiceProvider);
  
  return securityAsync.whenData((security) async {
    final hasKeys = await security.hasActiveKeyPair();
    
    switch (hasKeys) {
      case Success(value: true):
        return true;
      case Success(value: false):
        // Generate new keys
        final genResult = await security.generateAndStoreKeyPair();
        return genResult.isSuccess;
      case Failure(:final failure):
        ref.read(errorNotifierProvider.notifier).setError(failure);
        return false;
    }
  });
});
