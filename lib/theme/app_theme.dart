import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_constants.dart';

class AppTheme {
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkSurface = Color(0xFF111111);
  static const Color _primaryRed = Color(0xFFE50914);
  static const Color _secondaryPurple = Color(0xFF7A1FCA);
  static const Color _lightBackground = Color(0xFFF5F6FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryRed,
      onPrimary: Colors.white,
      secondary: _secondaryPurple,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      background: _darkBackground,
      onBackground: Colors.white,
      surface: _darkSurface,
      onSurface: Colors.white70,
      surfaceTint: _secondaryPurple,
      primaryContainer: _primaryRed.withOpacity(0.15),
      onPrimaryContainer: Colors.white,
      secondaryContainer: _secondaryPurple.withOpacity(0.18),
      onSecondaryContainer: Colors.white,
      errorContainer: Colors.redAccent.withOpacity(0.2),
      onErrorContainer: Colors.white,
      scrim: Colors.black87,
      shadow: Colors.black54,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black87,
      outline: Colors.white24,
    );

    final textTheme =
        GoogleFonts.montserratTextTheme(base.textTheme).apply(bodyColor: Colors.white);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryRed,
          foregroundColor: Colors.white,
          elevation: UIConstants.elevationMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.paddingXLarge,
            vertical: UIConstants.paddingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
          shadowColor: _primaryRed.withOpacity(0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryPurple,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        labelStyle: TextStyle(color: Colors.white70),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.paddingLarge,
          vertical: UIConstants.paddingLarge,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          borderSide: BorderSide(color: _primaryRed),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _primaryRed,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _secondaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _secondaryPurple,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryRed,
      onPrimary: Colors.white,
      secondary: _secondaryPurple,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      background: _lightBackground,
      onBackground: Colors.black87,
      surface: _lightSurface,
      onSurface: Colors.black87,
      surfaceTint: _secondaryPurple,
      primaryContainer: _primaryRed.withOpacity(0.12),
      onPrimaryContainer: Colors.black,
      secondaryContainer: _secondaryPurple.withOpacity(0.12),
      onSecondaryContainer: Colors.black,
      errorContainer: Colors.redAccent.withOpacity(0.15),
      onErrorContainer: Colors.black,
      scrim: Colors.black54,
      shadow: Colors.black26,
      inverseSurface: Colors.black,
      onInverseSurface: Colors.white,
      outline: Colors.black26,
    );

    final textTheme = GoogleFonts.montserratTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        elevation: 0,
        foregroundColor: Colors.black87,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryRed,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryPurple,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        labelStyle: TextStyle(color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.paddingLarge,
          vertical: UIConstants.paddingLarge,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          borderSide: BorderSide(color: _primaryRed),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _primaryRed,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _secondaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.black.withOpacity(0.7)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _secondaryPurple,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


