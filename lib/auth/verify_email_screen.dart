import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/email_phone_verification_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/logger.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email = ''});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;
      if (refreshedUser?.emailVerified == true) {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        return;
      }

      _showSnackBar('Почта пока не подтверждена');
    } on FirebaseAuthException catch (e) {
      appLogger.e('Email verification check failed: ${e.code}', error: e);
      if (mounted) _showSnackBar('Не удалось проверить почту');
    } catch (e) {
      appLogger.e('Email verification check failed', error: e);
      if (mounted) _showSnackBar('Не удалось проверить почту');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    final sent = await EmailVerificationService.sendVerificationEmail();
    if (!mounted) return;

    setState(() => _isResending = false);
    if (sent) {
      _startCooldown();
      _showSnackBar('Письмо отправлено ещё раз');
    } else {
      _showSnackBar('Не удалось отправить письмо');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
        return;
      }
      setState(() => _cooldownSeconds--);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DarkKickColors.card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isNotEmpty
        ? widget.email
        : FirebaseAuth.instance.currentUser?.email ?? '';
    final resendLabel = _cooldownSeconds > 0
        ? 'Отправить письмо ещё раз ($_cooldownSeconds)'
        : 'Отправить письмо ещё раз';

    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Align(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DarkKickColors.panel,
                    border: Border.all(
                      color: DarkKickColors.stroke,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DarkKickColors.neonPurple.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: DarkKickColors.electricPurple,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Подтвердите почту',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DarkKickColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email.isEmpty
                    ? 'Мы отправили письмо на ваш email'
                    : 'Мы отправили письмо на ваш email\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DarkKickColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 34),
              _VerificationButton(
                label: 'Я подтвердил',
                isPrimary: true,
                isLoading: _isChecking,
                onPressed: _isChecking ? null : _checkVerification,
              ),
              const SizedBox(height: 12),
              _VerificationButton(
                label: resendLabel,
                isLoading: _isResending,
                onPressed: _cooldownSeconds > 0 || _isResending
                    ? null
                    : _resendVerificationEmail,
              ),
              const SizedBox(height: 12),
              _VerificationButton(
                label: 'Выйти',
                isDanger: true,
                onPressed: _signOut,
              ),
              const Spacer(),
              const Text(
                'После подтверждения вернитесь сюда и нажмите "Я подтвердил".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DarkKickColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationButton extends StatelessWidget {
  const _VerificationButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foreground = isDanger
        ? const Color(0xFFFF6B7A)
        : isPrimary
        ? Colors.white
        : DarkKickColors.electricPurple;

    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [
                    Color(0xFF241050),
                    Color(0xFF7B2CBF),
                    Color(0xFF2E0C61),
                  ],
                )
              : null,
          color: isPrimary ? null : DarkKickColors.panel,
          border: Border.all(
            color: isDanger
                ? const Color(0xFFFF3B6B).withValues(alpha: 0.45)
                : DarkKickColors.stroke,
            width: 0.8,
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: foreground,
            disabledForegroundColor: DarkKickColors.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
      ),
    );
  }
}
