import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
import '../constants/app_colors.dart';

class ToastUtils {
  static void _showAfterFrame(BuildContext context, Flushbar flushbar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flushbar.show(context);
    });
  }

  /// Show success toast
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    final flushbar = Flushbar(
      message: message,
      messageSize: 14,
      maxWidth: MediaQuery.of(context).size.width - 32,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 24,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: AppColors.statusWork,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
    _showAfterFrame(context, flushbar);
  }

  /// Show error toast
  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    final flushbar = Flushbar(
      message: message,
      messageSize: 14,
      maxWidth: MediaQuery.of(context).size.width - 32,
      icon: const Icon(
        Icons.error,
        color: Colors.white,
        size: 24,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
    _showAfterFrame(context, flushbar);
  }

  /// Show info toast
  static void showInfo(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    final flushbar = Flushbar(
      message: message,
      messageSize: 14,
      maxWidth: MediaQuery.of(context).size.width - 32,
      icon: const Icon(
        Icons.info,
        color: Colors.white,
        size: 24,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
    _showAfterFrame(context, flushbar);
  }

  /// Show warning toast
  static void showWarning(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    final flushbar = Flushbar(
      message: message,
      messageSize: 14,
      maxWidth: MediaQuery.of(context).size.width - 32,
      icon: const Icon(
        Icons.warning,
        color: Colors.white,
        size: 24,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: AppColors.statusLate,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
    _showAfterFrame(context, flushbar);
  }
}
