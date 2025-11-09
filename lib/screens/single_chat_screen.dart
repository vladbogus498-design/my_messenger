import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../services/voice_message_service.dart';
import '../models/message.dart';
import '../models/chat.dart';
import 'chat_input_panel.dart';
import 'user_profile_screen.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/message_status_icon.dart';
import '../utils/time_formatter.dart';
import '../utils/navigation_animations.dart';

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
  List<String> _sendingPhotoUsers = [];
  List<String> _recordingVoiceUsers = [];
  String? _playingVoiceMessageId;
  Timer? _playbackCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupTypingListener();
    _setupTypingDetection();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    // Отмечаем все сообщения как прочитанные при открытии чата
    await ChatService.markAllMessagesAsRead(widget.chatId);
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

    ChatService.getSendingPhotoUsers(widget.chatId).listen((sendingPhotoUsers) {
      if (mounted) {
        setState(() {
          _sendingPhotoUsers =
              sendingPhotoUsers.where((id) => id != _currentUser?.uid).toList();
        });
      }
    });

    ChatService.getRecordingVoiceUsers(widget.chatId)
        .listen((recordingVoiceUsers) {
      if (mounted) {
        setState(() {
          _recordingVoiceUsers = recordingVoiceUsers
              .where((id) => id != _currentUser?.uid)
              .toList();
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
        encrypt: false, // Можно добавить опцию шифрования
      );

      await ChatService.setSendingPhotoStatus(widget.chatId, false);
      setState(() => _replyingTo = null);
      _loadMessages();
    } catch (e) {
      print('Error: $e');
      await ChatService.setSendingPhotoStatus(widget.chatId, false);
    }
  }

  Future<void> _sendVoiceMessage(
      String base64Audio, int durationSeconds) async {
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: '🎤 Голосовое сообщение',
        type: 'voice',
        voiceAudioBase64: base64Audio,
        voiceDuration: durationSeconds,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
      );

      setState(() => _replyingTo = null);
      _loadMessages();
    } catch (e) {
      print('Error sending voice message: $e');
    }
  }

  Future<void> _sendSticker(String stickerId) async {
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: '',
        type: 'sticker',
        stickerId: stickerId,
      );

      _loadMessages();
    } catch (e) {
      print('Error sending sticker: $e');
    }
  }

  Future<void> _playVoiceMessage(Message message) async {
    if (message.voiceAudioBase64 == null) return;

    final messageId = message.id;

    // Если уже воспроизводится этот же файл - останавливаем
    if (_playingVoiceMessageId == messageId &&
        VoiceMessageService.isPlayingMessage(messageId)) {
      await VoiceMessageService.stopPlaying();
      setState(() => _playingVoiceMessageId = null);
      return;
    }

    // Останавливаем предыдущее воспроизведение
    if (_playingVoiceMessageId != null) {
      await VoiceMessageService.stopPlaying();
    }

    setState(() => _playingVoiceMessageId = messageId);
    await VoiceMessageService.playVoiceMessage(
        message.voiceAudioBase64!, messageId);

    // Обновляем состояние после завершения воспроизведения
    // Слушаем изменения статуса через периодическую проверку
    _playbackCheckTimer?.cancel();
    _playbackCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!VoiceMessageService.isPlayingMessage(messageId)) {
        timer.cancel();
        _playbackCheckTimer = null;
        if (mounted) {
          setState(() {
            if (_playingVoiceMessageId == messageId) {
              _playingVoiceMessageId = null;
            }
          });
        }
      }
    });
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

  // Удалено - используем виджет MessageStatusIcon

  Widget _buildReactions(Message message) {
    if (message.reactions.isEmpty) return SizedBox();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((entry) {
          return GestureDetector(
            onTap: () => _addReaction(message, entry.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStickerWidget(String stickerId) {
    // Маппинг ID стикеров на эмодзи (можно расширить)
    final stickerMap = {
      'thumbs_up': '👍',
      'heart': '❤️',
      'fire': '🔥',
      'party': '🎉',
      'rocket': '🚀',
      'star': '⭐',
      'trophy': '🏆',
      'clap': '👏',
      'cool': '😎',
      'wink': '😉',
    };

    final emoji = stickerMap[stickerId] ?? '😀';

    return Container(
      padding: EdgeInsets.all(8),
      child: Text(
        emoji,
        style: TextStyle(fontSize: 64),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: colorScheme.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ на сообщение',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  replyTo.text.length > 48
                      ? '${replyTo.text.substring(0, 48)}…'
                      : replyTo.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurface),
            onPressed: _cancelAction,
          ),
        ],
      ),
    );
  }

  Widget _buildForwardPreview(Message forwardMessage) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.forward, color: colorScheme.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Переслать сообщение',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  forwardMessage.text.length > 48
                      ? '${forwardMessage.text.substring(0, 48)}…'
                      : forwardMessage.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurface),
            onPressed: _cancelAction,
          ),
          ElevatedButton(
            onPressed: _forwardMessage,
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(
            'Печатает...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    if (message.type == 'system') {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final isMyMessage = _isMyMessage(message.senderId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = isMyMessage
        ? colorScheme.primary
        : (theme.brightness == Brightness.dark
            ? colorScheme.surfaceVariant
            : colorScheme.surfaceVariant.withOpacity(0.8));
    final textColor =
        isMyMessage ? colorScheme.onPrimary : colorScheme.onSurface;
    final metaTextColor = isMyMessage
        ? colorScheme.onPrimary.withOpacity(0.8)
        : colorScheme.onSurfaceVariant;

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
                        Icon(Icons.forward, size: 12, color: metaTextColor),
                        SizedBox(width: 4),
                        Text(
                          'Переслано',
                          style: TextStyle(color: metaTextColor, fontSize: 10),
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
                      color: bubbleColor,
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
                              color: isMyMessage
                                  ? colorScheme.primaryContainer
                                      .withOpacity(0.35)
                                  : colorScheme.surface.withOpacity(
                                      theme.brightness == Brightness.dark
                                          ? 0.3
                                          : 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: colorScheme.secondary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToText!,
                              style: TextStyle(
                                color: textColor.withOpacity(0.85),
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
                                child: Stack(
                                  children: [
                                    Image.network(
                                      message.imageUrl!,
                                      width: 200,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.scrim
                                              .withOpacity(0.35),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.photo,
                                          size: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),

                        // Voice message
                        if (message.type == 'voice' &&
                            message.voiceAudioBase64 != null)
                          GestureDetector(
                            onTap: () => _playVoiceMessage(message),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bubbleColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _playingVoiceMessageId == message.id &&
                                            VoiceMessageService
                                                .isPlayingMessage(message.id)
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: textColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '${(message.voiceDuration ?? 0) ~/ 60}:${((message.voiceDuration ?? 0) % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        color: textColor, fontSize: 16),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.mic, color: textColor, size: 16),
                                ],
                              ),
                            ),
                          ),

                        // Sticker message
                        if (message.type == 'sticker' &&
                            message.stickerId != null)
                          _buildStickerWidget(message.stickerId!),

                        // Text content
                        if (message.text.isNotEmpty &&
                            message.type != 'voice' &&
                            message.type != 'sticker')
                          Text(
                            message.text,
                            style: TextStyle(color: textColor, fontSize: 15),
                          ),

                        // Timestamp and status
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TimeFormatter.formatMessageTime(
                                  message.timestamp),
                              style: TextStyle(
                                  color: metaTextColor, fontSize: 12),
                            ),
                            if (isMyMessage) ...[
                              SizedBox(width: 4),
                              MessageStatusIcon(
                                status: message.status,
                                isOwnMessage: _isMyMessage(message.senderId),
                              ),
                            ],
                          ],
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

  Widget _buildMessageBubbleMap(Map<String, dynamic> m) {
    final isMyMessage = (_currentUser?.uid ?? '') == (m['senderId'] ?? '');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = isMyMessage
        ? colorScheme.primary
        : (theme.brightness == Brightness.dark
            ? colorScheme.surfaceVariant
            : colorScheme.surfaceVariant.withOpacity(0.8));
    final textColor =
        isMyMessage ? colorScheme.onPrimary : colorScheme.onSurface;
    final metaColor = isMyMessage
        ? colorScheme.onPrimary.withOpacity(0.8)
        : colorScheme.onSurfaceVariant;

    if ((m['type'] ?? 'text') == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (m['text'] ?? '') as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

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
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((m['type'] ?? 'text') == 'image' && m['imageUrl'] != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            m['imageUrl'],
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  if ((m['text'] ?? '').toString().isNotEmpty)
                    Text(
                      m['text'],
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTs(m['timestamp']),
                        style: TextStyle(color: metaColor, fontSize: 12),
                      ),
                      if (isMyMessage) ...[
                        SizedBox(width: 4),
                        MessageStatusIcon(
                          status: m['status'] ?? 'sent',
                          isOwnMessage: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '';
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

  void _showUserProfile() async {
    // Получаем ID другого пользователя из чата
    // Для простоты берем первого участника, который не является текущим пользователем
    // В реальном приложении нужно получить список участников чата
    final chat = await ChatService.getUserChats();
    final currentChat =
        chat.firstWhere((c) => c.id == widget.chatId, orElse: () => chat.first);

    String otherUserId = '';
    if (currentChat.participants.isNotEmpty) {
      otherUserId = currentChat.participants.firstWhere(
        (id) => id != _currentUser?.uid,
        orElse: () => currentChat.participants.first,
      );
    }

    if (otherUserId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: otherUserId,
            isMyProfile: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _showUserProfile(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.chatName),
              if (_recordingVoiceUsers.isNotEmpty)
                _AnimatedStatusRow(
                  icon: Icons.mic,
                  text: 'Записывает голосовое...',
                )
              else if (_sendingPhotoUsers.isNotEmpty)
                _AnimatedStatusRow(
                  icon: Icons.photo,
                  text: 'Отправляет фото...',
                )
              else if (_typingUsers.isNotEmpty)
                _AnimatedStatusRow(
                  icon: Icons.edit,
                  text: 'Печатает...',
                ),
            ],
          ),
        ),
        // use theme default color
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    return _buildMessageBubbleMap(m);
                  },
                );
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
            onVoiceMessageSent: _sendVoiceMessage,
            onStickerSent: _sendSticker,
            typingController: _typingController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playbackCheckTimer?.cancel();
    VoiceMessageService.stopPlaying();
    _scrollController.dispose();
    _typingController.dispose();
    ChatService.setTypingStatus(widget.chatId, false);
    super.dispose();
  }
}

class _AnimatedStatusRow extends StatelessWidget {
  const _AnimatedStatusRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
