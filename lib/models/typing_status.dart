/// Модель для статусов активности пользователей в чате
class TypingStatus {
  final List<String> typingUsers;
  final List<String> sendingPhotoUsers;
  final List<String> recordingVoiceUsers;

  TypingStatus({
    required this.typingUsers,
    required this.sendingPhotoUsers,
    required this.recordingVoiceUsers,
  });

  bool get hasAnyActivity =>
      typingUsers.isNotEmpty ||
      sendingPhotoUsers.isNotEmpty ||
      recordingVoiceUsers.isNotEmpty;
}

