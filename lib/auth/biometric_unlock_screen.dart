import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import '../utils/navigation_animations.dart';
import '../screens/main_screen.dart';
import 'auth_screen.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    final success = await BiometricService.authenticate(
      reason: 'Войдите по отпечатку пальца',
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        NavigationAnimations.slideFadeRoute(MainScreen()),
      );
    } else {
      setState(() {
        _isAuthenticating = false;
        _error = 'Не удалось подтвердить личность. Попробуйте снова.';
      });
    }
  }

  Future<void> _disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBiometric', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      NavigationAnimations.slideFadeRoute(const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.fingerprint,
                color: colorScheme.primary,
                size: 96,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Подтвердите вход',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Используйте биометрию, чтобы продолжить.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.refresh),
                label: const Text('Попробовать снова'),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _disableBiometrics,
              child: const Text('Использовать пароль'),
            ),
          ],
        ),
      ),
    );
  }
}


