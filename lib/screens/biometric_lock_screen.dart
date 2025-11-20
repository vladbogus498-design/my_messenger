import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

/// Экран блокировки с биометрической аутентификацией
/// Пока только placeholder, полная интеграция будет позже
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({Key? key}) : super(key: key);

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricService.isAvailable();
    setState(() {
      _biometricAvailable = isAvailable;
    });
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    
    final success = await BiometricService.authenticate(
      reason: 'Разблокируйте приложение для продолжения',
    );

    setState(() => _isAuthenticating = false);

    if (success && mounted) {
      // Возвращаем результат разблокировки родительскому виджету
      // Если экран используется как модальный, можно заменить на pushReplacement
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Аутентификация не удалась'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Приложение заблокировано',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Используйте биометрию для разблокировки',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 48),
                if (_biometricAvailable)
                  ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(_isAuthenticating ? 'Проверка...' : 'Разблокировать'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    'Биометрическая аутентификация недоступна',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

