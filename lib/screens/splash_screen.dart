import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/biometric_service.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    // Минимальная задержка для показа splash screen (оптимизация для мобилок)
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Проверяем, включена ли биометрия
      final prefs = await SharedPreferences.getInstance();
      final useBiometric = prefs.getBool('useBiometric') ?? false;

      if (useBiometric) {
        // Проверяем доступность биометрии перед запросом
        final canAuth = await BiometricService.canAuthenticate();

        if (canAuth) {
          // Показываем биометрическую аутентификацию
          final authenticated = await BiometricService.authenticate();

          if (!mounted) return;

          if (!authenticated) {
            // Если биометрия не прошла (отмена или ошибка), выходим из аккаунта
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            }
            return;
          }
        } else {
          // Биометрия недоступна - отключаем её и продолжаем
          await prefs.setBool('useBiometric', false);
        }
      }

      // Пользователь авторизован - переходим на главный экран
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
    } else {
      // Пользователь не авторизован - переходим на экран авторизации
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    }
  }

  Future<UserModel?> _loadUserAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await UserService.getUserData(user.uid);
      }
    } catch (e) {
      print('Error loading user avatar: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<UserModel?>(
        future: _loadUserAvatar(),
        builder: (context, snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Аватар или логотип
                if (snapshot.hasData && snapshot.data?.photoURL != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: NetworkImage(snapshot.data!.photoURL!),
                  )
                else
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                SizedBox(height: 30),

                // Название приложения
                Text(
                  'DarkKick',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Messages that leave no trace',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                SizedBox(height: 40),

                // Индикатор загрузки
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
