import 'package:flutter/foundation.dart';
import 'crash_reporting_service.dart';

/// مدیریت خطاهای Flutter
class FlutterErrorHandler {
  static final CrashReportingService _crashService = CrashReportingService();

  /// راه‌اندازی error handler
  static void initialize() {
    // مدیریت خطاهای Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      // نمایش خطا در کنسول در حالت دیباگ
      if (kDebugMode) {
        FlutterError.presentError(details);
      }

      // ارسال گزارش خطا به سرور
      _handleFlutterError(details);
    };

    // مدیریت خطاهای پلتفرم (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  /// مدیریت خطاهای Flutter
  static void _handleFlutterError(FlutterErrorDetails details) {
    try {
      final additionalMetadata = {
        'library': details.library,
        'context': details.context?.toString(),
        'contextType': details.context?.runtimeType.toString(),
        'informationCollector': details.informationCollector?.toString(),
        'silent': details.silent,
        'errorType': 'flutter_error',
      };

      _crashService.reportCrash(
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.empty,
        additionalMetadata: additionalMetadata,
      );
    } catch (e) {
      debugPrint('[FlutterErrorHandler] Failed to report Flutter error: $e');
    }
  }

  /// مدیریت خطاهای پلتفرم
  static void _handlePlatformError(Object error, StackTrace stack) {
    try {
      final additionalMetadata = {
        'errorType': 'platform_error',
        'source': 'platform_dispatcher',
      };

      _crashService.reportCrash(
        error: error,
        stackTrace: stack,
        additionalMetadata: additionalMetadata,
      );
    } catch (e) {
      debugPrint('[FlutterErrorHandler] Failed to report platform error: $e');
    }
  }

  /// گزارش خطای دستی
  static void reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? metadata,
  }) {
    try {
      _crashService.reportCrash(
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
        additionalMetadata: {
          'errorType': 'manual_report',
          'reported_at': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
    } catch (e) {
      debugPrint('[FlutterErrorHandler] Failed to report manual error: $e');
    }
  }

  /// گزارش اطلاعات عملکرد
  static void reportPerformanceIssue(String operation, Duration duration) {
    if (duration.inMilliseconds > 1000) {
      // بیش از 1 ثانیه
      _crashService.reportPerformance(
        operation: operation,
        duration: duration,
        additionalData: {
          'performance_issue': true,
          'threshold_exceeded': true,
        },
      );
    }
  }

  /// گزارش خطای شبکه
  static void reportNetworkError(
      String endpoint, int? statusCode, String error) {
    _crashService.reportError(
      message: 'Network Error: $endpoint',
      logType: 'network_error',
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// گزارش خطای محلی
  static void reportLocalError(String operation, String error,
      {Map<String, dynamic>? context}) {
    _crashService.reportError(
      message: 'Local Error in $operation: $error',
      logType: 'local_error',
      metadata: {
        'operation': operation,
        'error_details': error,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
