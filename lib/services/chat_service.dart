import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import '../models/message.dart';

class ChatService {
  // ... твой существующий код ...

  static Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          chatId: chatId,
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          type: data['type'] ?? 'text',
          imageUrl: data['imageUrl'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error loading messages: $e');
      return [];
    }
  }

  static Future<void> sendMessage({
    required String chatId,
    required String text,
    required String type,
    String? imageUrl,
  }) async {
    try {
      final messageData = {
        'text': text,
        'type': type,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update last message in chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      throw e;
    }
  }

  static void createTestChat() {}

  static Future getUserChats() async {}
}
