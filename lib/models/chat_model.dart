import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final String? type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = 'text',
  });

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values[data['status'] ?? 0],
      type: data['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.index,
      'type': type,
    };
  }
}

enum MessageStatus {
  sent, // отправлено
  delivered, // доставлено
  read, // прочитано
}
