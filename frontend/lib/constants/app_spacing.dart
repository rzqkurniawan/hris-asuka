import 'package:flutter/material.dart';

/// Standardized spacing system for consistent layout
class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  
  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  
  // SizedBox helpers
  static const SizedBox verticalSpaceXs = SizedBox(height: xs);
  static const SizedBox verticalSpaceSm = SizedBox(height: sm);
  static const SizedBox verticalSpaceMd = SizedBox(height: md);
  static const SizedBox verticalSpaceLg = SizedBox(height: lg);
  static const SizedBox verticalSpaceXl = SizedBox(height: xl);
  
  static const SizedBox horizontalSpaceXs = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSm = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(width: md);
  static const SizedBox horizontalSpaceLg = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXl = SizedBox(width: xl);
}
