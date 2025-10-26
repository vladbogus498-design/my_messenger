import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setTypingStatus(false);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setTypingStatus(bool isTyping) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'typingStatus': isTyping ? 'typing' : null,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _onTextChanged(String text) {
    _typingTimer?.cancel();
    _setTypingStatus(true);

    _typingTimer = Timer(Duration(seconds: 2), () {
      _setTypingStatus(false);
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .update({
        'lastMessage': _messageController.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _setTypingStatus(false);
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
    }
  }

  Future<void> _sendImage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final currentUserId = FirebaseAuth.instance.currentUser!.uid;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'typingStatus': 'sending_photo',
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .collection('messages')
            .add({
          'text': languageProvider.currentLanguage == 'ru'
              ? '📷 [Изображение]'
              : '📷 [Image]',
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'image',
          'isRead': false,
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .update({
          'lastMessage': languageProvider.currentLanguage == 'ru'
              ? '📷 Изображение'
              : '📷 Image',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'typingStatus': null,
        });
      }
    } catch (e) {
      print('Ошибка отправки изображения: $e');
    }
  }

  Future<void> _sendVoiceMessage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'typingStatus': 'sending_voice',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .collection('messages')
          .add({
        'text': languageProvider.currentLanguage == 'ru'
            ? '🎤 [Голосовое сообщение]'
            : '🎤 [Voice message]',
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'voice',
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .update({
        'lastMessage': languageProvider.currentLanguage == 'ru'
            ? '🎤 Голосовое сообщение'
            : '🎤 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'typingStatus': null,
      });
    } catch (e) {
      print('Ошибка отправки голосового сообщения: $e');
    }
  }

  void _viewUserProfile(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final userProfile = UserProfile.fromMap(userDoc.data()!);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(userProfile.username),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFDC143C),
                  child: userProfile.avatarUrl.isNotEmpty
                      ? ClipOval(child: Image.network(userProfile.avatarUrl))
                      : Text(userProfile.username[0].toUpperCase(),
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
                SizedBox(height: 16),
                Text(userProfile.email, style: TextStyle(fontSize: 16)),
                if (userProfile.bio.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(userProfile.bio,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ),
                SizedBox(height: 8),
                Text(
                  'Online: ${userProfile.isOnline ? 'Да' : 'Нет'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
    }
  }

  Widget _buildMessageContent(Message message) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    switch (message.type) {
      case 'image':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo,
                color: message.isMe ? Colors.white : Colors.black),
            SizedBox(width: 8),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? '📷 Изображение'
                    : '📷 Image',
                style: TextStyle(
                  fontSize: 16,
                  color: message.isMe ? Colors.white : Colors.black,
                )),
          ],
        );
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, color: message.isMe ? Colors.white : Colors.black),
            SizedBox(width: 8),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? '🎤 Голосовое'
                    : '🎤 Voice',
                style: TextStyle(
                  fontSize: 16,
                  color: message.isMe ? Colors.white : Colors.black,
                )),
          ],
        );
      default:
        return Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            color: message.isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            final otherUserId = widget.chat.participants
                .firstWhere((id) => id != currentUserId, orElse: () => '');
            if (otherUserId.isNotEmpty) {
              _viewUserProfile(otherUserId);
            }
          },
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Color(0xFFDC143C),
              child: Text(widget.chat.name[0],
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.name),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.chat.participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => ''))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final typingStatus = userData?['typingStatus'];
                      final isOnline = userData?['isOnline'] ?? false;

                      if (typingStatus == 'typing') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'печатает...'
                              : 'typing...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else if (typingStatus == 'sending_photo') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'отправляет фото...'
                              : 'sending photo...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else if (typingStatus == 'sending_voice') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'отправляет голосовое...'
                              : 'sending voice...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else {
                        return Text(
                          isOnline
                              ? (languageProvider.currentLanguage == 'ru'
                                  ? 'онлайн'
                                  : 'online')
                              : (languageProvider.currentLanguage == 'ru'
                                  ? 'офлайн'
                                  : 'offline'),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                    }
                    return SizedBox();
                  },
                ),
              ],
            ),
          ]),
        ),
        backgroundColor: Color(0xFF8B0000),
        actions: [
          PopupMenuButton<String>(
            onSelected: (language) => languageProvider.setLanguage(language),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            ],
            icon: Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chat.id)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(languageProvider.currentLanguage == 'ru'
                            ? 'Ошибка загрузки сообщений'
                            : 'Error loading messages'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    return Message(
                      id: doc.id,
                      text: data['text'] ?? '',
                      isMe: data['senderId'] == currentUserId,
                      time: _formatTime(data['timestamp']),
                      senderId: data['senderId'] ?? '',
                      type: data['type'] ?? 'text',
                      isRead: data['isRead'] ?? false,
                    );
                  }).toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final unreadMessages =
                        messages.where((msg) => !msg.isMe && !msg.isRead);
                    for (final msg in unreadMessages) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chat.id)
                          .collection('messages')
                          .doc(msg.id)
                          .update({'isRead': true});
                    }
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return GestureDetector(
                        onTap: () {
                          if (!message.isMe) {
                            _viewUserProfile(message.senderId);
                          }
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: message.isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: message.isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: message.isMe
                                        ? Color(0xFFDC143C)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: _buildMessageContent(message),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(message.time,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    if (message.isMe) ...[
                                      SizedBox(width: 4),
                                      Icon(
                                        message.isRead
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 12,
                                        color: message.isRead
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.photo_camera, color: Color(0xFFDC143C)),
                    onPressed: _sendImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: Color(0xFFDC143C)),
                    onPressed: _sendVoiceMessage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: languageProvider.currentLanguage == 'ru'
                            ? 'Написать сообщение...'
                            : 'Write a message...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color(0xFFDC143C),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
