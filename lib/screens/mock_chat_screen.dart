// lib/screens/mock_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';
import 'mock_data.dart';

class MockChatScreen extends StatefulWidget {
  final MockChat chat;
  const MockChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<MockChatScreen> createState() => _MockChatScreenState();
}

class _MockChatScreenState extends State<MockChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MockMessage> get _messages {
    chatMessages.putIfAbsent(widget.chat.id, () => []);
    return chatMessages[widget.chat.id]!;
  }

  bool get _isAdmin =>
      widget.chat.type == ChatType.personal || widget.chat.isSubscribed;

  bool get _canWrite =>
      widget.chat.type == ChatType.personal ||
      (widget.chat.type == ChatType.group && widget.chat.isSubscribed) ||
      (widget.chat.type == ChatType.channel && widget.chat.isSubscribed);

  @override
  void initState() {
    super.initState();
    // Сбрасываем счётчик непрочитанных при открытии чата
    widget.chat.unreadCount = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = MockMessage(text: text, isMe: true, time: DateTime.now());
    setState(() {
      _messages.add(msg);
      widget.chat.lastMessage = text;
      widget.chat.lastMessageTime = msg.time;
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(max, duration: Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  void _subscribe() {
    setState(() => widget.chat.isSubscribed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.chat.type == ChatType.group ? 'Вы вступили в группу!' : 'Вы подписались на канал!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DarkKickColors.neonPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          // Если не подписан — показываем кнопку вместо инпута
          widget.chat.isSubscribed ? _buildInputBar() : _buildSubscribeBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String subtitle;
    if (widget.chat.type == ChatType.personal) {
      subtitle = 'онлайн';
    } else if (widget.chat.type == ChatType.group) {
      subtitle = widget.chat.isSubscribed ? 'группа · вы участник' : 'группа';
    } else {
      subtitle = widget.chat.isSubscribed ? 'канал · вы создатель' : 'канал';
    }

    return AppBar(
      backgroundColor: DarkKickColors.darkBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: DarkKickColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.chat.avatarColor,
              boxShadow: [BoxShadow(color: DarkKickColors.neonPurple.withOpacity(0.3), blurRadius: 8)],
            ),
            child: Center(child: Text(widget.chat.avatarEmoji, style: TextStyle(fontSize: 20))),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: DarkKickColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.chat.type == ChatType.personal
                            ? DarkKickColors.online
                            : DarkKickColors.neonPurple,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(subtitle, style: TextStyle(color: DarkKickColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.chat.type == ChatType.personal)
          IconButton(icon: Icon(Icons.phone_outlined, color: DarkKickColors.neonPurple), onPressed: () {}),
        IconButton(icon: Icon(Icons.more_vert, color: DarkKickColors.textSecondary), onPressed: () {}),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.chat.avatarEmoji, style: TextStyle(fontSize: 52)),
          SizedBox(height: 10),
          Text(
            widget.chat.type == ChatType.personal
                ? 'Начни диалог с ${widget.chat.name.split(' ').first}'
                : 'Сообщений пока нет',
            style: TextStyle(color: DarkKickColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(MockMessage msg) {
    final isMe = msg.isMe;
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Аватар собеседника
          if (!isMe) ...[
            Container(
              width: 28, height: 28,
              margin: EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.chat.avatarColor),
              child: Center(child: Text(widget.chat.avatarEmoji, style: TextStyle(fontSize: 13))),
            ),
          ],
          // Пузырь
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? DarkKickColors.neonPurple : DarkKickColors.mediumGray,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isMe ? Radius.circular(16) : Radius.circular(3),
                  bottomRight: isMe ? Radius.circular(3) : Radius.circular(16),
                ),
                boxShadow: isMe
                    ? [BoxShadow(color: DarkKickColors.neonPurple.withOpacity(0.2), blurRadius: 6, offset: Offset(0, 2))]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : DarkKickColors.textPrimary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.time),
                        style: TextStyle(
                          color: isMe ? Colors.white.withOpacity(0.55) : DarkKickColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 3),
                        Icon(Icons.done_all, size: 11, color: Colors.white.withOpacity(0.65)),
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

  // ─── Инпут для тех кто может писать ────────────────────────────────────────
  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DarkKickColors.darkBackground,
          border: Border(top: BorderSide(color: DarkKickColors.divider)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: DarkKickColors.neonPurple, size: 25),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 34, minHeight: 34),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: DarkKickColors.mediumGray,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: DarkKickColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    hintStyle: TextStyle(color: DarkKickColors.lightGray, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DarkKickColors.neonPurple,
                  boxShadow: [BoxShadow(color: DarkKickColors.neonPurple.withOpacity(0.35), blurRadius: 10)],
                ),
                child: Icon(Icons.send, color: Colors.white, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Кнопка подписки / вступления для чужих групп и каналов ────────────────
  Widget _buildSubscribeBar() {
    final isGroup = widget.chat.type == ChatType.group;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: DarkKickColors.darkBackground,
          border: Border(top: BorderSide(color: DarkKickColors.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _subscribe,
            icon: Icon(isGroup ? Icons.group_add : Icons.notifications_active, size: 18),
            label: Text(
              isGroup ? 'Вступить в группу' : 'Подписаться на канал',
              style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkKickColors.neonPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
