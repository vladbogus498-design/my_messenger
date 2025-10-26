import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String language;
  final UserModel otherUser;
  final String chatId;

  const ChatScreen({
    required this.language,
    required this.otherUser,
    required this.chatId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
    print('💬 Чат открыт: ${widget.chatId}');
  }

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    print('📤 Отправка сообщения: "$text" в чат ${widget.chatId}');
    _chatService.sendMessage(widget.chatId, text);
    _messageController.clear();
  }

  void _showProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          user: widget.otherUser,
          language: _currentLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showProfile,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red,
                child: Text(
                  widget.otherUser.name[0],
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: TextStyle(fontSize: 16)),
                  Text('online',
                      style: TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Text(_currentLanguage == 'ru' ? 'EN' : 'RU',
                style: TextStyle(color: Colors.red)),
            onPressed: _switchLanguage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: StreamBuilder(
                stream: _chatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('❌ Ошибка сообщений: ${snapshot.error}');
                    return Center(
                      child: Text('Ошибка загрузки сообщений',
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: Colors.red));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет сообщений\nНачните общение!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;
                  print('📨 Загружено сообщений: ${messages.length}');
                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages.reversed.toList()[index];
                      final data = message.data() as Map<String, dynamic>;
                      final isMe =
                          data['senderId'] == _chatService.getCurrentUserId();

                      return _buildMessageBubble(
                        data['text'] ?? '',
                        isMe,
                        data['timestamp']?.toDate() ?? DateTime.now(),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo_camera, color: Colors.red),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.red),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _currentLanguage == 'ru'
                          ? 'Введите сообщение...'
                          : 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.red,
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

  Widget _buildMessageBubble(String text, bool isMe, DateTime time) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.red : Colors.grey[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: Colors.white)),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6),
                      Icon(Icons.done_all, size: 12, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
