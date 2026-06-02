import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Welcome slide for DarkKick Messenger authentication flow (Slide 1)
/// Displays branding, neon aesthetic, and action buttons to proceed with authentication
class AuthWelcomeSlide extends StatelessWidget {
  /// Callback when "Войти" (Sign In) button is pressed
  final VoidCallback? onSignInPressed;

  /// Callback when "Создать аккаунт" (Create Account) button is pressed
  final VoidCallback? onCreateAccountPressed;

  const AuthWelcomeSlide({
    super.key,
    this.onSignInPressed,
    this.onCreateAccountPressed,
  });

  // DarkKick specific color palette
  static const Color _darkBackground = Color(0xFF07050C);
  static const Color _neonPurple = Color(0xFF9D4EDD);
  static const Color _darkPurple = Color(0xFF4A148C);
  static const Color _brightPurple = Color(0xFF7B2CBF);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.height < 800;

    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Central content block
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing circular container with angel image
                    Container(
                      height: 240,
                      width: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _neonPurple.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/auth_angel.png',
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback: display a simple circular gradient if image not found
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _brightPurple.withOpacity(0.3),
                                  _neonPurple.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: _neonPurple.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),

                    // "DARKKICK" header
                    Text(
                      'DARKKICK',
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 6.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'БЕЗ ГРАНИЦ. БЕЗ СЛЕЖКИ. ЭТО DARKKICK.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom buttons block
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sign In button with gradient background
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_darkPurple, _brightPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _neonPurple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onSignInPressed ?? () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Войти',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Create Account button with outline
                  OutlinedButton(
                    onPressed: onCreateAccountPressed ?? () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Создать аккаунт',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Copyright text and lightning icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Сделано с нуля одним человеком. ',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      Icon(
                        Icons.bolt,
                        size: 14,
                        color: _neonPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
