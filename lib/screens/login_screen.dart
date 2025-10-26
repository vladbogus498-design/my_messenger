import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  bool _validateInputs() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    if (_emailController.text.isEmpty) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите email'
          : 'Enter email');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите корректный email'
          : 'Enter valid email');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите пароль'
          : 'Enter password');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Пароль должен содержать минимум 6 символов'
          : 'Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _createUserProfile(String userId, String email) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'userId': userId,
      'email': email,
      'username': email.split('@')[0],
      'avatarUrl': '',
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'language': languageProvider.currentLanguage,
      'typingStatus': null,
      'bio': '',
    }, SetOptions(merge: true));
  }

  Future<void> _createDemoChats(String userId) async {
    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final demoChats = languageProvider.currentLanguage == 'ru'
          ? [
              {'name': 'Андрей', 'lastMessage': 'Привет! Как дела?'},
              {'name': 'Мама', 'lastMessage': 'Не забудь купить хлеб'},
              {'name': 'Работа', 'lastMessage': 'Совещание в 15:00'},
            ]
          : [
              {'name': 'Andrew', 'lastMessage': 'Hi! How are you?'},
              {'name': 'Mom', 'lastMessage': 'Don\'t forget to buy bread'},
              {'name': 'Work', 'lastMessage': 'Meeting at 3:00 PM'},
            ];

      for (final chat in demoChats) {
        final chatDoc = FirebaseFirestore.instance.collection('chats').doc();
        await chatDoc.set({
          'id': chatDoc.id,
          'name': chat['name'],
          'participants': [userId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': chat['lastMessage'],
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {userId: 0},
        });

        await chatDoc.collection('messages').add({
          'text': chat['lastMessage']!,
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'isRead': false,
        });
      }
    } catch (e) {
      print("❌ ОШИБКА СОЗДАНИЯ ДЕМО-ЧАТОВ: $e");
    }
  }

  Future<void> _auth() async {
    if (!_validateInputs()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await _createUserProfile(
            userCredential.user!.uid, _emailController.text);
        await _createDemoChats(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      String errorMessage = 'Ошибка: ${e.code}';
      if (languageProvider.currentLanguage == 'en') {
        if (e.code == 'user-not-found')
          errorMessage = 'User not found';
        else if (e.code == 'wrong-password')
          errorMessage = 'Wrong password';
        else if (e.code == 'email-already-in-use')
          errorMessage = 'Email already in use';
        else if (e.code == 'weak-password')
          errorMessage = 'Weak password';
        else
          errorMessage = 'Error: ${e.code}';
      } else {
        if (e.code == 'user-not-found')
          errorMessage = 'Пользователь не найден';
        else if (e.code == 'wrong-password')
          errorMessage = 'Неверный пароль';
        else if (e.code == 'email-already-in-use')
          errorMessage = 'Email уже используется';
        else if (e.code == 'weak-password') errorMessage = 'Слабый пароль';
      }
      _showError(errorMessage);
    } catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Произошла ошибка: $e'
          : 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (language) => languageProvider.setLanguage(language),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            ],
            icon: Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFFDC143C),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, size: 60, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(languageProvider.appTitle,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                  color: Color(0xFF1a0000),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = true),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          _isLogin ? Color(0xFFDC143C) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(languageProvider.loginTabText,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          !_isLogin ? Color(0xFFDC143C) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(languageProvider.registerTabText,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: languageProvider.emailLabel,
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'test@gmail.com',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFDC143C))),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: languageProvider.passwordLabel,
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFDC143C))),
              ),
              obscureText: true,
            ),
            SizedBox(height: 25),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _auth,
                child: Text(
                    _isLogin
                        ? languageProvider.loginButtonText
                        : languageProvider.registerButtonText,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFFDC143C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
