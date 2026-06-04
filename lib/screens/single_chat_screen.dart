import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../services/media_availability_service.dart';
import '../services/storage_service.dart';
import '../services/voice_message_service.dart';
import '../models/message.dart';
import '../models/chat.dart';
import 'chat_input_panel.dart';
import 'image_viewer_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/message_status_icon.dart';
import '../theme/darkkick_colors.dart';
import '../utils/time_formatter.dart';
import '../utils/navigation_animations.dart';
import '../utils/user_formatters.dart';
import '../utils/logger.dart';
import '../models/typing_status.dart';

class SingleChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? otherUserId; // ID получателя для нового чата

  const SingleChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    this.otherUserId,
  }) : super(key: key);

  @override
  _SingleChatScreenState createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Message? _replyingTo;
  Message? _forwardingMessage;
  final TextEditingController _typingController = TextEditingController();
  TypingStatus _typingStatus = TypingStatus(
    typingUsers: [],
    sendingPhotoUsers: [],
    recordingVoiceUsers: [],
  );
  String? _playingVoiceMessageId;
  StreamSubscription? _playbackCompleteSubscription;
  StreamSubscription? _typingStatusSubscription;
  String? _otherUserId;
  String? _peerName;
  String? _peerPhotoUrl;
  bool _peerIsOnline = false;
  DateTime? _peerLastSeen;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _messageDocs = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  String? _messagesStreamChatId;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Set<String> _invalidPinnedHandled = <String>{};

  bool get _voiceMessagesTemporarilyDisabled => true;

  @override
  void initState() {
    super.initState();
    _actualChatId = widget.chatId.isEmpty ? null : widget.chatId;
    _setupTypingListener();
    _setupTypingDetection();
    _loadPeerInfo();
    _markMessagesAsRead();
    _setupVoicePlaybackListener();
  }

  Future<void> _markMessagesAsRead() async {
    // Отмечаем все сообщения как прочитанные при открытии чата
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isNotEmpty) {
      await ChatService.markAllMessagesAsRead(chatId);
    }
  }

  Future<void> _loadPeerInfo([String? chatIdOverride]) async {
    String? otherUserId = widget.otherUserId ?? _otherUserId;
    final chatId = chatIdOverride ?? _actualChatId ?? widget.chatId;

    if ((otherUserId == null || otherUserId.isEmpty) && chatId.isNotEmpty) {
      try {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        final participants = List<String>.from(
          chatDoc.data()?['participants'] ?? const [],
        );
        otherUserId = participants.firstWhere(
          (id) => id != _currentUser?.uid,
          orElse: () => '',
        );
      } catch (e) {
        appLogger.e('Error resolving direct chat peer: $chatId', error: e);
      }
    }

    if (otherUserId == null || otherUserId.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(otherUserId)
          .get();
      final data = userDoc.data() ?? const <String, dynamic>{};
      final email = (data['email'] ?? '').toString();
      final fallback = email.contains('@')
          ? email.split('@').first
          : widget.chatName;
      final name = (data['name'] ?? fallback).toString();
      final photoUrl = UserFormatters.readPhotoUrl(data);
      final avatarUpdatedAt = UserFormatters.readDate(data['avatarUpdatedAt']);
      final lastSeen = UserFormatters.readDate(data['lastSeen']);

      if (!mounted) return;
      setState(() {
        _otherUserId = otherUserId;
        _peerName = name;
        _peerPhotoUrl = UserFormatters.versionedImageUrl(
          photoUrl,
          avatarUpdatedAt,
        );
        _peerIsOnline = data['isOnline'] == true;
        _peerLastSeen = lastSeen;
      });
    } catch (e) {
      appLogger.e('Error loading peer profile: $otherUserId', error: e);
    }
  }

  void _setupTypingListener() {
    // Слушатели работают только для существующих чатов
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isEmpty) return;

    // Используем единый поток для всех статусов
    _typingStatusSubscription = ChatService.getTypingStatus(chatId).listen((
      status,
    ) {
      if (mounted) {
        setState(() {
          _typingStatus = TypingStatus(
            typingUsers: status.typingUsers
                .where((id) => id != _currentUser?.uid)
                .toList(),
            sendingPhotoUsers: status.sendingPhotoUsers
                .where((id) => id != _currentUser?.uid)
                .toList(),
            recordingVoiceUsers: status.recordingVoiceUsers
                .where((id) => id != _currentUser?.uid)
                .toList(),
          );
        });
      }
    });
  }

  void _setupTypingDetection() {
    _typingController.addListener(() {
      final isTyping = _typingController.text.isNotEmpty;
      final chatId = _actualChatId ?? widget.chatId;
      if (chatId.isNotEmpty) {
        ChatService.setTypingStatus(chatId, isTyping);
      }
    });
  }

  String? _actualChatId; // Реальный ID чата (может быть создан при отправке)

  void _setupVoicePlaybackListener() {
    // Voice playback completion is handled via VoiceMessageService callback
    // No need for Timer.periodic polling
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStreamFor(String chatId) {
    if (_messagesStreamChatId != chatId || _messagesStream == null) {
      _messagesStreamChatId = chatId;
      _messagesStream = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return _messagesStream!;
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
    // Animation handled by AnimatedSize in _buildActionPreview
  }

  Future<String> _ensureChatExists() async {
    // Если чат уже существует, возвращаем его ID
    if (_actualChatId != null && _actualChatId!.isNotEmpty) {
      return _actualChatId!;
    }

    // Если это новый чат и есть получатель, создаем чат через ChatService
    if (widget.chatId.isEmpty && widget.otherUserId != null) {
      try {
        final chatId = await ChatService.createChat(
          otherUserId: widget.otherUserId!,
          chatName: widget.chatName,
        );
        if (mounted) {
          setState(() => _actualChatId = chatId);
        } else {
          _actualChatId = chatId;
        }
        _typingStatusSubscription?.cancel();
        _setupTypingListener();
        unawaited(_loadPeerInfo(chatId));
        appLogger.d('Chat ensured/created: $chatId');
        return chatId;
      } catch (e) {
        appLogger.e('Error ensuring chat exists', error: e);
        throw Exception('Не удалось создать чат: $e');
      }
    }

    // Если chatId был передан, используем его
    if (widget.chatId.isNotEmpty) {
      _actualChatId = widget.chatId;
      return _actualChatId!;
    }

    throw Exception('Cannot create chat: missing otherUserId');
  }

  Future<void> _sendTextMessage(String text, String type) async {
    if (text.trim().isEmpty) return;
    try {
      // Создаем чат при отправке первого сообщения, если его еще нет
      final chatId = await _ensureChatExists();

      await ChatService.sendMessage(
        chatId: chatId,
        text: text,
        type: type,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
      );
      _cancelAction(); // Clear preview immediately
      _scrollToBottom();
    } catch (e) {
      appLogger.e('Error sending message in chat: ${widget.chatId}', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
      }
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    try {
      final chatId = await _ensureChatExists();
      await ChatService.setSendingPhotoStatus(chatId, true);

      final messageId = ChatService.createMessageId(chatId);
      final imageUrl = await StorageService.uploadChatImage(
        imageFile,
        chatId,
        messageId: messageId,
      );

      await ChatService.sendMessage(
        chatId: chatId,
        text: '',
        type: 'image',
        imageUrl: imageUrl,
        messageId: messageId,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
        encrypt: false,
      );

      await ChatService.setSendingPhotoStatus(chatId, false);
      _cancelAction(); // Clear preview immediately
      _scrollToBottom();
    } catch (e) {
      appLogger.e('Error sending image in chat: ${_actualChatId}', error: e);
      if (_actualChatId != null) {
        await ChatService.setSendingPhotoStatus(_actualChatId!, false);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка отправки фото: $e')));
      }
    }
  }

  Future<void> _sendVoiceMessage(
    String base64Audio,
    int durationSeconds,
  ) async {
    if (_voiceMessagesTemporarilyDisabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Голосовые сообщения временно отключены'),
          ),
        );
      }
      return;
    }

    try {
      final chatId = await _ensureChatExists();
      await ChatService.sendMessage(
        chatId: chatId,
        text: '🎤 Голосовое сообщение',
        type: 'voice',
        voiceAudioBase64: base64Audio,
        voiceDuration: durationSeconds,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
      );

      _cancelAction(); // Clear preview immediately
      _scrollToBottom();
    } catch (e) {
      appLogger.e(
        'Error sending voice message in chat: ${widget.chatId}',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки голосового: $e')),
        );
      }
    }
  }

  Future<void> _sendSticker(String stickerId) async {
    try {
      final chatId = await _ensureChatExists();
      await ChatService.sendMessage(
        chatId: chatId,
        text: '',
        type: 'sticker',
        stickerId: stickerId,
      );

      _scrollToBottom();
    } catch (e) {
      appLogger.e('Error sending sticker in chat: ${widget.chatId}', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка отправки стикера: $e')));
      }
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

    // Отменяем предыдущую подписку
    await _playbackCompleteSubscription?.cancel();

    setState(() => _playingVoiceMessageId = messageId);

    // Play voice message and listen for completion
    await VoiceMessageService.playVoiceMessage(
      message.voiceAudioBase64!,
      messageId,
    );

    // Listen for playback completion via VoiceMessageService callback
    // The service already handles completion internally, we just need to update UI
    final completionStream = VoiceMessageService.onPlaybackComplete;
    if (completionStream != null) {
      _playbackCompleteSubscription = completionStream.listen((
        completedMessageId,
      ) {
        if (mounted && completedMessageId == messageId) {
          setState(() {
            if (_playingVoiceMessageId == messageId) {
              _playingVoiceMessageId = null;
            }
          });
        }
      });
    }
  }

  Future<void> _forwardMessage() async {
    if (_forwardingMessage == null) return;

    try {
      final chatId = await _ensureChatExists();
      await ChatService.forwardMessage(_forwardingMessage!, chatId);
      _cancelAction(); // Clear preview immediately with animation
      _scrollToBottom();
    } catch (e) {
      appLogger.e(
        'Error forwarding message in chat: ${widget.chatId}',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка пересылки: $e')));
      }
    }
  }

  Future<void> _addReaction(Message message, String emoji) async {
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isEmpty) return;
    await ChatService.addReaction(chatId, message.id, emoji);
    // StreamBuilder will automatically update
  }

  Future<void> _pinMessage(Message message) async {
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isEmpty) return;
    await ChatService.pinMessage(chatId, message);
  }

  GlobalKey _messageKey(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  Future<void> _scrollToPinnedMessage(Map<String, dynamic> pinned) async {
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isNotEmpty &&
        !await _validatePinnedMessage(chatId, pinned, notify: true)) {
      return;
    }

    final messageId = (pinned['messageId'] ?? pinned['id'] ?? '').toString();
    if (messageId.isEmpty) {
      _showSnackBar('Сообщение не найдено');
      return;
    }

    final existingContext = _messageKeys[messageId]?.currentContext;
    if (existingContext != null) {
      await Scrollable.ensureVisible(
        existingContext,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: 0.35,
      );
      _highlightMessage(messageId);
      return;
    }

    final index = _messageDocs.indexWhere((doc) => doc.id == messageId);
    if (index == -1 || !_scrollController.hasClients) {
      _showSnackBar('Сообщение не найдено');
      return;
    }

    final maxOffset = _scrollController.position.maxScrollExtent;
    final targetOffset = _messageDocs.length <= 1
        ? 0.0
        : (maxOffset * (index / (_messageDocs.length - 1)))
              .clamp(0.0, maxOffset)
              .toDouble();
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _messageKeys[messageId]?.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
        _highlightMessage(messageId);
      }
    });
  }

  Future<bool> _validatePinnedMessage(
    String chatId,
    Map<String, dynamic> pinned, {
    required bool notify,
  }) async {
    final messageId = (pinned['messageId'] ?? pinned['id'] ?? '').toString();
    if (messageId.isEmpty) {
      await _clearInvalidPinnedMessage(chatId, messageId, null, notify: notify);
      return false;
    }

    Map<String, dynamic>? messageData;
    for (final doc in _messageDocs) {
      if (doc.id == messageId) {
        messageData = doc.data();
        break;
      }
    }

    if (messageData == null) {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (!doc.exists) {
        await _clearInvalidPinnedMessage(
          chatId,
          messageId,
          null,
          notify: notify,
        );
        return false;
      }
      messageData = doc.data();
    }

    final type = (pinned['type'] ?? messageData?['type'] ?? '').toString();
    if (type == 'image') {
      final imageUrl = (pinned['imageUrl'] ?? messageData?['imageUrl'] ?? '')
          .toString()
          .trim();
      if (!await MediaAvailabilityService.exists(imageUrl)) {
        await _clearInvalidPinnedMessage(
          chatId,
          messageId,
          'Закреплённое фото больше недоступно',
          notify: notify,
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _clearInvalidPinnedMessage(
    String chatId,
    String messageId,
    String? message, {
    required bool notify,
  }) async {
    final key = '$chatId:$messageId:${message ?? 'missing'}';
    if (!_invalidPinnedHandled.add(key)) return;

    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'pinnedMessage': null,
      });
    } catch (e) {
      appLogger.e('Error clearing invalid pinned message', error: e);
    }

    if (notify) {
      _showSnackBar(message ?? 'Сообщение не найдено');
    }
  }

  void _highlightMessage(String messageId) {
    _highlightTimer?.cancel();
    if (!mounted) return;
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted && _highlightedMessageId == messageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _isMyMessage(String senderId) {
    return senderId == _currentUser?.uid;
  }

  String _messageStatusForCurrentUser(Message message) {
    final currentUid = _currentUser?.uid;
    if (currentUid == null || message.senderId != currentUid) {
      return message.status;
    }

    final isReadByOther = message.readBy.any((uid) => uid != currentUid);
    return isReadByOther ? 'read' : 'sent';
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
              child: Text(entry.value, style: const TextStyle(fontSize: 12)),
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
      child: Text(emoji, style: TextStyle(fontSize: 64)),
    );
  }

  Widget _buildActionPreview() {
    return AnimatedSize(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _replyingTo != null
          ? _buildReplyPreview(_replyingTo!)
          : _forwardingMessage != null
          ? _buildForwardPreview(_forwardingMessage!)
          : SizedBox(),
    );
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
    if (_typingStatus.typingUsers.isEmpty) return const SizedBox();

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
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  List<ChatImageItem> _chatImageItems() {
    return _messageDocs
        .map((doc) {
          final data = doc.data();
          final type = (data['type'] ?? '').toString();
          final imageUrl = (data['imageUrl'] ?? '').toString().trim();
          if (type != 'image' || imageUrl.isEmpty) return null;
          return ChatImageItem(messageId: doc.id, imageUrl: imageUrl);
        })
        .whereType<ChatImageItem>()
        .toList();
  }

  void _openImageViewer(Message message) {
    final imageUrl = message.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) return;

    final items = _chatImageItems();
    final fallbackItems = items.isEmpty
        ? [ChatImageItem(messageId: message.id, imageUrl: imageUrl)]
        : items;
    final initialIndex = fallbackItems.indexWhere(
      (item) => item.messageId == message.id,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          images: fallbackItems,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: docs.length,
      key: ValueKey('messages_list_${_actualChatId ?? widget.chatId}'),
      itemBuilder: (_, i) {
        final doc = docs[i];
        final message = Message.fromMap(doc.data(), doc.id);
        return RepaintBoundary(
          key: _messageKey(message.id),
          child: _buildMessageBubble(message),
        );
      },
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
        ? DarkKickColors.neonPurple
        : DarkKickColors.panel;
    final textColor = isMyMessage
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final metaTextColor = isMyMessage
        ? colorScheme.onPrimary.withOpacity(0.8)
        : colorScheme.onSurfaceVariant;
    final isHighlighted = _highlightedMessageId == message.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMyMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMyMessage ? 18 : 4),
                        bottomRight: Radius.circular(isMyMessage ? 4 : 18),
                      ),
                      border: isHighlighted
                          ? Border.all(
                              color: DarkKickColors.neonPurple,
                              width: 1.4,
                            )
                          : isMyMessage
                          ? null
                          : Border.all(color: DarkKickColors.divider),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: DarkKickColors.neonPurple.withValues(
                                  alpha: 0.55,
                                ),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ]
                          : isMyMessage
                          ? [
                              BoxShadow(
                                color: DarkKickColors.neonPurple.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
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
                                  ? colorScheme.primaryContainer.withOpacity(
                                      0.35,
                                    )
                                  : colorScheme.surface.withOpacity(
                                      theme.brightness == Brightness.dark
                                          ? 0.3
                                          : 0.6,
                                    ),
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
                              GestureDetector(
                                onTap: () => _openImageViewer(message),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      Hero(
                                        tag: 'chat-image-${message.id}',
                                        child: CachedNetworkImage(
                                          imageUrl: message.imageUrl!,
                                          width: 200,
                                          height: 150,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                width: 200,
                                                height: 150,
                                                color:
                                                    colorScheme.surfaceVariant,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                width: 200,
                                                height: 150,
                                                color: DarkKickColors.panel,
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  'Фото недоступно',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: DarkKickColors
                                                        .textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.scrim
                                                .withOpacity(0.35),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                            VoiceMessageService.isPlayingMessage(
                                              message.id,
                                            )
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: textColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '${(message.voiceDuration ?? 0) ~/ 60}:${((message.voiceDuration ?? 0) % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
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
                                message.timestamp,
                              ),
                              style: TextStyle(
                                color: metaTextColor,
                                fontSize: 12,
                              ),
                            ),
                            if (isMyMessage) ...[
                              SizedBox(width: 4),
                              MessageStatusIcon(
                                status: _messageStatusForCurrentUser(message),
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

  Widget _buildPinnedMessageCard(String chatId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, snapshot) {
        final pinned = snapshot.data?.data()?['pinnedMessage'];
        if (pinned == null) return const SizedBox.shrink();

        final data = Map<String, dynamic>.from(pinned);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validatePinnedMessage(chatId, data, notify: true);
        });
        final text = (data['text'] ?? '').toString();
        final type = (data['type'] ?? 'text').toString();
        final label = text.isNotEmpty
            ? text
            : type == 'image'
            ? 'Фото'
            : type == 'sticker'
            ? 'Стикер'
            : 'Сообщение';

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: GestureDetector(
            onTap: () => _scrollToPinnedMessage(data),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DarkKickColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DarkKickColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: DarkKickColors.neonPurple.withValues(alpha: 0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.push_pin_outlined,
                    color: DarkKickColors.neonPurple,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Закреплено',
                          style: TextStyle(
                            color: DarkKickColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text.isNotEmpty
                              ? label
                              : type == 'image'
                              ? 'Фото'
                              : type == 'sticker'
                              ? 'Стикер'
                              : 'Сообщение',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DarkKickColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            ListTile(
              leading: Icon(Icons.push_pin_outlined),
              title: Text('Закрепить'),
              onTap: () {
                Navigator.pop(context);
                _pinMessage(message);
              },
            ),
            Divider(),
            Text(
              'Добавить реакцию:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    // Используем otherUserId если он передан, иначе получаем из участников чата напрямую
    String? otherUserId = widget.otherUserId ?? _otherUserId;

    if (otherUserId == null) {
      // Получаем ID другого пользователя из участников чата напрямую через Firestore
      final chatId = _actualChatId ?? widget.chatId;
      if (chatId.isNotEmpty) {
        try {
          final chatDoc = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .get();

          if (chatDoc.exists) {
            final participants = List<String>.from(
              chatDoc.data()?['participants'] ?? [],
            );

            if (participants.isNotEmpty) {
              otherUserId = participants.firstWhere(
                (id) => id != _currentUser?.uid,
                orElse: () => participants.first,
              );
            }
          }
        } catch (e) {
          appLogger.e(
            'Error getting chat participants for chat: ${widget.chatId}',
            error: e,
          );
        }
      }
    }

    if (!mounted || otherUserId == null || otherUserId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: otherUserId!,
          isMyProfile: false,
          chatId: _actualChatId ?? widget.chatId,
        ),
      ),
    );
  }

  Widget _buildChatAppBarTitle() {
    final otherUserId = widget.otherUserId ?? _otherUserId;
    final fallbackName = _peerName ?? widget.chatName;

    Widget titleContent({
      required String name,
      required String? photoUrl,
      required bool isOnline,
      required DateTime? lastSeen,
    }) {
      final status = _typingStatus.recordingVoiceUsers.isNotEmpty
          ? 'Записывает голосовое...'
          : _typingStatus.sendingPhotoUsers.isNotEmpty
          ? 'Отправляет фото...'
          : _typingStatus.typingUsers.isNotEmpty
          ? 'Печатает...'
          : UserFormatters.chatPresence(isOnline: isOnline, lastSeen: lastSeen);

      return GestureDetector(
        onTap: _showUserProfile,
        child: Row(
          children: [
            _ChatAppBarAvatar(
              name: name,
              photoUrl: photoUrl,
              isOnline: isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOnline
                          ? DarkKickColors.online
                          : DarkKickColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (otherUserId == null || otherUserId.isEmpty) {
      return titleContent(
        name: fallbackName,
        photoUrl: _peerPhotoUrl,
        isOnline: _peerIsOnline,
        lastSeen: _peerLastSeen,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(otherUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final email = (data['email'] ?? '').toString();
        final loadedName = (data['name'] ?? '').toString();
        final name = loadedName.isNotEmpty
            ? loadedName
            : email.contains('@')
            ? email.split('@').first
            : fallbackName;
        final photoUrl = UserFormatters.readPhotoUrl(data);
        final avatarUpdatedAt = UserFormatters.readDate(
          data['avatarUpdatedAt'],
        );
        final lastSeen =
            UserFormatters.readDate(data['lastSeen']) ?? _peerLastSeen;

        return titleContent(
          name: name,
          photoUrl:
              UserFormatters.versionedImageUrl(photoUrl, avatarUpdatedAt) ??
              _peerPhotoUrl,
          isOnline: data['isOnline'] == true,
          lastSeen: lastSeen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatId = _actualChatId ?? widget.chatId;

    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        foregroundColor: DarkKickColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: _buildChatAppBarTitle(),
        // use theme default color
      ),
      body: Column(
        children: [
          if (chatId.isNotEmpty) _buildPinnedMessageCard(chatId),
          Expanded(
            child: chatId.isNotEmpty
                ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messageStreamFor(chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        if (_messageDocs.isNotEmpty) {
                          return _buildMessagesList(_messageDocs);
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                            color: DarkKickColors.neonPurple,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const _ChatEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Не удалось загрузить сообщения',
                          subtitle: 'Проверь подключение и открой чат еще раз.',
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Ошибка загрузки сообщений: ${snapshot.error}',
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      _messageDocs = docs;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead();
                      });
                      if (docs.isEmpty) {
                        return const _ChatEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'Диалог пуст',
                          subtitle: 'Отправь первое сообщение.',
                        );
                      }
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Начните диалог, отправив сообщение',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return _buildMessagesList(docs);
                    },
                  )
                : Center(
                    child: Text(
                      'Начните диалог, отправив сообщение',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
          ),

          // Action preview (reply/forward)
          _buildActionPreview(),

          if (_typingStatus.typingUsers.isNotEmpty) _buildTypingIndicator(),

          ChatInputPanel(
            chatId: _actualChatId ?? widget.chatId,
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
    _highlightTimer?.cancel();
    _playbackCompleteSubscription?.cancel();
    _typingStatusSubscription?.cancel();
    VoiceMessageService.stopPlaying();
    _scrollController.dispose();
    _typingController.dispose();
    final chatId = _actualChatId ?? widget.chatId;
    if (chatId.isNotEmpty) {
      ChatService.setTypingStatus(chatId, false);
    }
    super.dispose();
  }
}

class _ChatAppBarAvatar extends StatelessWidget {
  const _ChatAppBarAvatar({
    required this.name,
    required this.photoUrl,
    required this.isOnline,
  });

  final String name;
  final String? photoUrl;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DarkKickColors.stroke),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ChatAppBarAvatarFallback(initial: initial),
                  )
                : _ChatAppBarAvatarFallback(initial: initial),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: isOnline ? DarkKickColors.online : DarkKickColors.offline,
              shape: BoxShape.circle,
              border: Border.all(
                color: DarkKickColors.darkBackground,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatAppBarAvatarFallback extends StatelessWidget {
  const _ChatAppBarAvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DarkKickColors.cardSoft,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DarkKickColors.neonPurple, size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DarkKickColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
