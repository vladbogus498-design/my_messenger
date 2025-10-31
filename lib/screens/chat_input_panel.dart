import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputPanel extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final Function(String, String) onSendMessage;
  final Function(String) onImageUpload;

  const ChatInputPanel({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.onSendMessage,
    required this.onImageUpload,
  }) : super(key: key);

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _showAttachmentMenu = false;

  // 📸 Временное решение для фото (демо-режим)
  Future<void> _sendPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Демо-режим: используем случайное фото из интернета
        final String demoImageUrl =
            'https://picsum.photos/200/300?random=${DateTime.now().millisecondsSinceEpoch}';
        widget.onImageUpload(demoImageUrl);

        _showSnackBar('Фото отправлено! 📸');
      }
    } catch (e) {
      print('❌ Ошибка выбора фото: $e');
      _showSnackBar('Ошибка загрузки фото');
    }
  }

  // 🎤 Голосовое сообщение (заглушка)
  void _startVoiceRecording() {
    _showSnackBar('Голосовые сообщения скоро будут! 🎤');
  }

  // 📍 Местоположение (заглушка)
  void _sendLocation() {
    _showSnackBar('Отправка местоположения скоро будет! 📍');
  }

  // 📎 Меню прикреплений
  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ✉️ Отправка текстового сообщения
  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text, 'text');
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // 📎 Меню прикреплений
          if (_showAttachmentMenu) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 📸 Фото
                  _AttachmentButton(
                    icon: Icons.photo,
                    label: 'Фото',
                    onTap: _sendPhoto,
                  ),
                  // 🎤 Голосовое
                  _AttachmentButton(
                    icon: Icons.mic,
                    label: 'Голосовое',
                    onTap: _startVoiceRecording,
                  ),
                  // 📍 Местоположение
                  _AttachmentButton(
                    icon: Icons.location_on,
                    label: 'Место',
                    onTap: _sendLocation,
                  ),
                ],
              ),
            ),
            Divider(height: 1),
          ],

          // ✏️ Поле ввода + кнопки
          Row(
            children: [
              // 📎 Кнопка прикреплений
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: _toggleAttachmentMenu,
                tooltip: 'Прикрепить файл',
              ),

              // 📝 Поле ввода
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),

              // ▶️ Кнопка отправки
              IconButton(
                icon: Icon(Icons.send, color: Colors.blue),
                onPressed: _sendTextMessage,
                tooltip: 'Отправить сообщение',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🎯 Кнопка меню прикреплений
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade100.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
