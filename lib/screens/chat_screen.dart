import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'profile_screen.dart';
import '../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String language;
  final UserModel otherUser; // добавляем получателя

  ChatScreen({required this.language, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;

    // Тестовые сообщения со статусами
    _messages.addAll([
      Message(
          text: 'Привет! Как дела?',
          isMe: false,
          time: DateTime.now().subtract(Duration(minutes: 5)),
          status: MessageStatus.read),
      Message(
          text: 'Привет! Всё отлично, а у тебя?',
          isMe: true,
          time: DateTime.now().subtract(Duration(minutes: 4)),
          status: MessageStatus.read),
      Message(
          text: 'Тоже всё хорошо! Что нового?',
          isMe: false,
          time: DateTime.now().subtract(Duration(minutes: 3)),
          status: MessageStatus.delivered),
      Message(
          text: 'Сегодня кодил новый мессенджер!',
          isMe: true,
          time: DateTime.now().subtract(Duration(minutes: 2)),
          status: MessageStatus.sent),
    ]);
  }

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: _messageController.text,
        isMe: true,
        time: DateTime.now(),
        status: MessageStatus.sent,
      ));
    });

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

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.check, size: 12, color: Colors.grey);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 12, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 12, color: Colors.blue);
    }
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
                child: Text(widget.otherUser.name[0],
                    style: TextStyle(color: Colors.white)),
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
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages.reversed.toList()[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),

          // ПАНЕЛЬ ВВОДА С ИКОНКАМИ
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              children: [
                // ИКОНКА ФОТО
                IconButton(
                  icon: Icon(Icons.photo_camera, color: Colors.red),
                  onPressed: () {},
                ),
                // ИКОНКА ГОЛОСОВОГО
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

  Widget _buildMessageBubble(Message message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? Colors.red : Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    if (message.isMe) ...[
                      SizedBox(width: 6),
                      _buildStatusIcon(message.status),
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

class Message {
  final String text;
  final bool isMe;
  final DateTime time;
  final MessageStatus status;

  Message(
      {required this.text,
      required this.isMe,
      required this.time,
      required this.status});
}
