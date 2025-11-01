import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Message? _replyingTo;
  Message? _forwardingMessage;
  final TextEditingController _typingController = TextEditingController();
  List<String> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupTypingListener();
    _setupTypingDetection();
  }

  void _setupTypingListener() {
    ChatService.getTypingUsers(widget.chatId).listen((typingUsers) {
      if (mounted) {
        setState(() {
          _typingUsers =
              typingUsers.where((id) => id != _currentUser?.uid).toList();
        });
      }
    });
  }

  void _setupTypingDetection() {
    _typingController.addListener(() {
      final isTyping = _typingController.text.isNotEmpty;
      ChatService.setTypingStatus(widget.chatId, isTyping);
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await ChatService.getChatMessages(widget.chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _startReply(Message message) {
    setState(() {
      _replyingTo = message;
      _forwardingMessage = null;
    });
  }

  void _startForward(Message message) {
    setState(() {
      _forwardingMessage = message;
      _replyingTo = null;
    });
  }

  void _cancelAction() {
    setState(() {
      _replyingTo = null;
      _forwardingMessage = null;
    });
  }

  Future<void> _sendTextMessage(String text, String type) async {
    if (text.trim().isEmpty) return;
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: text,
        type: type,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
      );
      setState(() => _replyingTo = null);
      _loadMessages();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: '[Photo]',
        type: 'image',
        imageUrl: imageUrl,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
      );
      setState(() => _replyingTo = null);
      _loadMessages();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _forwardMessage() async {
    if (_forwardingMessage == null) return;

    try {
      await ChatService.forwardMessage(_forwardingMessage!, widget.chatId);
      setState(() => _forwardingMessage = null);
      _loadMessages();
    } catch (e) {
      print('Error forwarding: $e');
    }
  }

  Future<void> _addReaction(Message message, String emoji) async {
    await ChatService.addReaction(widget.chatId, message.id, emoji);
    _loadMessages();
  }

  bool _isMyMessage(String senderId) {
    return senderId == _currentUser?.uid;
  }

  Widget _buildReactions(Message message) {
    if (message.reactions.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((entry) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.value,
              style: TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionPreview() {
    if (_replyingTo != null) {
      return _buildReplyPreview(_replyingTo!);
    } else if (_forwardingMessage != null) {
      return _buildForwardPreview(_forwardingMessage!);
    }
    return SizedBox();
  }

  Widget _buildReplyPreview(Message replyTo) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: Colors.grey, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ответ на сообщение',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  replyTo.text.length > 30
                      ? '${replyTo.text.substring(0, 30)}...'
                      : replyTo.text,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: _cancelAction,
          ),
        ],
      ),
    );
  }

  Widget _buildForwardPreview(Message forwardMessage) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue[800]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.forward, color: Colors.blue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Переслать сообщение',
                    style: TextStyle(color: Colors.blue, fontSize: 12)),
                Text(
                  forwardMessage.text.length > 30
                      ? '${forwardMessage.text.substring(0, 30)}...'
                      : forwardMessage.text,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: _cancelAction,
          ),
          ElevatedButton(
            onPressed: _forwardMessage,
            child: Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Text(
            'Печатает...',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          SizedBox(width: 8),
          CircularProgressIndicator(strokeWidth: 2, value: null),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMyMessage = _isMyMessage(message.senderId);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Пересланное сообщение
                if (message.isForwarded) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.forward, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Переслано',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
                GestureDetector(
                  onLongPress: () => _showMessageMenu(message),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMyMessage ? Colors.deepPurple : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply preview
                        if (message.replyToText != null) ...[
                          Container(
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(color: Colors.blue, width: 3),
                              ),
                            ),
                            child: Text(
                              message.replyToText!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],

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
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),

                        // Text content
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(color: Colors.white),
                          ),

                        // Timestamp
                        SizedBox(height: 4),
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Реакции
                _buildReactions(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Ответить'),
              onTap: () {
                Navigator.pop(context);
                _startReply(message);
              },
            ),
            ListTile(
              leading: Icon(Icons.forward),
              title: Text('Переслать'),
              onTap: () {
                Navigator.pop(context);
                _startForward(message);
              },
            ),
            Divider(),
            Text('Добавить реакцию:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '😮', '😢', '😠'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _addReaction(message, emoji);
                  },
                  child: Text(emoji, style: TextStyle(fontSize: 24)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName),
            if (_typingUsers.isNotEmpty)
              Text(
                'Печатает...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Action preview (reply/forward)
          _buildActionPreview(),

          ChatInputPanel(
            chatId: widget.chatId,
            currentUserId: _currentUser?.uid ?? '',
            onSendMessage: _sendTextMessage,
            onImageUpload: _sendImageMessage,
            typingController: _typingController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    ChatService.setTypingStatus(widget.chatId, false);
    super.dispose();
  }
}
