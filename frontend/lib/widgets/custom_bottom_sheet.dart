import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Show custom bottom sheet with drag handle
Future<T?> showCustomBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double? height,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: height ?? MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.3)
                  : AppColors.textSecondaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

/// Show bottom sheet with title
Future<T?> showCustomBottomSheetWithTitle<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  double? height,
  bool isDismissible = true,
  bool enableDrag = true,
  List<Widget>? actions,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: height ?? MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.3)
                  : AppColors.textSecondaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          
          // Header with title and actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (actions != null) Row(children: actions),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          Expanded(child: child),
        ],
      ),
    ),
  );
}
