class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final List<String> participants;

  Chat(
      {required this.id,
      required this.name,
      required this.lastMessage,
      required this.time,
      required this.unread,
      required this.participants});
}
