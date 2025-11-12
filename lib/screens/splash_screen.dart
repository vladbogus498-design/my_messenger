import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_screen.dart';
import '../auth/biometric_unlock_screen.dart';
import '../utils/navigation_animations.dart';
import 'main_chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.wait([
      _controller.forward(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        NavigationAnimations.slideFadeRoute(const AuthScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final useBiometric = prefs.getBool('useBiometric') ?? false;
    if (!mounted) return;

    if (useBiometric) {
      Navigator.pushReplacement(
        context,
        NavigationAnimations.slideFadeRoute(const BiometricUnlockScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        NavigationAnimations.slideFadeRoute(MainChatScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: colorScheme.primary,
                  size: 72,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'DarkKick',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Encrypted messenger with instant access',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
