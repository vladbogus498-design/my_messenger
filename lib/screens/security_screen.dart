import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Darkkick'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 24),
              _FeatureCard(
                icon: Icons.lock,
                title: 'Защита сообщений',
                description:
                    'Приватные чаты и защита доступа развиваются в рамках MVP.',
                trailingIcon: Icons.lock,
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                icon: Icons.timer_outlined,
                title: 'Самоуничтожающиеся сообщения',
                description: 'Выбирай время, и следов не останется.',
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                icon: Icons.auto_awesome,
                title: 'Полная кастомизация',
                description: 'Темы, цвета, шрифты, звуки. Приложение под тебя.',
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                icon: Icons.theater_comedy_outlined,
                title: 'Анонимность',
                description: 'Никакого номера телефона. Только твой ник.',
              ),
              const SizedBox(height: 22),
              _buildSignature(),
              const SizedBox(height: 22),
              _buildExploreButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Без границ.\nБез слежки.\nЭто '),
                TextSpan(
                  text: 'Darkkick',
                  style: TextStyle(
                    color: DarkKickColors.electricPurple,
                    shadows: [
                      Shadow(
                        color: DarkKickColors.neonPurple.withValues(
                          alpha: 0.75,
                        ),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                DarkKickColors.neonPurple.withValues(alpha: 0.48),
                DarkKickColors.card.withValues(alpha: 0.78),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: DarkKickColors.electricPurple,
            size: 58,
          ),
        ),
      ],
    );
  }

  Widget _buildSignature() {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Row(
        children: [
          Text(
            'Сделано с нуля\nодним человеком.',
            style: GoogleFonts.caveat(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 20,
              height: 1,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_upward,
            color: DarkKickColors.textSecondary,
            size: 26,
          ),
          const Spacer(),
          Icon(
            Icons.workspace_premium_outlined,
            color: DarkKickColors.textSecondary.withValues(alpha: 0.72),
            size: 34,
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _buildExploreButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E0B46), Color(0xFF4A148C), Color(0xFF18072F)],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.36),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Исследовать',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.arrow_forward,
                color: DarkKickColors.neonPurple,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.trailingIcon = Icons.arrow_forward_ios,
  });

  final IconData icon;
  final String title;
  final String description;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: DarkKickColors.cardSoft,
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: DarkKickColors.neonPurple, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: DarkKickColors.textSecondary,
                    fontSize: 12,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(trailingIcon, color: DarkKickColors.textTertiary, size: 16),
        ],
      ),
    );
  }
}
