import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'main_chat_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _currentLanguage = 'ru';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainChatScreen()),
        );
      }
    });
  }

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'welcome': 'Добро пожаловать!',
      'choose_action': 'Выберите действие',
      'login': 'ВОЙТИ',
      'signup': 'ЗАРЕГИСТРИРОВАТЬСЯ',
      'anonymous': 'Войти анонимно',
    },
    'en': {
      'welcome': 'Welcome!',
      'choose_action': 'Choose action',
      'login': 'LOGIN',
      'signup': 'SIGN UP',
      'anonymous': 'Login anonymously',
    },
  };

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizations[_currentLanguage]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Text(
              _currentLanguage == 'ru' ? 'EN' : 'RU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: _switchLanguage,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                texts['welcome']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                texts['choose_action']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              LoginScreen(language: _currentLanguage)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    texts['login']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SignupScreen(language: _currentLanguage)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    texts['signup']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInAnonymously();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                },
                child: Text(
                  texts['anonymous']!,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
