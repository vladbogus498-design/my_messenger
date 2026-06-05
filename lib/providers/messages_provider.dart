import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, chatId) {
      final userId = ref
          .watch(authStateProvider)
          .maybeWhen(data: (user) => user?.uid, orElse: () => null);
      if (userId == null || userId.isEmpty || chatId.isEmpty) {
        return Stream.value(const <Message>[]);
      }

      final firestore = FirebaseFirestore.instance;
      return firestore.collection('chats').doc(chatId).snapshots().asyncExpand((
        chatDoc,
      ) {
        final participants = List<String>.from(
          chatDoc.data()?['participants'] ?? const [],
        );
        if (!chatDoc.exists || !participants.contains(userId)) {
          return Stream.value(const <Message>[]);
        }

        return firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots()
            .asyncMap((snapshot) async {
              final messages = <Message>[];
              for (final doc in snapshot.docs) {
                messages.add(
                  await ChatService.messageFromFirestoreData(
                    chatId: chatId,
                    messageId: doc.id,
                    data: doc.data(),
                  ),
                );
              }
              return messages;
            });
      });
    });
