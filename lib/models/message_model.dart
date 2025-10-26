class Message {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String senderId;
  final String type;
  final bool isRead;

  Message(
      {required this.id,
      required this.text,
      required this.isMe,
      required this.time,
      required this.senderId,
      this.type = 'text',
      this.isRead = false});
}
