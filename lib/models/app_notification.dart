class AppNotification {
  final String id;
  final String type; // e.g., message, mention, friend_request
  final String targetUser; // user id
  final String? message; // optional content
  final String? chatId; // chat related

  AppNotification({
    required this.id,
    required this.type,
    required this.targetUser,
    this.message,
    this.chatId,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: data['type'] ?? 'message',
      targetUser: data['targetUser'] ?? '',
      message: data['message'],
      chatId: data['chatId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetUser': targetUser,
      'message': message,
      'chatId': chatId,
    };
  }
}
