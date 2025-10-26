import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Инициализируем Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase подключен!");

    // АВТОМАТИЧЕСКИ ВХОДИМ АНОНИМНО
    await FirebaseAuth.instance.signInAnonymously();
    print("✅ Вошли анонимно!");

    // Запускаем основное приложение
    runApp(MyApp());
  } catch (e) {
    print("❌ Ошибка: $e");
    // Даже при ошибке показываем приложение
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Ошибка Firebase: $e"),
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
                'Приложение запускается...',
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
