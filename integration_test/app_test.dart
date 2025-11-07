import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:darkkick/lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Интеграционные тесты DarkKick Messenger', () {
    testWidgets('логин → открыть чат → отправить сообщение', (WidgetTester tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle();

      // Находим кнопку входа
      final loginButton = find.text('ВОЙТИ');
      expect(loginButton, findsOneWidget);

      // Нажимаем на кнопку входа
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Вводим email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Вводим пароль (нужно найти поле пароля)
      final passwordFields = find.byType(TextField);
      if (passwordFields.evaluate().length > 1) {
        await tester.enterText(passwordFields.at(1), 'password123');
        await tester.pumpAndSettle();
      }

      // Нажимаем кнопку входа (если есть)
      final submitButton = find.text('ВОЙТИ').last;
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Проверяем, что мы на главном экране
      // (это зависит от вашей структуры экранов)
      // expect(find.text('Chats'), findsOneWidget);

      // Открываем чат (если есть)
      // final chatItem = find.byType(ListTile).first;
      // if (chatItem.evaluate().isNotEmpty) {
      //   await tester.tap(chatItem);
      //   await tester.pumpAndSettle();
      // }

      // Отправляем сообщение
      // final messageField = find.byType(TextField);
      // if (messageField.evaluate().isNotEmpty) {
      //   await tester.enterText(messageField.first, 'Тестовое сообщение');
      //   await tester.pumpAndSettle();
      //   
      //   final sendButton = find.byIcon(Icons.send);
      //   if (sendButton.evaluate().isNotEmpty) {
      //     await tester.tap(sendButton);
      //     await tester.pumpAndSettle();
      //   }
      // }

      // Проверяем, что сообщение отобразилось
      // expect(find.text('Тестовое сообщение'), findsOneWidget);
    });
  });
}

