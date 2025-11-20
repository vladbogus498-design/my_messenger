import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Утилита для валидации и санитизации пользовательского ввода
class InputValidator {
  // Константы для ограничений
  static const int maxMessageLength = 10000;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;
  static const int maxSearchQueryLength = 100;
  static const int maxFileSizeMB = 10; // 10 MB
  static const int maxImageSizeMB = 5; // 5 MB для изображений
  static const int maxVoiceMessageSizeMB = 25; // 25 MB для голосовых

  /// Валидация и санитизация текста сообщения
  static String? validateMessage(String? text) {
    if (text == null || text.isEmpty) {
      return 'Сообщение не может быть пустым';
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Сообщение не может содержать только пробелы';
    }

    if (trimmed.length > maxMessageLength) {
      return 'Сообщение слишком длинное (максимум $maxMessageLength символов)';
    }

    // Проверка на потенциально опасные паттерны
    if (_containsSuspiciousPatterns(trimmed)) {
      appLogger.w('Suspicious pattern detected in message');
      // Не блокируем, но логируем
    }

    return null; // Валидация пройдена
  }

  /// Санитизация текста сообщения (удаление опасных символов)
  static String sanitizeMessage(String text) {
    // Удаляем нулевые байты и другие опасные символы
    var sanitized = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Ограничиваем длину
    if (sanitized.length > maxMessageLength) {
      sanitized = sanitized.substring(0, maxMessageLength);
    }

    return sanitized.trim();
  }

  /// Валидация имени пользователя
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Имя не может быть пустым';
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Имя не может содержать только пробелы';
    }

    if (trimmed.length > maxNameLength) {
      return 'Имя слишком длинное (максимум $maxNameLength символов)';
    }

    // Проверка на допустимые символы (буквы, цифры, пробелы, некоторые спецсимволы)
    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ0-9\s\-_\.]+$').hasMatch(trimmed)) {
      return 'Имя содержит недопустимые символы';
    }

    return null;
  }

  /// Санитизация имени пользователя
  static String sanitizeName(String name) {
    // Удаляем опасные символы, оставляем только безопасные
    var sanitized = name.replaceAll(RegExp(r'[^\w\s\-_\.а-яА-ЯёЁ]', unicode: true), '');
    
    // Удаляем множественные пробелы
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Ограничиваем длину
    if (sanitized.length > maxNameLength) {
      sanitized = sanitized.substring(0, maxNameLength);
    }

    return sanitized.trim();
  }

  /// Валидация bio
  static String? validateBio(String? bio) {
    if (bio == null || bio.isEmpty) {
      return null; // Bio опционально
    }

    if (bio.length > maxBioLength) {
      return 'Описание слишком длинное (максимум $maxBioLength символов)';
    }

    return null;
  }

  /// Санитизация bio
  static String sanitizeBio(String bio) {
    // Удаляем опасные символы
    var sanitized = bio.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Ограничиваем длину
    if (sanitized.length > maxBioLength) {
      sanitized = sanitized.substring(0, maxBioLength);
    }

    return sanitized.trim();
  }

  /// Валидация и санитизация поискового запроса (защита от NoSQL injection)
  static String sanitizeSearchQuery(String query) {
    if (query.isEmpty) return '';
    
    // Удаляем специальные символы, которые могут использоваться в NoSQL injection
    // Firestore использует isGreaterThanOrEqualTo и isLessThan, поэтому нужно быть осторожным
    var sanitized = query.trim();
    
    // Удаляем нулевые байты и другие опасные символы
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Ограничиваем длину
    if (sanitized.length > maxSearchQueryLength) {
      sanitized = sanitized.substring(0, maxSearchQueryLength);
    }

    // Удаляем символы, которые могут вызвать проблемы в запросах
    // Но оставляем обычные символы для поиска
    sanitized = sanitized.replaceAll(RegExp(r'[<>{}[\]\\]'), '');

    return sanitized.trim();
  }

  /// Валидация размера файла
  static String? validateFileSize(int fileSizeBytes, {bool isImage = false, bool isVoice = false}) {
    final maxSizeMB = isImage 
        ? maxImageSizeMB 
        : (isVoice ? maxVoiceMessageSizeMB : maxFileSizeMB);
    
    final fileSizeMB = fileSizeBytes / (1024 * 1024);
    
    if (fileSizeMB > maxSizeMB) {
      return 'Файл слишком большой (максимум ${maxSizeMB}MB)';
    }

    return null;
  }

  /// Валидация email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email не может быть пустым';
    }

    final trimmed = email.trim().toLowerCase();
    
    // Базовая проверка формата email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Неверный формат email';
    }

    if (trimmed.length > 254) { // RFC 5321
      return 'Email слишком длинный';
    }

    return null;
  }

  /// Валидация chatId
  static bool isValidChatId(String chatId) {
    if (chatId.isEmpty) return false;
    
    // ChatId должен быть непустой строкой без опасных символов
    if (chatId.length > 100) return false;
    
    // Проверяем, что это безопасный ID (только буквы, цифры, дефисы, подчеркивания)
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(chatId);
  }

  /// Валидация userId
  static bool isValidUserId(String userId) {
    if (userId.isEmpty) return false;
    
    // Firebase UID обычно 28 символов, но проверяем до 128
    if (userId.length > 128) return false;
    
    // Firebase UID содержит только безопасные символы
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId);
  }

  /// Проверка на подозрительные паттерны (для логирования)
  static bool _containsSuspiciousPatterns(String text) {
    // Проверка на потенциально опасные паттерны
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onerror=, onclick= и т.д.
      RegExp(r'data:text/html', caseSensitive: false),
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Санитизация текста для отображения (удаление HTML тегов)
  static String sanitizeForDisplay(String text) {
    // Удаляем HTML теги (базовая защита)
    var sanitized = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Экранируем специальные символы
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    return sanitized;
  }
}

