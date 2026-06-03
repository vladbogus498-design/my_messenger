import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'darkkick_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: DarkKickColors.textPrimary,
      displayColor: DarkKickColors.textPrimary,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: DarkKickColors.neonPurple,
      brightness: Brightness.dark,
      primary: DarkKickColors.neonPurple,
      onPrimary: Colors.white,
      secondary: DarkKickColors.electricPurple,
      onSecondary: Colors.white,
      error: const Color(0xFFFF5C7A),
      onError: Colors.white,
      surface: DarkKickColors.panel,
      onSurface: DarkKickColors.textPrimary,
      surfaceTint: DarkKickColors.neonPurple,
      primaryContainer: DarkKickColors.darkPurple,
      onPrimaryContainer: Colors.white,
      secondaryContainer: DarkKickColors.cardSoft,
      onSecondaryContainer: DarkKickColors.textPrimary,
      errorContainer: const Color(0xFF3A0D18),
      onErrorContainer: Colors.white,
      scrim: Colors.black87,
      shadow: Colors.black87,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      outline: DarkKickColors.stroke,
      outlineVariant: DarkKickColors.divider,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DarkKickColors.darkBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: DarkKickColors.darkBackground,
        foregroundColor: DarkKickColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: DarkKickColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DarkKickColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkKickColors.neonPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: DarkKickColors.neonPurple),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkKickColors.panel,
        hintStyle: const TextStyle(color: DarkKickColors.textTertiary),
        labelStyle: const TextStyle(color: DarkKickColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DarkKickColors.neonPurple),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DarkKickColors.darkBackground,
        selectedItemColor: DarkKickColors.neonPurple,
        unselectedItemColor: DarkKickColors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DarkKickColors.neonPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: DarkKickColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkKickColors.cardSoft,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData light() => dark();
}
