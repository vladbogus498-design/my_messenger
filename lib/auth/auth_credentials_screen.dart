import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/input_validator.dart';

enum AuthCredentialsMode { signIn, register }

class AuthCredentialsScreen extends ConsumerStatefulWidget {
  const AuthCredentialsScreen({super.key, required this.initialMode});

  final AuthCredentialsMode initialMode;

  @override
  ConsumerState<AuthCredentialsScreen> createState() =>
      _AuthCredentialsScreenState();
}

class _AuthCredentialsScreenState extends ConsumerState<AuthCredentialsScreen> {
  late AuthCredentialsMode _mode;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  String? _validationError;

  bool get _isRegister => _mode == AuthCredentialsMode.register;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _validationError = 'Заполни email и пароль');
      return;
    }

    if (!InputValidator.isValidEmail(email)) {
      setState(() => _validationError = 'Некорректный email');
      return;
    }

    if (password.length < 6) {
      setState(
        () => _validationError = 'Пароль должен быть минимум 6 символов',
      );
      return;
    }

    setState(() => _validationError = null);
    ref.read(authControllerProvider.notifier).clearError();

    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegister) {
      await controller.registerWithEmail(email: email, password: password);
      if (name.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
        await UserService.updateUserData(name: name);
      }
    } else {
      await controller.signInWithEmail(email: email, password: password);
    }

    if (!mounted) return;
    final flowState = ref.read(authControllerProvider);
    if (flowState.errorMessage != null) return;

    if (FirebaseAuth.instance.currentUser != null) {
      ref.invalidate(chatsProvider);
      ref.invalidate(chatsNotifierProvider);
      ref.invalidate(messagesProvider);
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }

  void _switchMode() {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {
      _validationError = null;
      _mode = _isRegister
          ? AuthCredentialsMode.signIn
          : AuthCredentialsMode.register;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authControllerProvider);
    final displayError = _validationError ?? flowState.errorMessage;

    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isRegister ? 'Создать аккаунт' : 'Войти'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Text(
                'DARKKICK',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRegister
                    ? 'Новый профиль. Никакого лишнего шума.'
                    : 'Возвращайся в темную сторону связи.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DarkKickColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 34),
              _GlassPanel(
                child: Column(
                  children: [
                    if (_isRegister) ...[
                      _AuthTextField(
                        controller: _nameController,
                        hint: 'Имя',
                        icon: Icons.person_outline,
                        enabled: !flowState.isLoading,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _AuthTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !flowState.isLoading,
                    ),
                    const SizedBox(height: 14),
                    _AuthTextField(
                      controller: _passwordController,
                      hint: 'Пароль',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      enabled: !flowState.isLoading,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: DarkKickColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: flowState.isLoading
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      ),
                    ),
                    if (displayError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF3B6B,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFFFF3B6B,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: Color(0xFFFF8AA8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SubmitButton(
                      label: _isRegister ? 'Создать аккаунт' : 'Войти',
                      isLoading: flowState.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: flowState.isLoading ? null : _switchMode,
                      child: Text(
                        _isRegister
                            ? 'Уже есть аккаунт? Войти'
                            : 'Нет аккаунта? Создать',
                        style: const TextStyle(
                          color: DarkKickColors.electricPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarkKickColors.divider),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.16),
            blurRadius: 26,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: DarkKickColors.textPrimary),
      cursorColor: DarkKickColors.neonPurple,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: DarkKickColors.textTertiary, size: 21),
        suffixIcon: suffix,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF241050), Color(0xFF7B2CBF), Color(0xFF2E0C61)],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.38),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
