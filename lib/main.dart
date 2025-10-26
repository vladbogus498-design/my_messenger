import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Импортируем твои экраны
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/main_chat_screen.dart';
import 'screens/user_search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase подключен!");

    await FirebaseAuth.instance.signInAnonymously();
    print("✅ Вошли анонимно!");

    runApp(MyApp());
  } catch (e) {
    print("❌ Ошибка: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text("Ошибка: $e")),
        ),
      ),
    );
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
      home: AuthWrapper(), // Используем твой AuthWrapper для навигации
    );
  }
}
