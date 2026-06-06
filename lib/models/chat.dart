import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  const Chat({
    required this.id,
    required this.type,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageStatus,
    required this.lastMessageTime,
    required this.updatedAt,
    this.lastMessageType = 'text',
    this.lastSenderId,
    this.lastMessageId,
    this.lastMessageReadBy = const [],
    this.unreadCount = const {},
    this.typing = const {},
    this.pinnedMessage,
    this.isGroup = false,
    this.admins = const [],
    this.groupName,
  });

  final String id;
  final String type;
  final String name;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageStatus;
  final DateTime lastMessageTime;
  final DateTime updatedAt;
  final String lastMessageType;
  final String? lastSenderId;
  final String? lastMessageId;
  final List<String> lastMessageReadBy;
  final Map<String, int> unreadCount;
  final Map<String, dynamic> typing;
  final Map<String, dynamic>? pinnedMessage;
  final bool isGroup;
  final List<String> admins;
  final String? groupName;

  bool get isDirect => type == 'direct' || !isGroup;

  String? otherParticipantId(String? currentUid) {
    if (currentUid == null) return null;
    for (final participant in participants) {
      if (participant != currentUid) return participant;
    }
    return null;
  }

  int unreadFor(String? uid) {
    if (uid == null) return 0;
    return unreadCount[uid] ?? 0;
  }

  factory Chat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawType = data['type'];
    final isGroup = data['isGroup'] == true || rawType == 'group';
    final type = (rawType ?? (isGroup ? 'group' : 'direct')).toString();
    final legacyLastMessage = data['lastMessage'];
    final rawLastMessage = legacyLastMessage is Map<String, dynamic>
        ? (legacyLastMessage['text'] ?? '').toString()
        : (legacyLastMessage ?? '').toString();
    final lastMessageType = (data['lastMessageType'] ?? 'text').toString();
    final lastMessage = _previewText(rawLastMessage, lastMessageType);
    final legacyLastMessageAt = legacyLastMessage is Map<String, dynamic>
        ? legacyLastMessage['timestamp']
        : null;
    final lastMessageAt =
        data['lastMessageAt'] ??
        data['updatedAt'] ??
        legacyLastMessageAt ??
        data['lastMessageTime'] ??
        data['createdAt'];
    final updatedAt = data['updatedAt'] ?? lastMessageAt;
    final lastMessageReadBy = _readStringList(data['lastMessageReadBy']);
    final lastMessageStatus =
        data['lastMessageStatus'] ??
        (lastMessageReadBy.length > 1 ? 'read' : 'sent');

    return Chat(
      id: doc.id,
      type: type,
      name: (data['name'] ?? 'Chat').toString(),
      participants: _readStringList(data['participants']),
      lastMessage: lastMessage,
      lastMessageStatus: lastMessageStatus,
      lastMessageTime: _readDate(lastMessageAt),
      updatedAt: _readDate(updatedAt),
      lastMessageType: lastMessageType,
      lastSenderId: data['lastSenderId'],
      lastMessageId: data['lastMessageId'],
      lastMessageReadBy: lastMessageReadBy,
      unreadCount: _readUnreadCount(data['unreadCount']),
      typing: Map<String, dynamic>.from(data['typing'] ?? const {}),
      pinnedMessage: data['pinnedMessage'] is Map
          ? Map<String, dynamic>.from(data['pinnedMessage'] as Map)
          : null,
      isGroup: isGroup,
      admins: _readStringList(data['admins']),
      groupName: data['groupName'],
    );
  }

  @override
  String toString() {
    return 'Chat{id: $id, type: $type, participants: $participants}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageStatus': lastMessageStatus,
      'lastMessageTime': lastMessageTime.toString(),
      'lastMessageType': lastMessageType,
      'lastSenderId': lastSenderId,
      'lastMessageId': lastMessageId,
      'lastMessageReadBy': lastMessageReadBy,
      'unreadCount': unreadCount,
      'typing': typing,
      'pinnedMessage': pinnedMessage,
      'updatedAt': updatedAt.toString(),
      'isGroup': isGroup,
      'admins': admins,
      'groupName': groupName,
    };
  }

  static Map<String, int> _readUnreadCount(dynamic value) {
    if (value is! Map) return const {};
    final raw = Map<String, dynamic>.from(value);
    return raw.map((key, value) {
      final count = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      return MapEntry(key, count);
    });
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
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
