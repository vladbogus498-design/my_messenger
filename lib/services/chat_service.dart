import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<Chat>> getUserChats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Chat(
          id: doc.id,
          name: data['name'] ?? 'Chat',
          participants: List<String>.from(data['participants'] ?? []),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
