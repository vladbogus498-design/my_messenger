import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          'Об мне',
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
            SizedBox(height: 24),
            _buildAboutCard(),
            SizedBox(height: 24),
            _buildStatsGrid(),
            SizedBox(height: 24),
            _buildMenuItems(context),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '15 лет.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: DarkKickColors.textPrimary,
                  ),
                ),
                Text(
                  '2 месяца.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: DarkKickColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Одно ',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DarkKickColors.textPrimary,
                      ),
                    ),
                    Text(
                      'приложение.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DarkKickColors.neonPurple,
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
              Icons.crown,
              color: DarkKickColors.neonPurple,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DarkKickColors.mediumGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkKickColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Я — junior разработчик.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DarkKickColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Сделал Darkkick в соло. Без команды. Без слежки. Только код, кофе и желание.',
              style: TextStyle(
                fontSize: 13,
                color: DarkKickColors.textSecondary,
                height: 1.6,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Тольки код, кофе и желание создать что-то своё.',
              style: TextStyle(
                fontSize: 12,
                color: DarkKickColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (title: '50 000+\nстрок кода', icon: Icons.code),
      (title: '60 дней\nбез остановки', icon: Icons.schedule),
      (title: '100%\nв соло', icon: Icons.bolt),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
        children: stats.map((stat) {
          return Container(
            decoration: BoxDecoration(
              color: DarkKickColors.mediumGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DarkKickColors.divider),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat.icon,
                  color: DarkKickColors.neonPurple,
                  size: 28,
                ),
                SizedBox(height: 12),
                Text(
                  stat.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DarkKickColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          title: 'Поддержать разработчика',
          icon: Icons.favorite_outline,
          onTap: () {},
        ),
        _buildMenuItem(
          title: 'Пригласить друзей',
          icon: Icons.person_add_outlined,
          onTap: () {},
          showArrow: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DarkKickColors.mediumGray,
                border: Border.all(
                  color: DarkKickColors.neonPurple,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: DarkKickColors.neonPurple,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DarkKickColors.textPrimary,
                ),
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: DarkKickColors.lightGray,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}


