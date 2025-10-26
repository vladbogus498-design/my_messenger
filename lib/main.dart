import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ИМПОРТИРУЕМ ТВОИ ЭКРАНЫ
import 'screens/login_screen.dart';
import 'screens/main_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // Пробуем анонимный вход
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print("Анонимный вход не сработал: $e");
    }

    runApp(MyApp());
  } catch (e) {
    // Даже при ошибке запускаем
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Messenger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Если грузится - показываем загрузку
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Если пользователь есть - показываем чаты
          if (snapshot.hasData) {
            return MainChatScreen(); // ТВОЙ ГЛАВНЫЙ ЭКРАН ЧАТОВ!
          }

          // Если нет - показываем логин
          return LoginScreen(); // ТВОЙ ЭКРАН ВХОДА
        },
      ),
    );
  }
}
