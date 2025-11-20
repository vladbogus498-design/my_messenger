import 'dart:async';
import '../utils/logger.dart';

/// Базовый rate limiter на клиенте для защиты от злоупотреблений
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests;
  final Duration timeWindow;

  RateLimiter({
    required this.maxRequests,
    required this.timeWindow,
  });

  /// Проверка, можно ли выполнить запрос
  bool canMakeRequest(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];

    // Удаляем старые запросы вне временного окна
    final validRequests = requests.where((time) {
      return now.difference(time) < timeWindow;
    }).toList();

    _requests[key] = validRequests;

    if (validRequests.length >= maxRequests) {
      appLogger.w('Rate limit exceeded for key: $key');
      return false;
    }

    return true;
  }

  /// Регистрация запроса
  void recordRequest(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];
    requests.add(now);
    _requests[key] = requests;
  }

  /// Попытка выполнить запрос (проверка + регистрация)
  bool tryRequest(String key) {
    if (canMakeRequest(key)) {
      recordRequest(key);
      return true;
    }
    return false;
  }

  /// Очистка старых записей
  void cleanup() {
    final now = DateTime.now();
    _requests.removeWhere((key, requests) {
      final validRequests = requests.where((time) {
        return now.difference(time) < timeWindow;
      }).toList();
      
      if (validRequests.isEmpty) {
        return true; // Удаляем ключ если нет валидных запросов
      }
      _requests[key] = validRequests;
      return false;
    });
  }

  /// Очистка всех записей для ключа
  void clear(String key) {
    _requests.remove(key);
  }

  /// Очистка всех записей
  void clearAll() {
    _requests.clear();
  }
}

/// Глобальные rate limiters для разных типов операций
class AppRateLimiters {
  // Ограничение на отправку сообщений: 30 сообщений в минуту
  static final messageLimiter = RateLimiter(
    maxRequests: 30,
    timeWindow: const Duration(minutes: 1),
  );

  // Ограничение на поиск пользователей: 20 запросов в минуту
  static final searchLimiter = RateLimiter(
    maxRequests: 20,
    timeWindow: const Duration(minutes: 1),
  );

  // Ограничение на загрузку файлов: 10 файлов в минуту
  static final uploadLimiter = RateLimiter(
    maxRequests: 10,
    timeWindow: const Duration(minutes: 1),
  );

  // Ограничение на создание чатов: 5 чатов в минуту
  static final chatCreationLimiter = RateLimiter(
    maxRequests: 5,
    timeWindow: const Duration(minutes: 1),
  );

  // Периодическая очистка старых записей
  static Timer? _cleanupTimer;

  static void startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      messageLimiter.cleanup();
      searchLimiter.cleanup();
      uploadLimiter.cleanup();
      chatCreationLimiter.cleanup();
    });
  }

  static void stopCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}

