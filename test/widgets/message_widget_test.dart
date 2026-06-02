import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darkkick/lib/widgets/message_status_icon.dart';

void main() {
  group('MessageStatusIcon', () {
    testWidgets('отображает иконку отправки для статуса sending', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'sending',
              isOwnMessage: true,
            ),
          ),
        ),
      );

      // Проверяем, что виджет отображается
      expect(find.byType(MessageStatusIcon), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('отображает иконку отправлено для статуса sent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'sent',
              isOwnMessage: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('отображает иконку доставлено для статуса delivered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'delivered',
              isOwnMessage: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('отображает иконку прочитано для статуса read', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'read',
              isOwnMessage: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('не отображается для чужих сообщений', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'sent',
              isOwnMessage: false,
            ),
          ),
        ),
      );

      // Виджет должен быть пустым для чужих сообщений
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

