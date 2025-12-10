import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF0c4a6e); // Deep Ocean
  static const Color secondaryLight = Color(0xFF0ea5e9); // Cyan Blue
  static const Color dangerLight = Color(0xFFbe123c); // Crimson
  static const Color backgroundLight = Color(0xFFf0f9ff); // Ice Blue
  static const Color surfaceLight = Color(0xFFffffff); // White
  static const Color textPrimaryLight = Color(0xFF164e63); // Teal Dark
  static const Color accentLight = Color(0xFFfca5a5); // Coral
  static const Color mutedLight = Color(0xFFe0f2fe); // Sky Light
  static const Color textSecondaryLight = Color(0xFF64748b); // Slate Gray

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF0ea5e9); // Bright Cyan
  static const Color secondaryDark = Color(0xFF3b82f6); // Electric Blue
  static const Color dangerDark = Color(0xFFf43f5e); // Rose Red
  static const Color backgroundDark = Color(0xFF020617); // Midnight
  static const Color surfaceDark = Color(0xFF0f172a); // Dark Slate
  static const Color surfaceAltDark = Color(0xFF1e293b); // Slate
  static const Color textPrimaryDark = Color(0xFFf1f5f9); // Ghost White
  static const Color textSecondaryDark = Color(0xFF94a3b8); // Steel Gray

  // Status Colors
  static const Color statusWork = Color(0xFF10b981); // Green
  static const Color statusLate = Color(0xFFf59e0b); // Orange
  static const Color statusAbsent = Color(0xFFef4444); // Red
  static const Color statusLeave = Color(0xFF8b5cf6); // Purple

  // Aliases for backward compatibility
  static const Color primary = primaryLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color cardDark = surfaceDark;

  // Gradients
  static const LinearGradient primaryGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0c4a6e), Color(0xFF082f49)],
  );

  static const LinearGradient secondaryGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
  );

  static const LinearGradient statusWorkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10b981), Color(0xFF059669)],
  );

  static const LinearGradient statusLateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
  );

  static const LinearGradient statusAbsentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFef4444), Color(0xFFdc2626)],
  );

  static const LinearGradient statusLeaveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
  );
}
