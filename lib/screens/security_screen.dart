import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DarkKickColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Безопасность',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DarkKickColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 32),
            _buildFeaturesList(),
            SizedBox(height: 32),
            _buildExploreButton(context),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Без границ.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: DarkKickColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Без слежки.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: DarkKickColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Это ',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: DarkKickColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Darkkick',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: DarkKickColors.neonPurple,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: DarkKickColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DarkKickColors.mediumGray,
                  boxShadow: [
                    BoxShadow(
                      color: DarkKickColors.neonPurple.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: DarkKickColors.neonPurple,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      (
        title: 'Шифрование E2EE',
        description: 'Только ты и собеседник. Никто не прочитает твои сообщения.',
        icon: Icons.lock_outline,
      ),
      (
        title: 'Самоуничтожающиеся сообщения',
        description: 'Выбери время — и след не останется',
        icon: Icons.timer_outlined,
      ),
      (
        title: 'Полная кастомизация',
        description: 'Тема, цвета, шрифты, звуки — приспособь под себя.',
        icon: Icons.palette_outlined,
      ),
      (
        title: 'Анонимность',
        description: 'Никакого номера телефона. Только код, кофе и желание.',
        icon: Icons.person_off_outlined,
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: features.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DarkKickColors.mediumGray,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkKickColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DarkKickColors.darkBackground,
                  border: Border.all(
                    color: DarkKickColors.neonPurple,
                    width: 2,
                  ),
                ),
                child: Icon(
                  feature.icon,
                  color: DarkKickColors.neonPurple,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DarkKickColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: DarkKickColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                color: DarkKickColors.lightGray,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [DarkKickColors.darkPurple, DarkKickColors.brightPurple],
            ),
            boxShadow: [
              BoxShadow(
                color: DarkKickColors.neonPurple.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Исследовать',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
