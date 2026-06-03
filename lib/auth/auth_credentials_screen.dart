import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/darkkick_colors.dart';
import '../utils/input_validator.dart';

enum AuthCredentialsMode { signIn, register }

/// Базовый экран входа / регистрации (email + пароль).
class AuthCredentialsScreen extends ConsumerStatefulWidget {
  const AuthCredentialsScreen({
    super.key,
    required this.initialMode,
  });

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

  bool get _isRegister => _mode == AuthCredentialsMode.register;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _validationError = 'Заполните email и пароль');
      return;
    }

    if (!InputValidator.isValidEmail(email)) {
      setState(() => _validationError = 'Некорректный email');
      return;
    }

    if (password.length < 6) {
      setState(() => _validationError = 'Пароль минимум 6 символов');
      return;
    }

    setState(() => _validationError = null);
    ref.read(authControllerProvider.notifier).clearError();

    final controller = ref.read(authControllerProvider.notifier);

    if (_isRegister) {
      await controller.registerWithEmail(email: email, password: password);
    } else {
      await controller.signInWithEmail(email: email, password: password);
    }

    if (!mounted) return;

    final flowState = ref.read(authControllerProvider);
    if (flowState.errorMessage != null) return;

    if (FirebaseAuth.instance.currentUser != null) {
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
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DarkKickColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isRegister ? 'Создать аккаунт' : 'Войти',
          style: const TextStyle(
            color: DarkKickColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isRegister
                    ? 'Регистрация в DARKKICK'
                    : 'С возвращением в DARKKICK',
                style: const TextStyle(
                  color: DarkKickColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              if (_isRegister) ...[
                _AuthTextField(
                  controller: _nameController,
                  hint: 'Имя (необязательно)',
                  icon: Icons.person_outline,
                  enabled: !flowState.isLoading,
                ),
                const SizedBox(height: 16),
              ],
              _AuthTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !flowState.isLoading,
              ),
              const SizedBox(height: 16),
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
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              if (displayError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    displayError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SubmitButton(
                label: _isRegister ? 'Создать аккаунт' : 'Войти',
                isLoading: flowState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: flowState.isLoading ? null : _switchMode,
                child: Text(
                  _isRegister
                      ? 'Уже есть аккаунт? Войти'
                      : 'Нет аккаунта? Создать',
                  style: const TextStyle(
                    color: DarkKickColors.neonPurple,
                    fontWeight: FontWeight.w600,
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
        hintStyle: const TextStyle(color: DarkKickColors.textTertiary),
        prefixIcon: Icon(icon, color: DarkKickColors.textTertiary, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: DarkKickColors.mediumGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.brightPurple, width: 1.5),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DarkKickColors.brightPurple,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DarkKickColors.neonPurple,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: DarkKickColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
