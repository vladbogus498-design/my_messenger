import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/selected_media.dart';
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
  final Future<void> Function(String text, String type) onSendMessage;
  final Future<void> Function(SelectedMedia image) onImageUpload;
  final void Function(String base64Audio, int duration)? onVoiceMessageSent;
  final Future<void> Function(String stickerId)? onStickerSent;
  final TextEditingController? typingController;

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final TextEditingController _localController = TextEditingController();
  bool _showAttachmentMenu = false;
  bool _showStickerPicker = false;
  bool _uploadingImage = false;
  bool _sendingText = false;
  bool _sendingSticker = false;

  TextEditingController get _controller =>
      widget.typingController ?? _localController;

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  Future<void> _sendPhoto() async {
    if (_uploadingImage) return;

    try {
      setState(() => _uploadingImage = true);

      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected image is empty');
      }

      await widget.onImageUpload(
        SelectedMedia(bytes: bytes, name: image.name, path: image.path),
      );
      if (mounted) setState(() => _showAttachmentMenu = false);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Photo send failed: $error\n$stackTrace');
      }
      _showSnackBar('Не удалось отправить фото.');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _sendTextMessage() async {
    if (_sendingText) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingText = true);
    try {
      await widget.onSendMessage(text, 'text');
      _controller.clear();
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Text send failed: $error\n$stackTrace');
      }
      _showSnackBar('Не удалось отправить сообщение.');
    } finally {
      if (mounted) setState(() => _sendingText = false);
    }
  }

  Future<void> _sendSticker(String stickerId) async {
    if (_sendingSticker) return;
    final sendSticker = widget.onStickerSent;
    if (sendSticker == null) return;

    setState(() => _sendingSticker = true);
    try {
      await sendSticker(stickerId);
      if (mounted) setState(() => _showStickerPicker = false);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Sticker send failed: $error\n$stackTrace');
      }
      _showSnackBar('Не удалось отправить стикер.');
    } finally {
      if (mounted) setState(() => _sendingSticker = false);
    }
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

    unawaited(_sendTextMessage());
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
                  onPressed: () => setState(() {
                    _showAttachmentMenu = !_showAttachmentMenu;
                    if (_showAttachmentMenu) _showStickerPicker = false;
                  }),
                ),
                _StickerToggleButton(
                  active: _showStickerPicker,
                  onTap: () => setState(() {
                    _showStickerPicker = !_showStickerPicker;
                    if (_showStickerPicker) _showAttachmentMenu = false;
                  }),
                ),
                const SizedBox(width: 8),
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
                        onSubmitted: (_) => unawaited(_sendTextMessage()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendingText
                      ? null
                      : () => unawaited(_sendTextMessage()),
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
        ],
      ),
    );
  }
}

class _StickerToggleButton extends StatelessWidget {
  const _StickerToggleButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF1A0F2A) : DarkKickColors.panel,
          border: Border.all(
            color: active
                ? DarkKickColors.neonPurple.withValues(alpha: 0.72)
                : DarkKickColors.divider,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DarkKickColors.neonPurple.withValues(alpha: 0.34),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.sticky_note_2_outlined,
          color: active
              ? DarkKickColors.electricPurple
              : DarkKickColors.neonPurple,
          size: 21,
        ),
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
