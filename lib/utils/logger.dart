import 'package:logger/logger.dart';

/// Глобальный логгер для приложения
/// Использует пакет logger для структурированного логирования
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
  level: Level.debug,
);

/// Логгер для продакшена (только ошибки и предупреждения)
final productionLogger = Logger(
  printer: SimplePrinter(colors: false),
  level: Level.warning,
);

