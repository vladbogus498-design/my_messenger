import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
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
    // Небольшая задержка для показа splash screen
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Пользователь авторизован - переходим на главный экран
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } else {
      // Пользователь не авторизован - переходим на экран авторизации
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
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

