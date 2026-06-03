import 'package:flutter/material.dart';

class AppTheme {
  // ألوان التطبيق
  static const Color primaryBg = Color(0xFF0D1B2A);
  static const Color secondaryBg = Color(0xFF1A2F44);
  static const Color cardBg = Color(0xFF1E3448);
  static const Color primaryBlue = Color(0xFF1E90FF);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color successGreen = Color(0xFF00C896);
  static const Color warningYellow = Color(0xFFFFB800);
  static const Color errorRed = Color(0xFFFF4757);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB0C4DE);
  static const Color dividerColor = Color(0xFF2A4A6B);
  static const Color goldColor = Color(0xFFFFD700);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: secondaryBg,
        error: errorRed,
      ),
      fontFamily: 'IBM',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textWhite,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textWhite,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(color: textWhite, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textWhite, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textWhite),
        bodyMedium: TextStyle(color: textGrey),
        labelLarge: TextStyle(color: textWhite, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: TextStyle(color: textGrey),
        hintStyle: TextStyle(color: textGrey),
      ),
      cardColor: cardBg,
      dividerColor: dividerColor,
    );
  }
}
