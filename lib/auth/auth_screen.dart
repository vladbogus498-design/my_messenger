import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';
import 'auth_credentials_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthCredentialsScreen(
          initialMode: AuthCredentialsMode.signIn,
        ),
      ),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthCredentialsScreen(
          initialMode: AuthCredentialsMode.register,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.12),
                    DarkKickColors.deepBackground.withValues(alpha: 0.8),
                    DarkKickColors.deepBackground,
                  ],
                  stops: const [0, 0.48, 0.76, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'DARKKICK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 7,
                      shadows: [
                        Shadow(
                          color: DarkKickColors.neonPurple.withValues(alpha: 0.75),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'БЕЗ ГРАНИЦ. БЕЗ СЛЕЖКИ. ЭТО '),
                        TextSpan(
                          text: 'DARKKICK.',
                          style: TextStyle(color: DarkKickColors.electricPurple),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _NeonButton(
                    label: 'Войти',
                    onPressed: () => _openSignIn(context),
                  ),
                  const SizedBox(height: 14),
                  _GhostButton(
                    label: 'Создать аккаунт',
                    onPressed: () => _openRegister(context),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Сделано с нуля одним человеком.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.42),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome,
                        size: 17,
                        color: DarkKickColors.neonPurple.withValues(alpha: 0.9),
                      ),
                    ],
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

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B0D65), Color(0xFF7B2CBF), Color(0xFF3C0D78)],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.62),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(label),
    );
  }
}
