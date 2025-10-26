class Chat {
  final String id;
  final String name;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      name: map['name'] ?? 'Chat',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }
}
