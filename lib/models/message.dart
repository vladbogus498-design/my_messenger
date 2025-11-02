import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type; // 'text', 'image', 'voice', 'sticker'
  final String? imageUrl;
  final String? voiceAudioBase64; // base64 закодированное голосовое сообщение
  final int? voiceDuration; // длительность голосового сообщения в секундах
  final String? stickerId; // ID стикера
  final bool isEncrypted; // флаг шифрования
  final DateTime timestamp;
  final String? replyToId;
  final String? replyToText;
  final bool isForwarded;
  final String? originalSender;
  final Map<String, String> reactions; // реакции: {userId: emoji}
  final bool isTyping; // статус "печатает"
  final String status; // 'sent', 'delivered', 'read' - статус прочтения

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    this.imageUrl,
    this.voiceAudioBase64,
    this.voiceDuration,
    this.stickerId,
    this.isEncrypted = false,
    required this.timestamp,
    this.replyToId,
    this.replyToText,
    this.isForwarded = false,
    this.originalSender,
    this.reactions = const {},
    this.isTyping = false,
    this.status = 'sent',
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      voiceAudioBase64: data['voiceAudioBase64'],
      voiceDuration: data['voiceDuration'],
      stickerId: data['stickerId'],
      isEncrypted: data['isEncrypted'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      isForwarded: data['isForwarded'] ?? false,
      originalSender: data['originalSender'],
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      isTyping: data['isTyping'] ?? false,
      status: data['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      if (voiceAudioBase64 != null) 'voiceAudioBase64': voiceAudioBase64,
      if (voiceDuration != null) 'voiceDuration': voiceDuration,
      if (stickerId != null) 'stickerId': stickerId,
      'isEncrypted': isEncrypted,
      'timestamp': timestamp,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'isForwarded': isForwarded,
      'originalSender': originalSender,
      'reactions': reactions,
      'isTyping': isTyping,
      'status': status,
    };
  }

  // Метод для добавления реакции
  Message copyWithReaction(String userId, String emoji) {
    final newReactions = Map<String, String>.from(reactions);
    if (newReactions[userId] == emoji) {
      newReactions.remove(userId); // убираем реакцию если уже есть
    } else {
      newReactions[userId] = emoji; // добавляем/меняем реакцию
    }
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: type,
      imageUrl: imageUrl,
      timestamp: timestamp,
      replyToId: replyToId,
      replyToText: replyToText,
      isForwarded: isForwarded,
      originalSender: originalSender,
      reactions: newReactions,
      isTyping: isTyping,
      status: status,
      voiceAudioBase64: voiceAudioBase64,
      voiceDuration: voiceDuration,
      stickerId: stickerId,
      isEncrypted: isEncrypted,
    );
  }
}
