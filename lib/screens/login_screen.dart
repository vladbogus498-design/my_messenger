import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_chat_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String language;

  LoginScreen({required this.language});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
  }

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Map<String, Map<String, String>> _localizations = {
    'ru': {
      'title': 'Вход в аккаунт',
      'subtitle': 'Введите ваш email и пароль',
      'email': 'Email',
      'password': 'Пароль',
      'login_button': 'ВОЙТИ',
      'no_account': 'Нет аккаунта? Зарегистрируйтесь',
      'fill_fields': 'Заполните все поля',
      'invalid_email': 'Введите корректный email (например: user@mail.ru)',
      'user_not_found': 'Аккаунт с таким email не найден',
      'wrong_password': 'Неверный пароль',
      'invalid_email_code': 'Некорректный email',
      'too_many_requests': 'Слишком много попыток. Попробуйте позже',
      'error': 'Ошибка входа',
    },
    'en': {
      'title': 'Login to account',
      'subtitle': 'Enter your email and password',
      'email': 'Email',
      'password': 'Password',
      'login_button': 'LOGIN',
      'no_account': 'No account? Sign up',
      'fill_fields': 'Fill all fields',
      'invalid_email': 'Enter valid email (example: user@mail.com)',
      'user_not_found': 'Account with this email not found',
      'wrong_password': 'Wrong password',
      'invalid_email_code': 'Invalid email',
      'too_many_requests': 'Too many attempts. Try again later',
      'error': 'Login error',
    },
  };

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final texts = _localizations[_currentLanguage]!;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['fill_fields']!)),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['invalid_email']!)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainChatScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = texts['error']!;

      if (e.code == 'user-not-found') {
        errorMessage = texts['user_not_found']!;
      } else if (e.code == 'wrong-password') {
        errorMessage = texts['wrong_password']!;
      } else if (e.code == 'invalid-email') {
        errorMessage = texts['invalid_email_code']!;
      } else if (e.code == 'too-many-requests') {
        errorMessage = texts['too_many_requests']!;
      } else {
        errorMessage = '${texts['error']!}: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${texts['error']!}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizations[_currentLanguage]!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentLanguage == 'ru' ? 'Вход' : 'Login'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text(
                texts['title']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                texts['subtitle']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: texts['email'],
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: texts['password'],
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          texts['login_button']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SignupScreen(language: _currentLanguage)),
                    );
                  },
                  child: Text(
                    texts['no_account']!,
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
