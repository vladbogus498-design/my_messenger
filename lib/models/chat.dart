import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  const Chat({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageStatus,
    required this.lastMessageTime,
    this.lastMessageType = 'text',
    this.lastSenderId,
    this.lastMessageId,
    this.lastMessageReadBy = const [],
    this.isGroup = false,
    this.admins = const [],
    this.groupName,
  });

  final String id;
  final String name;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageStatus;
  final DateTime lastMessageTime;
  final String lastMessageType;
  final String? lastSenderId;
  final String? lastMessageId;
  final List<String> lastMessageReadBy;
  final bool isGroup;
  final List<String> admins;
  final String? groupName;

  factory Chat.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final legacyLastMessage = data['lastMessage'];
    final rawLastMessage = legacyLastMessage is Map<String, dynamic>
        ? (legacyLastMessage['text'] ?? '').toString()
        : (legacyLastMessage ?? '').toString();
    final lastMessageType = data['lastMessageType'] ?? 'text';
    final lastMessage = _previewText(rawLastMessage, lastMessageType);

    final legacyLastMessageAt = legacyLastMessage is Map<String, dynamic>
        ? legacyLastMessage['timestamp']
        : null;
    final lastMessageAt = data['lastMessageAt'] ??
        data['updatedAt'] ??
        legacyLastMessageAt ??
        data['lastMessageTime'] ??
        data['createdAt'];
    final lastMessageReadBy =
        List<String>.from(data['lastMessageReadBy'] ?? const []);
    final lastMessageStatus = data['lastMessageStatus'] ??
        (lastMessageReadBy.length > 1 ? 'read' : 'sent');

    return Chat(
      id: doc.id,
      name: data['name'] ?? 'Chat',
      participants: List<String>.from(data['participants'] ?? const []),
      lastMessage: lastMessage,
      lastMessageStatus: lastMessageStatus,
      lastMessageTime: _readDate(lastMessageAt),
      lastMessageType: lastMessageType,
      lastSenderId: data['lastSenderId'],
      lastMessageId: data['lastMessageId'],
      lastMessageReadBy: lastMessageReadBy,
      isGroup: data['isGroup'] ?? false,
      admins: List<String>.from(data['admins'] ?? const []),
      groupName: data['groupName'],
    );
  }

  @override
  String toString() {
    return 'Chat{id: $id, name: $name, participants: $participants}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageStatus': lastMessageStatus,
      'lastMessageTime': lastMessageTime.toString(),
      'lastMessageType': lastMessageType,
      'lastSenderId': lastSenderId,
      'lastMessageId': lastMessageId,
      'lastMessageReadBy': lastMessageReadBy,
      'isGroup': isGroup,
      'admins': admins,
      'groupName': groupName,
    };
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now().subtract(const Duration(days: 365));
  }

  static String _previewText(String text, String type) {
    if (text.isNotEmpty) return text;
    switch (type) {
      case 'image':
        return 'Фото';
      case 'sticker':
        return 'Стикер';
      case 'voice':
        return 'Голосовое сообщение';
      default:
        return 'Сообщений пока нет';
    }
  }
}
