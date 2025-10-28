class Chat {
  final String id;
  final String name;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageStatus;
  final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageStatus,
    required this.lastMessageTime,
  });

  @override
  String toString() {
    return 'Chat{id: $id, name: $name, participants: $participants}';
  }
}
