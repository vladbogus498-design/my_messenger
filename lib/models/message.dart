import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    this.imageUrl,
    this.stickerUrl,
    this.voiceUrl,
    this.voiceAudioBase64,
    this.voiceDuration,
    this.stickerId,
    this.isEncrypted = false,
    this.replyTo,
    this.replyToId,
    this.replyToText,
    this.isForwarded = false,
    this.originalSender,
    this.reactions = const {},
    this.isTyping = false,
    this.status = 'sent',
    this.readBy = const [],
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final String? imageUrl;
  final String? stickerUrl;
  final String? voiceUrl;
  final String? voiceAudioBase64;
  final int? voiceDuration;
  final String? stickerId;
  final bool isEncrypted;

  // Backward compatible name used by the current UI.
  final DateTime timestamp;
  DateTime get createdAt => timestamp;

  final Map<String, dynamic>? replyTo;
  final String? replyToId;
  final String? replyToText;
  final bool isForwarded;
  final String? originalSender;
  final Map<String, String> reactions;
  final bool isTyping;
  final String status;
  final List<String> readBy;

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    final createdAt = data['createdAt'] ?? data['timestamp'];
    final replyTo = data['replyTo'] == null
        ? null
        : Map<String, dynamic>.from(data['replyTo']);
    final type = (data['type'] ?? 'text').toString();
    final imageUrl =
        _readString(data, const [
          'imageUrl',
          'imageURL',
          'photoUrl',
          'photoURL',
          'mediaUrl',
          'downloadUrl',
          'secureUrl',
        ]) ??
        (_isImageType(type)
            ? _readString(data, const ['fileUrl', 'url'])
            : null);

    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: type,
      imageUrl: imageUrl,
      stickerUrl: _readString(data, const [
        'stickerUrl',
        'stickerURL',
        'stickerId',
      ]),
      voiceUrl: _readString(data, const ['voiceUrl', 'audioUrl']),
      voiceAudioBase64: data['voiceAudioBase64'],
      voiceDuration: data['voiceDuration'],
      stickerId: data['stickerId'],
      isEncrypted: data['isEncrypted'] ?? false,
      timestamp: _readDate(createdAt),
      replyTo: replyTo,
      replyToId: data['replyToId'] ?? replyTo?['id'],
      replyToText: data['replyToText'] ?? replyTo?['text'],
      isForwarded: data['isForwarded'] ?? false,
      originalSender: data['originalSender'],
      reactions: Map<String, String>.from(data['reactions'] ?? const {}),
      isTyping: data['isTyping'] ?? false,
      status: data['status'] ?? 'sent',
      readBy: List<String>.from(data['readBy'] ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
      if (voiceUrl != null) 'voiceUrl': voiceUrl,
      if (voiceDuration != null) 'voiceDuration': voiceDuration,
      if (stickerId != null) 'stickerId': stickerId,
      'isEncrypted': isEncrypted,
      'timestamp': timestamp,
      'createdAt': timestamp,
      if (replyTo != null) 'replyTo': replyTo,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      'isForwarded': isForwarded,
      if (originalSender != null) 'originalSender': originalSender,
      'reactions': reactions,
      'isTyping': isTyping,
      'status': status,
      'readBy': readBy,
    };
  }

  Message copyWithReaction(String userId, String emoji) {
    final newReactions = Map<String, String>.from(reactions);
    if (newReactions[userId] == emoji) {
      newReactions.remove(userId);
    } else {
      newReactions[userId] = emoji;
    }

    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: type,
      imageUrl: imageUrl,
      stickerUrl: stickerUrl,
      voiceUrl: voiceUrl,
      voiceAudioBase64: voiceAudioBase64,
      voiceDuration: voiceDuration,
      stickerId: stickerId,
      isEncrypted: isEncrypted,
      timestamp: timestamp,
      replyTo: replyTo,
      replyToId: replyToId,
      replyToText: replyToText,
      isForwarded: isForwarded,
      originalSender: originalSender,
      reactions: newReactions,
      isTyping: isTyping,
      status: status,
      readBy: readBy,
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _isImageType(String type) {
    final normalized = type.toLowerCase().trim();
    return normalized == 'image' || normalized == 'photo';
  }
}
