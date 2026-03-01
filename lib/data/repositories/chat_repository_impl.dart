import '../datasources/local/hive_local_datasource.dart';
import '../datasources/remote/firebase_remote_datasource.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/entities/result.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/user_model.dart';
import '../../utils/logger.dart';

/// Repository for all chat-related operations
/// Implements offline-first pattern: local cache + remote sync
abstract class ChatRepository {
  // Queries
  Future<Result<List<Chat>>> getChats(String userId);
  Future<Result<Chat?>> getChat(String chatId);
  Future<Result<List<Message>>> getMessages(String chatId, {int limit = 50});
  Future<Result<Message?>> getMessage(String chatId, String messageId);
  Future<Result<UserModel?>> getUser(String userId);

  // Mutations
  Future<Result<void>> createChat(Chat chat);
  Future<Result<void>> sendMessage(String chatId, Message message);
  Future<Result<void>> updateUserProfile(String userId, Map<String, dynamic> updates);
  Future<Result<void>> deleteMessage(String chatId, String messageId);

  // Streams for realtime updates
  Stream<Result<List<Chat>>> watchChats(String userId);
  Stream<Result<List<Message>>> watchMessages(String chatId);
}

/// Implementation combining local cache (Hive) + remote (Firebase)
class ChatRepositoryImpl implements ChatRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  ChatRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  // ==== QUERIES ====

  @override
  Future<Result<List<Chat>>> getChats(String userId) async {
    try {
      // 1. Try to get from local cache first (offline-first)
      final localChats = await _localDataSource.getAllChats();
      if (localChats.isNotEmpty) {
        appLogger.d('Loaded ${localChats.length} chats from local cache');
        // Return local data while syncing remote
        _syncChatsInBackground(userId);
        return Success(
          localChats.map((data) => _chatFromMap(data)).toList(),
        );
      }

      // 2. Get from remote if cache is empty
      final remoteResult = await _remoteDataSource.getChats(userId);

      return remoteResult.maybeMap(
        success: (chats) async {
          // Save to local cache
          for (final chat in chats) {
            await _localDataSource.saveChat(
              chat.id,
              chat.toMap(),
            );
          }
          return Success(chats);
        },
        failure: (failure) => Failure(failure),
      );
    } catch (e) {
      appLogger.e('Error getting chats', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to load chats',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Chat?>> getChat(String chatId) async {
    try {
      // Try local first
      final localChat = await _localDataSource.getChat(chatId);
      if (localChat != null) {
        appLogger.d('Chat loaded from local cache: $chatId');
        _syncChatInBackground(chatId);
        return Success(_chatFromMap(localChat));
      }

      // Get from remote
      final result = await _remoteDataSource.getChat(chatId);
      return result.maybeMap(
        success: (chat) async {
          if (chat != null) {
            await _localDataSource.saveChat(chatId, chat.toMap());
          }
          return Success(chat);
        },
        failure: (failure) => Failure(failure),
      );
    } catch (e) {
      appLogger.e('Error getting chat: $chatId', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to load chat',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Message>>> getMessages(
    String chatId, {
    int limit = 50,
  }) async {
    try {
      // Try local first
      final localMessages = await _localDataSource.getChatMessages(chatId);
      if (localMessages.isNotEmpty) {
        appLogger.d('Loaded ${localMessages.length} messages from local cache');
        _syncMessagesInBackground(chatId, limit);
        return Success(
          localMessages
              .map((data) => Message.fromMap(data, data['id'] ?? ''))
              .toList(),
        );
      }

      // Get from remote
      final result = await _remoteDataSource.getMessages(chatId, limit: limit);
      return result.maybeMap(
        success: (messages) async {
          for (final message in messages) {
            await _localDataSource.saveMessage(
              chatId,
              message.id,
              message.toFirestore()..['id'] = message.id,
            );
          }
          return Success(messages);
        },
        failure: (failure) => Failure(failure),
      );
    } catch (e) {
      appLogger.e('Error getting messages', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to load messages',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Message?>> getMessage(String chatId, String messageId) async {
    try {
      final localMessage =
          await _localDataSource.getMessage(chatId, messageId);
      if (localMessage != null) {
        return Success(Message.fromMap(localMessage, messageId));
      }

      final result = await _remoteDataSource.getMessage(chatId, messageId);
      return result.maybeMap(
        success: (message) async {
          if (message != null) {
            await _localDataSource.saveMessage(
              chatId,
              messageId,
              message.toFirestore()..['id'] = message.id,
            );
          }
          return Success(message);
        },
        failure: (failure) => Failure(failure),
      );
    } catch (e) {
      appLogger.e('Error getting message', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to load message',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<UserModel?>> getUser(String userId) async {
    try {
      // Try local first
      final localUser = await _localDataSource.getUser(userId);
      if (localUser != null) {
        return Success(UserModel.fromMap(localUser));
      }

      // Get from remote
      final result = await _remoteDataSource.getUser(userId);
      return result.maybeMap(
        success: (user) async {
          if (user != null) {
            await _localDataSource.saveUser(userId, user.toMap());
          }
          return Success(user);
        },
        failure: (failure) => Failure(failure),
      );
    } catch (e) {
      appLogger.e('Error getting user', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to load user',
          originalError: e,
        ),
      );
    }
  }

  // ==== MUTATIONS ====

  @override
  Future<Result<void>> createChat(Chat chat) async {
    try {
      // Save locally first (optimistic)
      await _localDataSource.saveChat(chat.id, chat.toMap());

      // Sync with remote
      final result = await _remoteDataSource.createChat(chat);

      return result;
    } catch (e) {
      appLogger.e('Error creating chat', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to create chat',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> sendMessage(String chatId, Message message) async {
    try {
      // Save locally first (optimistic update)
      await _localDataSource.saveMessage(
        chatId,
        message.id,
        message.toFirestore()..['id'] = message.id,
      );

      // Sync with remote
      final result = await _remoteDataSource.sendMessage(chatId, message);

      return result;
    } catch (e) {
      appLogger.e('Error sending message', error: e);
      // Don't remove from local - will retry later
      return Failure(
        UnexpectedFailure(
          message: 'Failed to send message',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Update remote first for sensitive user data
      final result = await _remoteDataSource.updateUser(userId, updates);

      // Update local cache
      final user = await _localDataSource.getUser(userId);
      if (user != null) {
        user.addAll(updates);
        await _localDataSource.saveUser(userId, user);
      }

      return result;
    } catch (e) {
      appLogger.e('Error updating user profile', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to update profile',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteMessage(String chatId, String messageId) async {
    try {
      // Delete locally first
      await _localDataSource.deleteMessage(chatId, messageId);

      // Delete from remote
      return await _remoteDataSource.deleteMessage(chatId, messageId);
    } catch (e) {
      appLogger.e('Error deleting message', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'Failed to delete message',
          originalError: e,
        ),
      );
    }
  }

  // ==== STREAMS ====

  @override
  Stream<Result<List<Chat>>> watchChats(String userId) {
    return _remoteDataSource.watchChats(userId).asyncMap((result) async {
      // Also save to local cache
      if (result.isSuccess) {
        final chats = result.fold(
          onSuccess: (c) => c,
          onFailure: (f) => <Chat>[],
        );
        for (final chat in chats) {
          await _localDataSource.saveChat(chat.id, chat.toMap());
        }
      }
      return result;
    });
  }

  @override
  Stream<Result<List<Message>>> watchMessages(String chatId) {
    return _remoteDataSource.watchMessages(chatId).asyncMap((result) async {
      // Also save to local cache
      if (result.isSuccess) {
        final messages = result.fold(
          onSuccess: (m) => m,
          onFailure: (f) => <Message>[],
        );
        for (final message in messages) {
          await _localDataSource.saveMessage(
            chatId,
            message.id,
            message.toFirestore()..['id'] = message.id,
          );
        }
      }
      return result;
    });
  }

  // ==== BACKGROUND SYNC ====

  void _syncChatsInBackground(String userId) {
    _remoteDataSource.getChats(userId).then((result) {
      result.maybeMap(
        success: (chats) async {
          for (final chat in chats) {
            await _localDataSource.saveChat(chat.id, chat.toMap());
          }
          appLogger.d('Background sync completed: ${chats.length} chats');
        },
        failure: (failure) {
          appLogger.w('Background sync failed', error: failure);
        },
      );
    });
  }

  void _syncChatInBackground(String chatId) {
    _remoteDataSource.getChat(chatId).then((result) {
      result.maybeMap(
        success: (chat) async {
          if (chat != null) {
            await _localDataSource.saveChat(chatId, chat.toMap());
          }
        },
        failure: (failure) {
          appLogger.w('Chat sync failed', error: failure);
        },
      );
    });
  }

  void _syncMessagesInBackground(String chatId, int limit) {
    _remoteDataSource.getMessages(chatId, limit: limit).then((result) {
      result.maybeMap(
        success: (messages) async {
          for (final message in messages) {
            await _localDataSource.saveMessage(
              chatId,
              message.id,
              message.toFirestore()..['id'] = message.id,
            );
          }
          appLogger.d('Messages synced: $chatId (${messages.length} messages)');
        },
        failure: (failure) {
          appLogger.w('Messages sync failed', error: failure);
        },
      );
    });
  }

  // ==== HELPERS ====

  Chat _chatFromMap(Map<String, dynamic> data) {
    return Chat(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
      lastMessageTime: data['lastMessageTime'] is String
          ? DateTime.parse(data['lastMessageTime'])
          : DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      admins: List<String>.from(data['admins'] ?? []),
      groupName: data['groupName'],
    );
  }
}
