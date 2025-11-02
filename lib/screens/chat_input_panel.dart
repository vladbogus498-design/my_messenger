import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import '../services/voice_message_service.dart';
import '../widgets/sticker_picker.dart';

class ChatInputPanel extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final Function(String, String) onSendMessage;
  final Function(String) onImageUpload;
  final Function(String, int)? onVoiceMessageSent; // (base64Audio, duration)
  final Function(String)? onStickerSent; // (stickerId)
  final TextEditingController? typingController;

  const ChatInputPanel({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.onSendMessage,
    required this.onImageUpload,
    this.onVoiceMessageSent,
    this.onStickerSent,
    this.typingController,
  }) : super(key: key);

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _showAttachmentMenu = false;
  bool _isRecording = false;
  bool _showStickerPicker = false;
  Duration _recordingDuration = Duration.zero;
  List<double> _waveform = [];
  Timer? _waveformTimer;
  String? _recordingFilePath;

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

  Future<void> _startVoiceRecording() async {
    if (_isRecording) return;

    try {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _waveform = [];
      });

      await ChatService.setRecordingVoiceStatus(widget.chatId, true);

      _recordingFilePath = await VoiceMessageService.recordVoiceMessage(
        onDurationUpdate: (duration) {
          if (mounted) {
            setState(() {
              _recordingDuration = duration;
            });
          }
        },
        onWaveformUpdate: (waveform) {
          if (mounted) {
            setState(() {
              _waveform = waveform;
            });
          }
        },
      );

      if (_recordingFilePath == null) {
        throw Exception('Failed to start recording');
      }
    } catch (e) {
      print('❌ Ошибка записи голосового: $e');
      setState(() {
        _isRecording = false;
      });
      await ChatService.setRecordingVoiceStatus(widget.chatId, false);
      _showSnackBar('Ошибка записи');
    }
  }

  Future<void> _stopVoiceRecording({bool send = true}) async {
    if (!_isRecording) return;

    try {
      final audioBytes = await VoiceMessageService.stopRecording();
      
      setState(() {
        _isRecording = false;
      });

      await ChatService.setRecordingVoiceStatus(widget.chatId, false);

      if (send && audioBytes != null && _recordingFilePath != null) {
        // Конвертируем аудио в base64
        final base64Audio = await VoiceMessageService.encodeAudioToBase64(_recordingFilePath!);
        final durationSeconds = _recordingDuration.inSeconds;

        // Отправляем голосовое сообщение
        if (widget.onVoiceMessageSent != null) {
          widget.onVoiceMessageSent!(base64Audio, durationSeconds);
        }

        _showSnackBar('Голосовое сообщение отправлено! 🎤');
      }

      setState(() {
        _recordingDuration = Duration.zero;
        _waveform = [];
        _recordingFilePath = null;
      });
    } catch (e) {
      print('❌ Ошибка остановки записи: $e');
      _showSnackBar('Ошибка отправки голосового');
    }
  }

  void _sendSticker(String stickerId) {
    if (widget.onStickerSent != null) {
      widget.onStickerSent!(stickerId);
    }
    setState(() {
      _showStickerPicker = false;
    });
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
  void dispose() {
    _waveformTimer?.cancel();
    if (_isRecording) {
      _stopVoiceRecording(send: false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Визуализация записи голосового сообщения
        if (_isRecording) _buildRecordingWidget(),
        
        // Пicker стикеров
        if (_showStickerPicker)
          StickerPicker(
            onStickerSelected: _sendSticker,
            onDismiss: () => setState(() => _showStickerPicker = false),
          ),
        
        Container(
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
                    onTap: _isRecording ? () => _stopVoiceRecording() : _startVoiceRecording,
                  ),
                  _AttachmentButton(
                    icon: Icons.emoji_emotions,
                    label: 'Стикер',
                    onTap: () => setState(() => _showStickerPicker = !_showStickerPicker),
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
    ),
      ],
    );
  }

  Widget _buildRecordingWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.red.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Запись...',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                SizedBox(height: 4),
                // Визуализация waveform
                if (_waveform.isNotEmpty)
                  Row(
                    children: _waveform.map((value) {
                      return Container(
                        width: 3,
                        height: value * 30,
                        margin: EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(height: 4),
                Text(
                  '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.red),
            onPressed: () => _stopVoiceRecording(send: true),
            tooltip: 'Отправить',
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.grey),
            onPressed: () => _stopVoiceRecording(send: false),
            tooltip: 'Отменить',
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
