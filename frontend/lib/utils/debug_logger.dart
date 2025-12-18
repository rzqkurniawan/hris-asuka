import 'package:flutter/foundation.dart';

/// Debug logger that only logs in debug mode
/// Use this instead of print() to prevent sensitive data leakage in production
class DebugLogger {
  /// Log a message only in debug mode
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  /// Log an error only in debug mode
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix ERROR: $message');
      if (error != null) {
        debugPrint('$prefix Error details: $error');
      }
    }
  }
}
