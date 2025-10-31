import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../models/message.dart';
import 'chat_input_panel.dart';

class SingleChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const SingleChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
  }) : super(key: key);

  @override
  _SingleChatScreenState createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  final _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // DEMO MESSAGES
  final List<Message> _demoMessages = [
    Message(
      id: '1',
      chatId: '1',
      senderId: 'dev',
      text: 'Welcome to DarkKick! 🔥',
      timestamp: DateTime.now().subtract(Duration(minutes: 2)),
      type: 'text',
    ),
    Message(
      id: '2',
      chatId: '1',
      senderId: 'you',
      text: 'This is amazing!',
      timestamp: DateTime.now().subtract(Duration(minutes: 1)),
      type: 'text',
    ),
    Message(
      id: '3',
      chatId: '1',
      senderId: 'dev',
      text: 'Try the self-destruct feature! 💣',
      timestamp: DateTime.now(),
      type: 'text',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    print('🔄 Loading messages for chat ${widget.chatId}...');
    setState(() => _isLoading = true);

    try {
      final firebaseMessages = await ChatService.getChatMessages(widget.chatId);

      // Combine demo messages with Firebase messages
      setState(() {
        _messages = [..._demoMessages, ...firebaseMessages];
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print('✅ Loaded ${_messages.length} messages');
    } catch (e) {
      // If Firebase fails, use only demo messages
      setState(() {
        _messages = _demoMessages;
        _isLoading = false;
      });
      print('⚠️ Using demo messages: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 📨 Send text message
  Future<void> _sendTextMessage(String text, String type) async {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatId,
      senderId: _currentUser?.uid ?? 'you',
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: text,
        type: type,
      );
      print('✅ Text message sent');
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🖼️ Send image message
  Future<void> _sendImageMessage(String imageUrl) async {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatId,
      senderId: _currentUser?.uid ?? 'you',
      text: '[Photo]',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      type: 'image',
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: '[Photo]',
        type: 'image',
        imageUrl: imageUrl,
      );
      print('✅ Image message sent');
    } catch (e) {
      print('❌ Error sending image message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 👤 Get message alignment and color
  bool _isMyMessage(String senderId) {
    return senderId == _currentUser?.uid || senderId == 'you';
  }

  // 🎨 Message bubble widget
  Widget _buildMessageBubble(Message message) {
    final isMyMessage = _isMyMessage(message.senderId);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.deepPurple : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image message
                  if (message.type == 'image' && message.imageUrl != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[700],
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),

                  // Text content
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                  // Timestamp
                  SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepPurple))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
            ),

            // Input panel
            ChatInputPanel(
              chatId: widget.chatId,
              currentUserId: _currentUser?.uid ?? 'you',
              onSendMessage: _sendTextMessage,
              onImageUpload: _sendImageMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
