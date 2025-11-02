import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_chat_screen.dart';
import 'login_screen.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  final String language;

  SignupScreen({required this.language});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
      'title': 'Создать аккаунт',
      'subtitle': 'Заполните данные для регистрации',
      'email': 'Email',
      'password': 'Пароль',
      'confirm_password': 'Подтвердите пароль',
      'signup_button': 'ЗАРЕГИСТРИРОВАТЬСЯ',
      'has_account': 'Уже есть аккаунт? Войдите',
      'fill_fields': 'Заполните все поля',
      'passwords_not_match': 'Пароли не совпадают',
      'invalid_email': 'Введите корректный email (например: user@mail.ru)',
      'email_already_used': 'Этот email уже используется',
      'weak_password': 'Пароль слишком слабый (минимум 6 символов)',
      'error': 'Ошибка регистрации',
    },
    'en': {
      'title': 'Create account',
      'subtitle': 'Fill data for registration',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm password',
      'signup_button': 'SIGN UP',
      'has_account': 'Already have account? Login',
      'fill_fields': 'Fill all fields',
      'passwords_not_match': 'Passwords do not match',
      'invalid_email': 'Enter valid email (example: user@mail.com)',
      'email_already_used': 'This email is already in use',
      'weak_password': 'Password is too weak (minimum 6 characters)',
      'error': 'Registration error',
    },
  };

  void _switchLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ru' ? 'en' : 'ru';
    });
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final texts = _localizations[_currentLanguage]!;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['fill_fields']!)),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['passwords_not_match']!)),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['invalid_email']!)),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['weak_password']!)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Создаем профиль пользователя
      if (userCredential.user != null) {
        final name = email.split('@')[0]; // Используем часть email как имя по умолчанию
        await UserService.createUserProfile(
          userCredential.user!.uid,
          email,
          name,
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainChatScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = texts['error']!;

      if (e.code == 'email-already-in-use') {
        errorMessage = texts['email_already_used']!;
      } else if (e.code == 'weak-password') {
        errorMessage = texts['weak_password']!;
      } else if (e.code == 'invalid-email') {
        errorMessage = texts['invalid_email']!;
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
        title: Text(_currentLanguage == 'ru' ? 'Регистрация' : 'Sign Up'),
        backgroundColor: Colors.green,
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
              SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: texts['confirm_password'],
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
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
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          texts['signup_button']!,
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
                              LoginScreen(language: _currentLanguage)),
                    );
                  },
                  child: Text(
                    texts['has_account']!,
                    style: TextStyle(color: Colors.green),
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
