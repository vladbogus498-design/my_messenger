import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase подключен!");
    runApp(MyApp());
  } catch (e) {
    print("❌ Ошибка Firebase: $e");
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
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
