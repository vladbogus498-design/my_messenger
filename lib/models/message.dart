import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final String? imageUrl;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
