import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/darkkick_colors.dart';
import '../widgets/sticker_picker.dart';

class ChatInputPanel extends StatefulWidget {
  const ChatInputPanel({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.onSendMessage,
    required this.onImageUpload,
    this.onVoiceMessageSent,
    this.onStickerSent,
    this.typingController,
  });

  final String chatId;
  final String currentUserId;
  final void Function(String text, String type) onSendMessage;
  final Future<void> Function(File imageFile) onImageUpload;
  final void Function(String base64Audio, int duration)? onVoiceMessageSent;
  final void Function(String stickerId)? onStickerSent;
  final TextEditingController? typingController;

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final TextEditingController _localController = TextEditingController();
  bool _showAttachmentMenu = false;
  bool _showStickerPicker = false;
  bool _uploadingImage = false;

  TextEditingController get _controller =>
      widget.typingController ?? _localController;

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  Future<void> _sendPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploadingImage = true);
    try {
      await widget.onImageUpload(File(image.path));
      if (mounted) setState(() => _showAttachmentMenu = false);
    } catch (_) {
      _showSnackBar('Не удалось отправить фото.');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _sendTextMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text, 'text');
    _controller.clear();
    setState(() {});
  }

  void _sendSticker(String stickerId) {
    widget.onStickerSent?.call(stickerId);
    setState(() => _showStickerPicker = false);
  }

  KeyEventResult _handleTextFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isShiftPressed =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (isShiftPressed) {
      return KeyEventResult.ignored;
    }

    _sendTextMessage();
    return KeyEventResult.handled;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStickerPicker)
            StickerPicker(
              onStickerSelected: _sendSticker,
              onDismiss: () => setState(() => _showStickerPicker = false),
            ),
          if (_showAttachmentMenu) _buildAttachmentMenu(),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            decoration: const BoxDecoration(
              color: DarkKickColors.darkBackground,
              border: Border(top: BorderSide(color: DarkKickColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachmentMenu
                        ? Icons.close
                        : Icons.add_circle_outline,
                    color: DarkKickColors.neonPurple,
                  ),
                  onPressed: () => setState(
                    () => _showAttachmentMenu = !_showAttachmentMenu,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: DarkKickColors.panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DarkKickColors.divider),
                    ),
                    child: Focus(
                      onKeyEvent: _handleTextFieldKey,
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          color: DarkKickColors.textPrimary,
                        ),
                        cursorColor: DarkKickColors.neonPurple,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Сообщение...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendTextMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DarkKickColors.neonPurple,
                      boxShadow: [
                        BoxShadow(
                          color: DarkKickColors.neonPurple.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      decoration: const BoxDecoration(
        color: DarkKickColors.darkBackground,
        border: Border(top: BorderSide(color: DarkKickColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AttachmentButton(
            icon: _uploadingImage ? Icons.hourglass_top : Icons.photo_outlined,
            label: 'Фото',
            onTap: _uploadingImage ? null : _sendPhoto,
          ),
          _AttachmentButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'Стикер',
            onTap: () =>
                setState(() => _showStickerPicker = !_showStickerPicker),
          ),
        ],
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DarkKickColors.panel,
              border: Border.all(color: DarkKickColors.divider),
            ),
            child: Icon(icon, color: DarkKickColors.neonPurple),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
