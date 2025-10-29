import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SingleChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  SingleChatScreen({required this.chatId, required this.chatName});

  @override
  _SingleChatScreenState createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': message,
          'senderId': user.uid,
          'senderName': user.email?.split('@').first ?? 'You',
          'timestamp': Timestamp.now(),
          'type': 'text',
        });

        // Обновляем последнее сообщение в чате
        await _firestore.collection('chats').doc(widget.chatId).update({
          'lastMessage': message,
          'lastMessageTime': Timestamp.now(),
        });

        _messageController.clear();

        // Прокрутка вниз после отправки
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return Container(
                  color: Colors.grey[900],
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    reverse: true, // Новые сообщения внизу
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final data = message.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == user?.uid;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  data['senderName']?[0].toUpperCase() ?? '?',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.deepPurple
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        data['senderName'] ?? 'Unknown',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    Text(
                                      data['text'] ?? '',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTime(data['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.green,
                                child: Text(
                                  'You'[0],
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Input Field
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[700],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
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
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'now';

    try {
      final time = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) return 'now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'now';
    }
  }
}
