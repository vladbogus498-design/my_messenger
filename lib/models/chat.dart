import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String name;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageStatus;
  final DateTime lastMessageTime;
  final bool isGroup;
  final List<String> admins;
  final String? groupName;

  Chat({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageStatus,
    required this.lastMessageTime,
    this.isGroup = false,
    this.admins = const [],
    this.groupName,
  });

  factory Chat.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Chat(
      id: doc.id,
      name: data['name'] ?? 'Chat',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      admins: List<String>.from(data['admins'] ?? const []),
      groupName: data['groupName'],
    );
  }

  @override
  String toString() {
    return 'Chat{id: $id, name: $name, participants: $participants}';
  }

  // Для дебага
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageStatus': lastMessageStatus,
      'lastMessageTime': lastMessageTime.toString(),
      'isGroup': isGroup,
      'admins': admins,
      'groupName': groupName,
    };
  }
}
