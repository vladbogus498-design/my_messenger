import 'package:darkkick/utils/time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeFormatter', () {
    test('formats message time', () {
      final formatted = TimeFormatter.formatMessageTime(DateTime.now());

      expect(formatted, matches(r'\d{2}:\d{2}'));
    });

    test('formats chat time for today', () {
      final formatted = TimeFormatter.formatChatTime(DateTime.now());

      expect(formatted, matches(r'\d{2}:\d{2}'));
    });

    test('converts time to UTC and back', () {
      final localTime = DateTime.now();
      final utcTime = TimeFormatter.toUTC(localTime);
      final convertedBack = TimeFormatter.fromUTC(utcTime);

      expect(convertedBack.year, localTime.year);
      expect(convertedBack.month, localTime.month);
      expect(convertedBack.day, localTime.day);
      expect(convertedBack.hour, localTime.hour);
      expect(convertedBack.minute, localTime.minute);
    });

    test('formats full date and time', () {
      final formatted = TimeFormatter.formatFullDateTime(
        DateTime(2024, 1, 15, 14, 30),
      );

      expect(formatted, contains('15.01.2024'));
      expect(formatted, contains('14:30'));
    });
  });
}
