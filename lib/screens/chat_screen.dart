import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String language;

  ChatScreen({required this.language});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  late String _currentLanguage;

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'type_message': 'Введите сообщение...',
    },
    'en': {
      'type_message': 'Type a message...',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;

    _messages.addAll([
      Message(
          text: 'Привет! Как дела?',
          isMe: false,
          time: DateTime.now().subtract(Duration(minutes: 5))),
      Message(
          text: 'Привет! Всё отлично, а у тебя?',
          isMe: true,
          time: DateTime.now().subtract(Duration(minutes: 4))),
      Message(
          text: 'Тоже всё хорошо! Что нового?',
          isMe: false,
          time: DateTime.now().subtract(Duration(minutes: 3))),
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
      ));
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizations[_currentLanguage]!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('U', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 12),
            Text('Другой пользователь'),
          ],
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Text(
              _currentLanguage == 'ru' ? 'EN' : 'RU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: _switchLanguage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
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
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: texts['type_message']!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
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
              color: message.isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isMe ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: message.isMe ? Colors.white70 : Colors.grey[600],
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

class Message {
  final String text;
  final bool isMe;
  final DateTime time;

  Message({required this.text, required this.isMe, required this.time});
}
