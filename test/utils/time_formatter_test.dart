import 'package:flutter_test/flutter_test.dart';
import 'package:darkkick/lib/utils/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    test('форматирует время сообщения корректно', () {
      final now = DateTime.now();
      final formatted = TimeFormatter.formatMessageTime(now);
      
      // Проверяем, что формат содержит часы и минуты
      expect(formatted, matches(r'\d{2}:\d{2}'));
    });

    test('форматирует время чата для сегодняшних сообщений', () {
      final now = DateTime.now();
      final formatted = TimeFormatter.formatChatTime(now);
      
      // Сегодняшние сообщения должны показывать только время
      expect(formatted, matches(r'\d{2}:\d{2}'));
    });

    test('конвертирует время в UTC и обратно', () {
      final localTime = DateTime.now();
      final utcTime = TimeFormatter.toUTC(localTime);
      final convertedBack = TimeFormatter.fromUTC(utcTime);
      
      // Проверяем, что конвертация работает корректно
      expect(convertedBack.year, localTime.year);
      expect(convertedBack.month, localTime.month);
      expect(convertedBack.day, localTime.day);
      expect(convertedBack.hour, localTime.hour);
      expect(convertedBack.minute, localTime.minute);
    });

    test('форматирует полную дату и время', () {
      final date = DateTime(2024, 1, 15, 14, 30);
      final formatted = TimeFormatter.formatFullDateTime(date);
      
      expect(formatted, contains('15.01.2024'));
      expect(formatted, contains('14:30'));
    });
  });
}

