import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/email_phone_verification_service.dart';
import '../utils/logger.dart';

/// OTP Code input widget
/// Поле для ввода 6-значного кода из SMS/Email
class OtpCodeInput extends ConsumerStatefulWidget {
  final String label;
  final Function(String) onCodeSubmitted;
  final bool isLoading;
  final String? errorMessage;

  const OtpCodeInput({
    Key? key,
    required this.label,
    required this.onCodeSubmitted,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  ConsumerState<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends ConsumerState<OtpCodeInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final int _codeLength = 6;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _handleCodeInput(int index, String value) {
    if (value.isEmpty) {
      // Backspace pressed
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Only accept numbers
    if (!RegExp(r'^[0-9]$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    // Move to next field
    if (index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // All digits entered - submit
      _focusNodes[index].unfocus();
      widget.onCodeSubmitted(_code);
    }
  }

  void _clearAll() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _codeLength,
            (index) => SizedBox(
              width: 50,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: !widget.isLoading,
                maxLength: 1,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _handleCodeInput(index, value);
                },
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Error message
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          ),
        ],

        // Clear button
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.isLoading ? null : _clearAll,
            child: const Text('Очистить'),
          ),
        ),

        // Submit button
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : () {
              widget.onCodeSubmitted(_code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Подтвердить код'),
          ),
        ),
      ],
    );
  }
}

/// Email Verification Screen
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    _waitForEmailVerification();
  }

  void _waitForEmailVerification() async {
    final isVerified =
        await EmailVerificationService.waitForEmailVerification();

    if (!mounted) return;

    if (isVerified) {
      // Navigate to main screen
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verification timeout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.mail_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Проверьте вашу почту',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Письмо с ссылкой подтверждения отправлено на:\n${widget.email}',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Loading
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Ожидание подтверждения...',
              style: theme.textTheme.bodySmall,
            ),

            const Spacer(),

            // Resend button
            TextButton(
              onPressed: () async {
                await EmailVerificationService.sendVerificationEmail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Письмо переотправлено'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Переотправить письмо'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone Verification Screen
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
  }) : super(key: key);

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  void _verifyCode(String code) async {
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Код должен содержать 6 цифр';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await PhoneVerificationService.verifySmsCode(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        setState(() {
          _errorMessage = 'Неверный код. Попробуйте снова.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка проверки кода';
          _isLoading = false;
        });
        appLogger.e('Phone verification error', error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение номера'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.sms_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Введите код из SMS',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Код отправлен на номер\n${widget.phoneNumber}',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // OTP Input
            OtpCodeInput(
              label: 'Код подтверждения',
              onCodeSubmitted: _verifyCode,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
            ),
          ],
        ),
      ),
    );
  }
}
