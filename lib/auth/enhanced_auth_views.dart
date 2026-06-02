import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/email_phone_verification_service.dart';
import '../widgets/otp_verification_widgets.dart';
import '../widgets/primary_button.dart';
import '../utils/input_validator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced Email Registration with verification
class EnhancedEmailAuthView extends ConsumerStatefulWidget {
  const EnhancedEmailAuthView({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedEmailAuthView> createState() =>
      _EnhancedEmailAuthViewState();
}

class _EnhancedEmailAuthViewState
    extends ConsumerState<EnhancedEmailAuthView> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailRegistration() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Заполните все поля');
      return;
    }

    if (!InputValidator.isValidEmail(email)) {
      setState(() => _errorMessage = 'Некорректный email');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Пароль минимум 6 символов');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authController = ref.read(enhancedAuthControllerProvider.notifier);
      
      await authController.registerWithEmail(
        email: email,
        password: password,
      );

      // After registration, navigate based on state
      if (!mounted) return;

      final state = ref.read(enhancedAuthControllerProvider);
      
      if (state.currentStatus == AuthStatus.authenticated) {
        // Success - go to main
        Navigator.of(context).pushReplacementNamed('/main');
      } else if (state.currentStatus == AuthStatus.emailVerificationNeeded) {
        // Navigate to email verification screen
        Navigator.of(context).pushReplacementNamed(
          '/email-verification',
          arguments: email,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка регистрации: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email адрес',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Password field
          TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Пароль (минимум 6 символов)',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Register button
          PrimaryButton(
            text: 'Зарегистрироваться',
            isLoading: _isLoading,
            onPressed: _handleEmailRegistration,
          ),
          const SizedBox(height: 16),

          // Login link
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Уже есть аккаунт? ',
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'Войти',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Phone Registration with SMS verification
class EnhancedPhoneAuthView extends ConsumerStatefulWidget {
  const EnhancedPhoneAuthView({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedPhoneAuthView> createState() =>
      _EnhancedPhoneAuthViewState();
}

class _EnhancedPhoneAuthViewState
    extends ConsumerState<EnhancedPhoneAuthView> {
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneRegistration() async {
    final phone = _phoneController.text.trim();

    // Validate
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Введите номер телефона');
      return;
    }

    // Simple validation - just check it's a number
    if (!RegExp(r'^\+?[0-9\s\-\(\)]{10,}$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Некорректный номер телефона');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authController = ref.read(enhancedAuthControllerProvider.notifier);
      
      await authController.registerWithPhone(phoneNumber: phone);

      if (!mounted) return;

      final state = ref.read(enhancedAuthControllerProvider);

      if (state.currentStatus == AuthStatus.phoneVerificationNeeded) {
        // Navigate to phone verification screen
        Navigator.of(context).pushReplacementNamed(
          '/phone-verification',
          arguments: {
            'phone': phone,
            'verificationId': state.verificationId,
          },
        );
      } else if (state.currentStatus == AuthStatus.error) {
        setState(() {
          _isLoading = false;
          _errorMessage = state.errorMessage ?? 'Ошибка отправки СМС';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone field
          TextField(
            controller: _phoneController,
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+7 (999) 999-99-99',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary),
            ),
            child: Text(
              'На этот номер будет отправлен код подтверждения по СМС',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Register button
          PrimaryButton(
            text: 'Отправить код',
            isLoading: _isLoading,
            onPressed: _handlePhoneRegistration,
          ),
          const SizedBox(height: 16),

          // Login link
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Уже есть аккаунт? ',
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'Войти',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
