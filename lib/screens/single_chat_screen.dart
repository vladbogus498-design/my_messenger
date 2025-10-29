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

  // ДЕМО-СООБЩЕНИЯ ДЛЯ КАЖДОГО ЧАТА
  final Map<String, List<Map<String, String>>> _demoMessages = {
    '1': [
      // DarkKick Team
      {
        'text': 'Welcome to DarkKick! 🚀',
        'sender': 'system',
        'time': '2 min ago'
      },
      {
        'text': 'Messages here self-destruct automatically!',
        'sender': 'dev',
        'time': '1 min ago'
      },
      {
        'text': 'Try sending a message below!',
        'sender': 'system',
        'time': 'now'
      },
    ],
    '2': [
      // Flutter Developers
      {
        'text': 'This is where real messages will appear!',
        'sender': 'flutter_bot',
        'time': '5 min ago'
      },
      {
        'text': 'You can type below and see it here',
        'sender': 'system',
        'time': '3 min ago'
      },
      {
        'text': 'Firebase integration is ready!',
        'sender': 'firebase_dev',
        'time': '1 min ago'
      },
    ],
    '3': [
      // Secret Group
      {
        'text': 'Mission: Create the best messenger!',
        'sender': 'agent1',
        'time': '10 min ago'
      },
      {
        'text': 'Self-destruct feature coming soon...',
        'sender': 'agent2',
        'time': '8 min ago'
      },
      {
        'text': 'Stay tuned for updates!',
        'sender': 'admin',
        'time': '5 min ago'
      },
    ],
    '4': [
      // Ephemeral Chat
      {
        'text': 'This message will disappear in 5...4...3...',
        'sender': 'system',
        'time': '1 min ago'
      },
      {
        'text': 'Ephemeral messaging - no traces left!',
        'sender': 'privacy_bot',
        'time': '30 sec ago'
      },
      {
        'text': 'Your privacy is protected here',
        'sender': 'system',
        'time': 'now'
      },
    ],
  };

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
          'timestamp': DateTime.now(),
          'type': 'text',
        });

        // Обновляем последнее сообщение в чате
        await _firestore.collection('chats').doc(widget.chatId).update({
          'lastMessage': message,
          'lastMessageTime': DateTime.now(),
        });

        _messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoMessages = _demoMessages[widget.chatId] ??
        [
          {'text': 'Start the conversation!', 'sender': 'system', 'time': 'now'}
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                reverse: false,
                itemCount: demoMessages.length,
                itemBuilder: (context, index) {
                  final message = demoMessages[index];
                  final isSystem = message['sender'] == 'system';

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isSystem
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!isSystem) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              message['sender']![0].toUpperCase(),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSystem
                                  ? Colors.grey[800]
                                  : Colors.deepPurple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isSystem)
                                  Text(
                                    message['sender']!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  message['text']!,
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  message['time']!,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
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
}
