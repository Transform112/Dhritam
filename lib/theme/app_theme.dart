import 'package:flutter/material.dart';

class AppTheme {
  // The "Sacred" Colors [cite: 45]
  static const Color primaryPurple = Color(0xFF4A3BAE);
  static const Color recoveryTeal = Color(0xFF1D9E75);
  static const Color moderateAmber = Color(0xFFBA7517);
  static const Color stressRed = Color(0xFFE24B4A);
  
  static const Color textDark = Color(0xFF2C2C2A);
  static const Color bgOffWhite = Color(0xFFF8F7F4);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color mutedGray = Color(0xFF888780);
  
  // Dark Mode specific
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkText = Color(0xFFE8E6E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgOffWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: recoveryTeal,
        error: stressRed,
        surface: cardWhite,
        onSurface: textDark,
      ),
      fontFamily: 'Roboto', // Fallback for SF Pro
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryPurple,
        unselectedItemColor: mutedGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple, // Brand colors remain same in dark mode [cite: 71]
        secondary: recoveryTeal,
        error: stressRed,
        surface: darkCard,
        onSurface: darkText,
      ),
      fontFamily: 'Roboto',
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryPurple,
        unselectedItemColor: mutedGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}