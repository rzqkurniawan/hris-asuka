import 'package:flutter/material.dart';

/// Utility class for responsive design across different device sizes.
///
/// On tablets, we use fixed pixel values instead of ScreenUtil scaling
/// because ScreenUtil is designed for phones and doesn't scale well to tablets.
class Responsive {
  // Breakpoint constants
  static const double phoneMaxWidth = 600;
  static const double tabletPortraitMaxWidth = 900;

  /// Check if device is a phone (width < 600dp)
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneMaxWidth;
  }

  /// Check if device is a tablet (width >= 600dp)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= phoneMaxWidth;
  }

  /// Check if device is in tablet landscape mode (width >= 900dp)
  static bool isTabletLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletPortraitMaxWidth;
  }

  /// Get number of grid columns based on screen width
  /// - Phone: 2 columns
  /// - Tablet Portrait: 3 columns
  /// - Tablet Landscape: 4 columns
  static int getMenuGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < phoneMaxWidth) {
      return 2;
    } else if (width < tabletPortraitMaxWidth) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get appropriate horizontal padding based on device (in logical pixels)
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= tabletPortraitMaxWidth) {
      return 48; // Tablet landscape
    } else if (width >= phoneMaxWidth) {
      return 32; // Tablet portrait
    }
    return 20; // Phone (will be scaled by ScreenUtil in widget)
  }

  /// Get grid spacing for menu items (in logical pixels for tablet)
  static double getGridSpacing(BuildContext context) {
    if (isTablet(context)) {
      return 20; // Fixed pixels for tablet
    }
    return 15; // Will be scaled by ScreenUtil on phone
  }

  /// Get menu icon container size (in logical pixels for tablet)
  static double getMenuIconSize(BuildContext context) {
    if (isTabletLandscape(context)) {
      return 60;
    } else if (isTablet(context)) {
      return 56;
    }
    return 50; // Will be scaled by ScreenUtil on phone
  }

  /// Get profile menu columns for tablet
  static int getProfileMenuColumns(BuildContext context) {
    if (isTabletLandscape(context)) {
      return 2;
    }
    return 1; // Single column for phone and tablet portrait
  }
}
