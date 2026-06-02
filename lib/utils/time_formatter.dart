import 'package:intl/intl.dart';

/// Утилита для форматирования времени сообщений
/// Хранит время в UTC, отображает локально
class TimeFormatter {
  /// Форматирует дату для отображения в списке чатов
  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final localTime = dateTime.toLocal();
    final difference = now.difference(localTime);

    if (difference.inDays == 0) {
      // Сегодня - показываем только время
      return DateFormat('HH:mm').format(localTime);
    } else if (difference.inDays == 1) {
      // Вчера
      return 'Вчера';
    } else if (difference.inDays < 7) {
      // Неделя - показываем день недели
      return DateFormat('EEEE', 'ru').format(localTime);
    } else {
      // Старше недели - показываем дату
      return DateFormat('dd.MM.yyyy').format(localTime);
    }
  }

  /// Форматирует дату для отображения в сообщении
  static String formatMessageTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  /// Форматирует полную дату и время
  static String formatFullDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(localTime);
  }

  /// Получает время в UTC для сохранения в Firestore
  static DateTime toUTC(DateTime dateTime) {
    return dateTime.toUtc();
  }

  /// Получает локальное время из UTC
  static DateTime fromUTC(DateTime utcTime) {
    return utcTime.toLocal();
  }
}

