import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final bool isPrimary;

  DialogAction({
    required this.label,
    required this.onPressed,
    this.style,
    this.isPrimary = false,
  });
}

/// Custom dialog with animations
class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? icon;
  final List<DialogAction> actions;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actions = const [],
  });

  /// Show a custom dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    Widget? icon,
    List<DialogAction>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        icon: icon,
        actions: actions ??
            [
              DialogAction(
                label: 'OK',
                onPressed: () => Navigator.pop(context),
                isPrimary: true,
              ),
            ],
      ),
    );
  }

  /// Show success dialog
  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show<T>(
      context: context,
      title: title,
      message: message,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: AppColors.statusWorkGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return show<T>(
      context: context,
      title: title,
      message: message,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: AppColors.statusAbsentGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: AppColors.secondaryGradientLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
          size: 48,
        ),
      ),
      actions: [
        DialogAction(
          label: cancelText,
          onPressed: () => Navigator.pop(context, false),
        ),
        DialogAction(
          label: confirmText,
          onPressed: () => Navigator.pop(context, true),
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              AppSpacing.verticalSpaceMd,
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceMd,
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actions.isNotEmpty) ...[
              AppSpacing.verticalSpaceXl,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions.map((action) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: ElevatedButton(
                        onPressed: action.onPressed,
                        style: action.style ??
                            (action.isPrimary
                                ? ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.statusAbsent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  )
                                : ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.surfaceAltDark
                                        : AppColors.mutedLight,
                                    foregroundColor: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  )),
                        child: Text(action.label),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.easeOutCubic,
        );
  }
}
