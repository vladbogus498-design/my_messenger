import 'package:flutter/material.dart';

/// Современная мобильная кнопка в стиле Secondary
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Цвета для светлой и тёмной темы
    final backgroundColor = isDark
        ? Colors.grey[900] // Тёмный для тёмной темы
        : Colors.white; // Белый для светлой темы
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Скругление 12
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500, // Medium weight
                ),
              ),
      ),
    );
  }
}

