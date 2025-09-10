import 'package:flutter/foundation.dart';

/// Helper برای debugging که در production غیرفعال می‌شود
class DebugHelper {
  static void debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void apiLog(String message) {
    if (kDebugMode) {
      debugPrint('[API] $message');
    }
  }

  static void performanceLog(String message) {
    if (kDebugMode) {
      debugPrint('[PERF] $message');
    }
  }

  static void bootLog(String message) {
    if (kDebugMode) {
      debugPrint('[BOOT] $message');
    }
  }
}
