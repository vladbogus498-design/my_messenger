/// Enum для типов сообщений (защита от невалидных типов)
enum MessageType {
  text,
  image,
  voice,
  sticker;

  /// Преобразование в строку для Firestore
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.sticker:
        return 'sticker';
    }
  }

  /// Создание из строки (с валидацией)
  static MessageType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'sticker':
        return MessageType.sticker;
      default:
        return null; // Невалидный тип
    }
  }

  /// Проверка валидности типа сообщения
  static bool isValid(String? type) {
    return fromString(type) != null;
  }

  /// Получение всех валидных типов
  static List<String> get validTypes => [
        'text',
        'image',
        'voice',
        'sticker',
      ];
}

