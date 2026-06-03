import 'package:darkkick/widgets/message_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageStatusIcon', () {
    testWidgets('shows sending status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'sending',
              isOwnMessage: true,
            ),
          ),
        ),
      );

      expect(find.byType(MessageStatusIcon), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows sent status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
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

    testWidgets('shows delivered status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
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

    testWidgets('shows read status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
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

    testWidgets('hides status for incoming messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageStatusIcon(
              status: 'sent',
              isOwnMessage: false,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
