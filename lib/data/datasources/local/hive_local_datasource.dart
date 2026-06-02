import 'package:hive_flutter/hive_flutter.dart';
import '../../../utils/logger.dart';

/// Abstract local data source using Hive
abstract class LocalDataSource {
  Future<void> init();
  
  Future<void> saveChat(String chatId, Map<String, dynamic> chatData);
  Future<Map<String, dynamic>?> getChat(String chatId);
  Future<List<Map<String, dynamic>>> getAllChats();
  Future<void> deleteChat(String chatId);
  
  Future<void> saveMessage(String chatId, String messageId, Map<String, dynamic> messageData);
  Future<Map<String, dynamic>?> getMessage(String chatId, String messageId);
  Future<List<Map<String, dynamic>>> getChatMessages(String chatId);
  Future<void> deleteMessage(String chatId, String messageId);
  Future<void> clearChatMessages(String chatId);
  
  Future<void> saveUser(String userId, Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUser(String userId);
  Future<void> deleteUser(String userId);
  
  Future<void> clear();
}

/// Hive implementation of local data source
class HiveLocalDataSource implements LocalDataSource {
  late Box<Map<dynamic, dynamic>> _chatsBox;
  late Box<Map<dynamic, dynamic>> _messagesBox;
  late Box<Map<dynamic, dynamic>> _usersBox;
  late Box<Map<dynamic, dynamic>> _metadataBox;

  static const String _chatsBoxName = 'chats';
  static const String _messagesBoxName = 'messages';
  static const String _usersBoxName = 'users';
  static const String _metadataBoxName = 'metadata';

  @override
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      _chatsBox = await Hive.openBox<Map<dynamic, dynamic>>(_chatsBoxName);
      _messagesBox = await Hive.openBox<Map<dynamic, dynamic>>(_messagesBoxName);
      _usersBox = await Hive.openBox<Map<dynamic, dynamic>>(_usersBoxName);
      _metadataBox = await Hive.openBox<Map<dynamic, dynamic>>(_metadataBoxName);

      appLogger.i('Hive local storage initialized successfully');
    } catch (e) {
      appLogger.e('Error initializing Hive', error: e);
      rethrow;
    }
  }

  // ==== CHATS ====
  @override
  Future<void> saveChat(String chatId, Map<String, dynamic> chatData) async {
    try {
      await _chatsBox.put(chatId, chatData);
      appLogger.d('Chat saved locally: $chatId');
    } catch (e) {
      appLogger.e('Error saving chat $chatId', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getChat(String chatId) async {
    try {
      final data = _chatsBox.get(chatId);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      appLogger.e('Error getting chat $chatId', error: e);
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllChats() async {
    try {
      return _chatsBox.values
          .map((chat) => Map<String, dynamic>.from(chat))
          .toList();
    } catch (e) {
      appLogger.e('Error getting all chats', error: e);
      return [];
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatsBox.delete(chatId);
      // Удаляем все сообщения этого чата
      await clearChatMessages(chatId);
      appLogger.d('Chat deleted locally: $chatId');
    } catch (e) {
      appLogger.e('Error deleting chat $chatId', error: e);
    }
  }

  // ==== MESSAGES ====
  @override
  Future<void> saveMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      final key = '$chatId#$messageId';
      await _messagesBox.put(key, messageData);
      appLogger.d('Message saved locally: $key');
    } catch (e) {
      appLogger.e('Error saving message in chat $chatId', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getMessage(
    String chatId,
    String messageId,
  ) async {
    try {
      final key = '$chatId#$messageId';
      final data = _messagesBox.get(key);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      appLogger.e('Error getting message', error: e);
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      final prefix = '$chatId#';
      return _messagesBox.keys
          .where((key) => key.toString().startsWith(prefix))
          .map((key) => _messagesBox.get(key))
          .whereType<Map<dynamic, dynamic>>()
          .map((msg) => Map<String, dynamic>.from(msg))
          .toList();
    } catch (e) {
      appLogger.e('Error getting chat messages', error: e);
      return [];
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final key = '$chatId#$messageId';
      await _messagesBox.delete(key);
      appLogger.d('Message deleted locally: $key');
    } catch (e) {
      appLogger.e('Error deleting message', error: e);
    }
  }

  @override
  Future<void> clearChatMessages(String chatId) async {
    try {
      final prefix = '$chatId#';
      final keysToDelete = _messagesBox.keys
          .where((key) => key.toString().startsWith(prefix))
          .toList();
      
      for (final key in keysToDelete) {
        await _messagesBox.delete(key);
      }
      appLogger.d('Chat messages cleared: $chatId');
    } catch (e) {
      appLogger.e('Error clearing chat messages', error: e);
    }
  }

  // ==== USERS ====
  @override
  Future<void> saveUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _usersBox.put(userId, userData);
      appLogger.d('User saved locally: $userId');
    } catch (e) {
      appLogger.e('Error saving user $userId', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final data = _usersBox.get(userId);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      appLogger.e('Error getting user $userId', error: e);
      return null;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _usersBox.delete(userId);
      appLogger.d('User deleted locally: $userId');
    } catch (e) {
      appLogger.e('Error deleting user $userId', error: e);
    }
  }

  // ==== GENERAL ====
  @override
  Future<void> clear() async {
    try {
      await _chatsBox.clear();
      await _messagesBox.clear();
      await _usersBox.clear();
      await _metadataBox.clear();
      appLogger.i('All local data cleared');
    } catch (e) {
      appLogger.e('Error clearing local data', error: e);
      rethrow;
    }
  }
}
