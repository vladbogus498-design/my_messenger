import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatService {
  static final _fs = FirebaseFirestore.instance;

  static Future<String> createGroup(
      {required String name,
      required List<String> participantIds,
      required String creatorId}) async {
    final doc = await _fs.collection('chats').add({
      'name': name,
      'groupName': name,
      'isGroup': true,
      'participants': participantIds,
      'admins': [creatorId],
      'lastMessage': '',
      'lastMessageStatus': 'sent',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return doc.id;
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
