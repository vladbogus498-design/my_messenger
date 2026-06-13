import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darkkick_colors.dart';
import '../widgets/sticker_picker.dart';

String _desktopInputText(BuildContext context, String key) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  final values = _desktopInputStrings[code] ?? _desktopInputStrings['en']!;
  return values[key] ?? _desktopInputStrings['en']![key] ?? key;
}

const _desktopInputStrings = {
  'en': {
    'sendTextFailed': 'Could not send the message.',
    'sendStickerFailed': 'Could not send the sticker.',
    'sendPhotoFailed': 'Could not send the photo.',
    'unsupported': 'Not available on desktop yet',
    'photo': 'Photo',
    'stickers': 'Stickers',
    'message': 'Message...',
    'send': 'Send',
  },
  'ru': {
    'sendTextFailed': 'Не удалось отправить сообщение.',
    'sendStickerFailed': 'Не удалось отправить стикер.',
    'sendPhotoFailed': 'Не удалось отправить фото.',
    'unsupported': 'Пока недоступно на desktop',
    'photo': 'Фото',
    'stickers': 'Стикеры',
    'message': 'Сообщение...',
    'send': 'Отправить',
  },
  'pl': {
    'sendTextFailed': 'Nie udało się wysłać wiadomości.',
    'sendStickerFailed': 'Nie udało się wysłać naklejki.',
    'sendPhotoFailed': 'Nie udało się wysłać zdjęcia.',
    'unsupported': 'Jeszcze niedostępne na desktopie',
    'photo': 'Zdjęcie',
    'stickers': 'Naklejki',
    'message': 'Wiadomość...',
    'send': 'Wyślij',
  },
};

class DesktopChatInputPanel extends StatefulWidget {
  const DesktopChatInputPanel({
    super.key,
    required this.onSendMessage,
    required this.onImageSelected,
    required this.onStickerSent,
    this.typingController,
  });

  final Future<void> Function(String text, String type) onSendMessage;
  final Future<void> Function() onImageSelected;
  final Future<void> Function(String stickerId) onStickerSent;
  final TextEditingController? typingController;

  @override
  State<DesktopChatInputPanel> createState() => _DesktopChatInputPanelState();
}

class _DesktopChatInputPanelState extends State<DesktopChatInputPanel> {
  final TextEditingController _localController = TextEditingController();
  bool _showStickers = false;
  bool _sendingText = false;
  bool _sendingSticker = false;
  bool _pickingImage = false;

  TextEditingController get _controller =>
      widget.typingController ?? _localController;

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    if (_sendingText) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingText = true);
    try {
      await widget.onSendMessage(text, 'text');
      _controller.clear();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Desktop text send failed: $error\n$stackTrace');
      }
      _showSnackBar(_desktopInputText(context, 'sendTextFailed'));
    } finally {
      if (mounted) setState(() => _sendingText = false);
    }
  }

  Future<void> _sendSticker(String stickerId) async {
    if (_sendingSticker) return;

    setState(() => _sendingSticker = true);
    try {
      await widget.onStickerSent(stickerId);
      if (mounted) setState(() => _showStickers = false);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Desktop sticker send failed: $error\n$stackTrace');
      }
      _showSnackBar(_desktopInputText(context, 'sendStickerFailed'));
    } finally {
      if (mounted) setState(() => _sendingSticker = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_pickingImage) return;

    setState(() => _pickingImage = true);
    try {
      await widget.onImageSelected();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Desktop photo send failed: $error\n$stackTrace');
      }
      _showSnackBar(_desktopInputText(context, 'sendPhotoFailed'));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _showUnsupported() {
    _showSnackBar(_desktopInputText(context, 'unsupported'));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftPressed =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (shiftPressed) return KeyEventResult.ignored;

    unawaited(_sendText());
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DarkKickColors.darkBackground,
        border: Border(top: BorderSide(color: DarkKickColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStickers)
            StickerPicker(
              onStickerSelected: (id) => unawaited(_sendSticker(id)),
              onDismiss: () => setState(() => _showStickers = false),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _DesktopIconButton(
                  icon: _pickingImage
                      ? Icons.hourglass_top
                      : Icons.photo_outlined,
                  tooltip: _desktopInputText(context, 'photo'),
                  onPressed: _pickingImage
                      ? null
                      : () => unawaited(_pickPhoto()),
                ),
                const SizedBox(width: 8),
                _DesktopIconButton(
                  icon: Icons.sticky_note_2_outlined,
                  tooltip: _desktopInputText(context, 'stickers'),
                  active: _showStickers,
                  onPressed: () =>
                      setState(() => _showStickers = !_showStickers),
                ),
                const SizedBox(width: 8),
                _DesktopIconButton(
                  icon: Icons.mic_none_outlined,
                  tooltip: _desktopInputText(context, 'unsupported'),
                  onPressed: _showUnsupported,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Focus(
                    onKeyEvent: _handleKey,
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: DarkKickColors.textPrimary),
                      cursorColor: DarkKickColors.neonPurple,
                      decoration: InputDecoration(
                        hintText: _desktopInputText(context, 'message'),
                        hintStyle: const TextStyle(
                          color: DarkKickColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: DarkKickColors.panel,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: DarkKickColors.divider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: DarkKickColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: DarkKickColors.neonPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _DesktopIconButton(
                  icon: _sendingText ? Icons.hourglass_top : Icons.send,
                  tooltip: _desktopInputText(context, 'send'),
                  filled: true,
                  onPressed: _sendingText ? null : () => unawaited(_sendText()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopIconButton extends StatelessWidget {
  const _DesktopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? DarkKickColors.neonPurple
        : active
        ? DarkKickColors.neonPurple.withValues(alpha: 0.16)
        : DarkKickColors.panel;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          color: filled ? Colors.white : DarkKickColors.neonPurple,
          style: IconButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: DarkKickColors.panel,
            disabledForegroundColor: DarkKickColors.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: DarkKickColors.divider),
            ),
          ),
        ),
      ),
    );
  }
}
