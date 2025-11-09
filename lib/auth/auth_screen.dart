import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../screens/main_chat_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainChatScreen()),
          );
        }
      });
    });

    ref.listen<AuthFlowState>(authControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final gradient = LinearGradient(
      colors: [
        colorScheme.primary.withOpacity(0.12),
        colorScheme.surface,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _AnimatedHeader(tabIndex: _tabController.index),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добро пожаловать',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Войдите с помощью номера телефона или электронной почты — выберите удобный способ.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTabBar(context),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        _PhoneAuthView(),
                        _EmailAuthView(),
                      ],
                    ),
                  ),
                ],
              ),
              if (authState.isLoading)
                AnimatedOpacity(
                  opacity: authState.isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    color: Colors.black.withOpacity(0.18),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
          ),
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Телефон'),
            Tab(text: 'Email'),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  const _AnimatedHeader({required this.tabIndex});

  final int tabIndex;

  static const _lottieScenes = [
    'https://assets9.lottiefiles.com/packages/lf20_kyu6j0i3.json',
    'https://assets7.lottiefiles.com/packages/lf20_u4jjb9bd.json',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          child: Lottie.network(
            _lottieScenes[tabIndex % _lottieScenes.length],
            key: ValueKey(tabIndex),
            repeat: true,
            frameRate: FrameRate.max,
          ),
        ),
      ),
    );
  }
}

class _EmailAuthView extends ConsumerStatefulWidget {
  const _EmailAuthView();

  @override
  ConsumerState<_EmailAuthView> createState() => _EmailAuthViewState();
}

class _EmailAuthViewState extends ConsumerState<_EmailAuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignUp = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authController = ref.read(authControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    isActive: !_isSignUp,
                    label: 'Войти',
                      onTap: () {
                        if (_isSignUp) {
                          setState(() => _isSignUp = false);
                          authController.clearError();
                        }
                      },
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    isActive: _isSignUp,
                    label: 'Регистрация',
                      onTap: () {
                        if (!_isSignUp) {
                          setState(() => _isSignUp = true);
                          authController.clearError();
                        }
                      },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.alternate_email),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onChanged: (_) {
              _clearLocalError();
              authController.clearError();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onChanged: (_) {
              _clearLocalError();
              authController.clearError();
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Повторите пароль',
                prefixIcon: const Icon(Icons.lock),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onChanged: (_) {
                _clearLocalError();
                authController.clearError();
              },
            ),
          ],
          if (_localError != null) ...[
            const SizedBox(height: 16),
            Text(
              _localError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (authState.errorMessage != null && _localError == null) ...[
            const SizedBox(height: 12),
            Text(
              authState.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              if (_validateInputs()) {
                if (_isSignUp) {
                  await authController.registerWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                } else {
                  await authController.signInWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSignUp ? 'Создать аккаунт' : 'Войти',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              authController.clearError();
              final email = _emailController.text.trim();
              if (email.isEmpty) {
                setState(() {
                  _localError = 'Введите email для восстановления пароля.';
                });
                return;
              }
              await ref
                  .read(appAuthServiceProvider)
                  .sendPasswordReset(email)
                  .then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ссылка для сброса пароля отправлена.'),
                  ),
                );
              });
            },
            child: const Text('Забыли пароль?'),
          ),
        ],
      ),
    );
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Введите корректный email.');
      return false;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Пароль должен быть не короче 6 символов.');
      return false;
    }
    if (_isSignUp && password != _confirmController.text.trim()) {
      setState(() => _localError = 'Пароли не совпадают.');
      return false;
    }
    return true;
  }

  void _clearLocalError() {
    if (_localError != null) {
      setState(() => _localError = null);
    }
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneAuthView extends ConsumerStatefulWidget {
  const _PhoneAuthView();

  @override
  ConsumerState<_PhoneAuthView> createState() => _PhoneAuthViewState();
}

class _PhoneAuthViewState extends ConsumerState<_PhoneAuthView> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCodeStep = state.codeSent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Введите номер телефона',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Мы отправим SMS с кодом подтверждения. Это займёт пару секунд.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()]'))
            ],
            decoration: InputDecoration(
              labelText: 'Номер телефона',
              prefixIcon: const Icon(Icons.phone_rounded),
              hintText: '+7 900 000-00-00',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onChanged: (_) => controller.clearError(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              await controller.sendPhoneCode(_phoneController.text);
            },
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Отправить код'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (isCodeStep) ...[
            const SizedBox(height: 28),
            Text(
              'Введите код из SMS',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Код подтверждения',
                counterText: '',
                prefixIcon: const Icon(Icons.verified_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onChanged: (_) => controller.clearError(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await controller.verifySmsCode(_codeController.text);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Подтвердить код'),
            ),
            TextButton(
              onPressed: controller.resetPhoneFlow,
              child: const Text('Изменить номер'),
            ),
          ],
          if (state.isPhoneVerified)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Телефон подтверждён. Добро пожаловать!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

