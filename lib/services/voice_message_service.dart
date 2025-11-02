import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Сервис для записи и воспроизведения голосовых сообщений
class VoiceMessageService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _recordingTimer;
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentPlayingId;
  static StreamSubscription? _playerCompleteSubscription;

  // Запрос разрешения на запись
  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Запись голосового сообщения
  static Future<String?> recordVoiceMessage({
    required void Function(Duration duration) onDurationUpdate,
    required void Function(List<double> waveform) onWaveformUpdate,
  }) async {
    if (_isRecording) {
      print('⚠️ Already recording');
      return null;
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print('❌ Microphone permission denied');
      return null;
    }

    try {
      _isRecording = true;

      // Получаем путь для временного файла
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/voice_$timestamp.m4a';

      // Симуляция записи (в реальном приложении используйте microphone package)
      // Здесь просто создаем заглушку для демонстрации
      int tickCount = 0;

      _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        tickCount++;
        final recordingDuration = Duration(milliseconds: tickCount * 100);
        onDurationUpdate(recordingDuration);

        // Симуляция waveform
        final waveform =
            List.generate(20, (_) => 0.3 + (0.7 * (tickCount % 10) / 10));
        onWaveformUpdate(waveform);
      });

      // В реальном приложении здесь должна быть запись через microphone package
      // Для демонстрации возвращаем путь к файлу
      return filePath;
    } catch (e) {
      print('❌ Error recording voice: $e');
      _isRecording = false;
      return null;
    }
  }

  // Остановка записи
  static Future<Uint8List?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;

    // В реальном приложении здесь должна быть остановка записи
    // Для демонстрации возвращаем пустой байт-массив
    // В реальности здесь будет чтение записанного файла
    return Uint8List(0);
  }

  // Конвертация аудио в base64
  static Future<String> encodeAudioToBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error encoding audio: $e');
      rethrow;
    }
  }

  // Конвертация base64 в аудио файл
  static Future<String> decodeBase64ToAudio(String base64String) async {
    try {
      final bytes = base64Decode(base64String);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/voice_playback_$timestamp.m4a';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      print('❌ Error decoding audio: $e');
      rethrow;
    }
  }

  // Воспроизведение голосового сообщения
  static Future<void> playVoiceMessage(
      String base64Audio, String messageId) async {
    if (_isPlaying && _currentPlayingId == messageId) {
      // Если уже воспроизводится этот же файл - останавливаем
      await stopPlaying();
      return;
    }

    try {
      // Останавливаем предыдущее воспроизведение
      if (_isPlaying) {
        await stopPlaying();
      }

      _isPlaying = true;
      _currentPlayingId = messageId;

      // Конвертируем base64 в файл
      final filePath = await decodeBase64ToAudio(base64Audio);

      // Отменяем предыдущую подписку, если есть
      await _playerCompleteSubscription?.cancel();

      // Воспроизводим через audioplayers
      // Для локальных файлов используем UrlSource с file:// протоколом
      final fileUri = Uri.file(filePath).toString();
      await _audioPlayer.play(UrlSource(fileUri));

      // Слушаем завершение воспроизведения
      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingId = null;
      }, onError: (error) {
        print('❌ Error during playback: $error');
        _isPlaying = false;
        _currentPlayingId = null;
      });
    } catch (e) {
      print('❌ Error playing voice: $e');
      _isPlaying = false;
      _currentPlayingId = null;
    }
  }

  // Остановка воспроизведения
  static Future<void> stopPlaying() async {
    try {
      await _playerCompleteSubscription?.cancel();
      _playerCompleteSubscription = null;
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPlayingId = null;
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }

  // Проверка, воспроизводится ли сообщение
  static bool isPlayingMessage(String messageId) {
    return _isPlaying && _currentPlayingId == messageId;
  }

  // Получение статуса записи
  static bool get isRecordingStatus => _isRecording;

  // Получение статуса воспроизведения
  static bool get isPlayingStatus => _isPlaying;
}
