import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/failures/app_failure.dart';
import '../../../domain/entities/result.dart';
import '../../../models/chat.dart';
import '../../../models/message.dart';
import '../../../models/user_model.dart';
import '../../../utils/logger.dart';

/// Abstract remote data source for Firebase operations
abstract class RemoteDataSource {
  // Auth
  Future<Result<UserCredential>> signInWithEmail(String email, String password);
  Future<Result<UserCredential>> registerWithEmail(String email, String password);
  Future<Result<void>> signOut();

  // Chats
  Future<Result<List<Chat>>> getChats(String userId);
  Future<Result<Chat?>> getChat(String chatId);
  Future<Result<void>> createChat(Chat chat);
  Future<Result<void>> updateChat(String chatId, Map<String, dynamic> updates);
  Future<Result<void>> deleteChat(String chatId);
  Stream<Result<List<Chat>>> watchChats(String userId);

  // Messages
  Future<Result<List<Message>>> getMessages(String chatId, {int limit = 50});
  Future<Result<Message?>> getMessage(String chatId, String messageId);
  Future<Result<void>> sendMessage(String chatId, Message message);
  Future<Result<void>> deleteMessage(String chatId, String messageId);
  Stream<Result<List<Message>>> watchMessages(String chatId);

  // Users
  Future<Result<UserModel?>> getUser(String userId);
  Future<Result<void>> createUser(String userId, UserModel user);
  Future<Result<void>> updateUser(String userId, Map<String, dynamic> updates);
}

/// Firebase Firestore implementation
class FirebaseRemoteDataSource implements RemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const FirebaseRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // ==== AUTH ====
  @override
  Future<Result<UserCredential>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      appLogger.i('User signed in: $email');
      return Success(result);
    } on FirebaseAuthException catch (e) {
      appLogger.e('Sign in error: ${e.code}', error: e);
      return Failure(
        AuthenticationFailure(
          message: _mapFirebaseAuthError(e.code),
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected sign in error', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<UserCredential>> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      appLogger.i('User registered: $email');
      return Success(result);
    } on FirebaseAuthException catch (e) {
      appLogger.e('Registration error: ${e.code}', error: e);
      return Failure(
        AuthenticationFailure(
          message: _mapFirebaseAuthError(e.code),
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected registration error', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      appLogger.i('User signed out');
      return const Success(null);
    } catch (e) {
      appLogger.e('Sign out error', error: e);
      return Failure(
        AuthenticationFailure(
          message: 'Failed to sign out',
          originalError: e,
        ),
      );
    }
  }

  // ==== CHATS ====
  @override
  Future<Result<List<Chat>>> getChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final chats = snapshot.docs
          .map((doc) => Chat.fromFirestore(doc))
          .toList();

      appLogger.d('Loaded ${chats.length} chats for user: $userId');
      return Success(chats);
    } on FirebaseException catch (e) {
      appLogger.e('Error loading chats', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to load chats',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error loading chats', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Chat?>> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) {
        return const Success(null);
      }
      return Success(Chat.fromFirestore(doc));
    } on FirebaseException catch (e) {
      appLogger.e('Error loading chat: $chatId', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to load chat',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error loading chat', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> createChat(Chat chat) async {
    try {
      await _firestore.collection('chats').doc(chat.id).set({
        'name': chat.name,
        'participants': chat.participants,
        'lastMessage': {'text': chat.lastMessage, 'timestamp': Timestamp.now()},
        'lastMessageTime': Timestamp.now(),
        'isGroup': chat.isGroup,
        'admins': chat.admins,
        'groupName': chat.groupName,
      });
      appLogger.d('Chat created: ${chat.id}');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error creating chat', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to create chat',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error creating chat', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateChat(
    String chatId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update(updates);
      appLogger.d('Chat updated: $chatId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error updating chat: $chatId', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to update chat',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error updating chat', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
      appLogger.d('Chat deleted: $chatId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error deleting chat: $chatId', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to delete chat',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error deleting chat', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Stream<Result<List<Chat>>> watchChats(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          final chats = snapshot.docs
              .map((doc) => Chat.fromFirestore(doc))
              .toList();
          return Success(chats);
        } catch (e) {
          appLogger.e('Error mapping chats', error: e);
          return Failure(
            UnexpectedFailure(
              message: 'Failed to parse chats',
              originalError: e,
            ),
          );
        }
      });
    } catch (e) {
      appLogger.e('Error watching chats', error: e);
      yield Failure(
        UnexpectedFailure(
          message: 'Failed to watch chats',
          originalError: e,
        ),
      );
    }
  }

  // ==== MESSAGES ====
  @override
  Future<Result<List<Message>>> getMessages(
    String chatId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final messages = snapshot.docs
          .map((doc) => Message.fromMap(doc.data(), doc.id))
          .toList();

      appLogger.d('Loaded ${messages.length} messages from chat: $chatId');
      return Success(messages);
    } on FirebaseException catch (e) {
      appLogger.e('Error loading messages', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to load messages',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error loading messages', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Message?>> getMessage(
    String chatId,
    String messageId,
  ) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!doc.exists) {
        return const Success(null);
      }

      return Success(Message.fromMap(doc.data() ?? {}, doc.id));
    } on FirebaseException catch (e) {
      appLogger.e('Error loading message', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to load message',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error loading message', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> sendMessage(String chatId, Message message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toFirestore());

      appLogger.d('Message sent to chat: $chatId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error sending message', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to send message',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error sending message', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      appLogger.d('Message deleted from chat: $chatId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error deleting message', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to delete message',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error deleting message', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Stream<Result<List<Message>>> watchMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          final messages = snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), doc.id))
              .toList();
          return Success(messages);
        } catch (e) {
          appLogger.e('Error mapping messages', error: e);
          return Failure(
            UnexpectedFailure(
              message: 'Failed to parse messages',
              originalError: e,
            ),
          );
        }
      });
    } catch (e) {
      appLogger.e('Error watching messages', error: e);
      yield Failure(
        UnexpectedFailure(
          message: 'Failed to watch messages',
          originalError: e,
        ),
      );
    }
  }

  // ==== USERS ====
  @override
  Future<Result<UserModel?>> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return const Success(null);
      }
      return Success(UserModel.fromMap(doc.data() ?? {}));
    } on FirebaseException catch (e) {
      appLogger.e('Error loading user: $userId', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to load user',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error loading user', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> createUser(String userId, UserModel user) async {
    try {
      await _firestore.collection('users').doc(userId).set(user.toMap());
      appLogger.d('User created: $userId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error creating user', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to create user',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error creating user', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      appLogger.d('User updated: $userId');
      return const Success(null);
    } on FirebaseException catch (e) {
      appLogger.e('Error updating user: $userId', error: e);
      return Failure(
        NetworkFailure(
          message: 'Failed to update user',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      appLogger.e('Unexpected error updating user', error: e);
      return Failure(
        UnexpectedFailure(
          message: 'An unexpected error occurred',
          originalError: e,
        ),
      );
    }
  }

  String _mapFirebaseAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'User not found',
      'wrong-password' => 'Wrong password',
      'user-disabled' => 'User account has been disabled',
      'too-many-requests' => 'Too many sign-in attempts. Please try again later.',
      'operation-not-allowed' => 'Operation not allowed',
      'email-already-in-use' => 'Email is already in use',
      'invalid-email' => 'Invalid email address',
      'weak-password' => 'Password is too weak',
      'network-request-failed' => 'Network error. Please check your connection.',
      _ => 'An authentication error occurred',
    };
  }
}
