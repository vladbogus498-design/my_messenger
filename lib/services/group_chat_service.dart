import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatService {
  static final _fs = FirebaseFirestore.instance;

  static Future<String> createGroup({
    required String name,
    required List<String> participantIds,
    required String creatorId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final docRef = await _fs.collection('chats').add({
      'name': name,
      'groupName': name,
      'type': 'group',
      'isGroup': true,
      'participants': participantIds,
      'admins': [creatorId],
      'lastMessage': 'Группа создана',
      'lastMessageStatus': 'sent',
      'lastMessageTime': now,
      'createdAt': now,
      'createdBy': creatorId,
      'avatarUrl': null,
    });
    await docRef.collection('messages').add({
      'text': 'Группа "$name" создана',
      'type': 'system',
      'senderId': creatorId,
      'timestamp': now,
      'status': 'delivered',
    });
    return docRef.id;
  }

  static Future<void> addParticipants(
      String chatId, List<String> userIds) async {
    await _fs.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion(userIds),
    });
  }

  static Future<void> setAdmins(String chatId, List<String> adminIds) async {
    await _fs.collection('chats').doc(chatId).update({'admins': adminIds});
  }
}
