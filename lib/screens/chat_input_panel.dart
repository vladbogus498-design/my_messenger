import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/chat_service.dart';

class ChatInputPanel extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final Function(String, String) onSendMessage;
  final Function(String) onImageUpload;
  final TextEditingController? typingController;

  const ChatInputPanel({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.onSendMessage,
    required this.onImageUpload,
    this.typingController,
  }) : super(key: key);

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _showAttachmentMenu = false;

  TextEditingController get _effectiveController {
    return widget.typingController ?? _messageController;
  }

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
        // Устанавливаем статус "отправляет фото"
        await ChatService.setSendingPhotoStatus(widget.chatId, true);

        try {
          _showSnackBar('Загружаем фото...');
          final String imageUrl = await StorageService.uploadChatImage(
              File(image.path), widget.chatId);

          widget.onImageUpload(imageUrl);
          _showSnackBar('Фото отправлено! 📸');
        } catch (e) {
          print('❌ Ошибка загрузки фото: $e');
          _showSnackBar('Ошибка загрузки фото');
          rethrow;
        } finally {
          // Убираем статус "отправляет фото"
          await ChatService.setSendingPhotoStatus(widget.chatId, false);
        }
      }
    } catch (e) {
      print('❌ Ошибка выбора фото: $e');
      _showSnackBar('Ошибка выбора фото');
    }
  }

  void _startVoiceRecording() async {
    try {
      // Устанавливаем статус "записывает голосовое"
      await ChatService.setRecordingVoiceStatus(widget.chatId, true);
      _showSnackBar('Записываем голосовое... 🎤');
      
      // Симуляция записи (в реальном приложении здесь будет запись аудио)
      await Future.delayed(Duration(seconds: 3));
    } catch (e) {
      print('❌ Ошибка записи голосового: $e');
    } finally {
      // Убираем статус
      await ChatService.setRecordingVoiceStatus(widget.chatId, false);
      _showSnackBar('Голосовые сообщения скоро будут! 🎤');
    }
  }

  void _sendLocation() {
    _showSnackBar('Отправка местоположения скоро будет! 📍');
  }

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

  void _sendTextMessage() {
    final text = _effectiveController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text, 'text');
      _effectiveController.clear();
      setState(() {});
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
          if (_showAttachmentMenu) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentButton(
                    icon: Icons.photo,
                    label: 'Фото',
                    onTap: _sendPhoto,
                  ),
                  _AttachmentButton(
                    icon: Icons.mic,
                    label: 'Голосовое',
                    onTap: _startVoiceRecording,
                  ),
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
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: _toggleAttachmentMenu,
              ),
              Expanded(
                child: TextField(
                  controller: _effectiveController,
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendTextMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
