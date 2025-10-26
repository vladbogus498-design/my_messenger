import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ПРОСТАЯ ИНИЦИАЛИЗАЦИЯ БЕЗ OPTIONS
    await Firebase.initializeApp();
    print("✅ Firebase подключен!");

    // АНОНИМНЫЙ ВХОД
    await FirebaseAuth.instance.signInAnonymously();
    print("✅ Вошли анонимно!");

    runApp(MyApp());
  } catch (e) {
    print("❌ Ошибка: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Ошибка: $e"),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.green,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Приложение РАБОТАЕТ!',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
