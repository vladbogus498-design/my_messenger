import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🟡 Инициализируем Firebase...');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyC_wZVPV1csibeOs7isMdZeAJjpZ9XO0BQ",
        appId: "1:366138349689:web:58d15e2f8ad82415961ca8",
        messagingSenderId: "366138349689",
        projectId: "darkkickchat-765e0",
        authDomain: "darkkickchat-765e0.firebaseapp.com",
        storageBucket: "darkkickchat-765e0.firebasestorage.app",
      ),
    );
    print('🟢 Firebase инициализирован!');
  } catch (e) {
    print('🔴 Ошибка инициализации Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkKick',
      debugShowCheckedModeBanner: false, // Убираем дебаг баннер
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red[800],
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      home: MainChatScreen(),
    );
  }
}
