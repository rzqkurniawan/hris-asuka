import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightBgPrimary = Color(0xFFF0F9FF); // Ice Blue
  static const Color lightBgSecondary = Color(0xFFFFFFFF); // White
  static const Color lightBgTertiary = Color(0xFFF8FAFC); // Light Gray
  static const Color lightTextPrimary = Color(0xFF164E63); // Teal Dark
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightBorderSubtle = Color(0xFFE0F2FE); // Sky Light

  // Dark Mode Colors
  static const Color darkBgPrimary = Color(0xFF020617); // Midnight
  static const Color darkBgSecondary = Color(0xFF0F172A); // Dark Slate
  static const Color darkBgTertiary = Color(0xFF1E293B); // Slate
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Ghost White
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Steel Gray
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderSubtle = Color(0xFF1E293B);

  // Shared Colors
  static const Color primary = Color(0xFF0EA5E9); // Cyan Blue
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF06B6D4);
  static const Color danger = Color(0xFFBE123C); // Crimson (light mode)
  static const Color dangerDark = Color(0xFFF43F5E); // Rose Red (dark mode)
  static const Color accent = Color(0xFFFCA5A5); // Coral

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: lightBgPrimary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryDark,
      surface: lightBgSecondary,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.64,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.56,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.48,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.36,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.16,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBgTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: lightTextSecondary,
        fontWeight: FontWeight.w400,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightBgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorderSubtle, width: 1),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryDark,
      surface: darkBgSecondary,
      error: dangerDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.64,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.56,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.48,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.36,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.16,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBgTertiary.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBorder.withOpacity(0.2), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBorder.withOpacity(0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerDark, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: darkTextSecondary,
        fontWeight: FontWeight.w400,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkBgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: darkBorder.withOpacity(0.15), width: 1),
      ),
    ),
  );
}
