import 'package:flutter/foundation.dart';

/// Helper برای debugging که در production غیرفعال می‌شود
class DebugHelper {
  static void debugLog(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  static void apiLog(String message) {
    if (kDebugMode) {
      print('[API] $message');
    }
  }

  static void performanceLog(String message) {
    if (kDebugMode) {
      print('[PERF] $message');
    }
  }

  static void bootLog(String message) {
    if (kDebugMode) {
      print('[BOOT] $message');
    }
  }
}
