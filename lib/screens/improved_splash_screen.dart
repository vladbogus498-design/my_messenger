import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_screen.dart';
import '../screens/main_chat_screen.dart';
import '../utils/logger.dart';
import 'dart:async';

/// Improved splash screen with instant navigation
/// Не требует перезагрузки приложения!
class ImprovedSplashScreen extends StatefulWidget {
  const ImprovedSplashScreen({super.key});

  @override
  State<ImprovedSplashScreen> createState() => _ImprovedSplashScreenState();
}

class _ImprovedSplashScreenState extends State<ImprovedSplashScreen> {
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // ВАЖНО: Подписываемся на изменения auth прямо при загрузке
    // Это даст мгновенную навигацию БЕЗ перезагрузки приложения
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (!mounted) return;

        appLogger.i('Auth state changed: ${user?.email ?? 'Not signed in'}');

        // Мгновенный переход - БЕЗ задержек!
        if (user != null) {
          // Пользователь авторизован - идём в main chat
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // Пользователь НЕ авторизован - идём на auth
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      },
      onError: (error) {
        appLogger.e('Auth state stream error', error: error);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'DarkKick Messenger',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Загрузка...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
