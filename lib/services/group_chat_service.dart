import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';

class GroupChatService {
  static final _fs = FirebaseFirestore.instance;

  static Future<Chat> createGroup({
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
      'participants': participantIds, // Все участники добавлены
      'admins': [creatorId],
      'lastMessage': {
        'text': 'Группа создана',
        'timestamp': now,
      },
      'lastMessageStatus': 'sent',
      'lastMessageTime': now, // Для обратной совместимости
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
    
    // Fetch the created document to return as Chat object
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Failed to create group chat');
    }
    // Convert DocumentSnapshot to QueryDocumentSnapshot-like structure
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      name: data['name'] ?? 'Chat',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageStatus: data['lastMessageStatus'] ?? 'sent',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      admins: List<String>.from(data['admins'] ?? const []),
      groupName: data['groupName'],
    );
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
