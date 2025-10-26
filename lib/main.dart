import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase подключен!");

    // Пробуем анонимный вход, но если ошибка - всё равно запускаем
    try {
      await FirebaseAuth.instance.signInAnonymously();
      print("✅ Вошли анонимно!");
    } catch (e) {
      print("⚠️ Анонимный вход не сработал: $e");
    }

    runApp(MyApp());
  } catch (e) {
    print("❌ Ошибка инициализации: $e");
    // ВСЕГДА запускаем приложение, даже с ошибками
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой Мессенджер',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мой Мессенджер'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 64, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Мессенджер Запущен!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Firebase подключен',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Здесь будет переход к чатам
                },
                child: Text('Начать общение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
