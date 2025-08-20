import 'package:flutter/foundation.dart';
import '../services/crash_reporting_service.dart';
import '../services/flutter_error_handler.dart';

/// Helper class برای گزارش آسان خطاها در سراسر برنامه
class ErrorReporter {
  static final CrashReportingService _crashService = CrashReportingService();

  /// گزارش خطای کلی
  static Future<void> reportError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _crashService.reportCrash(
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
        additionalMetadata: {
          'context': context,
          'reported_by': 'ErrorReporter',
          ...?metadata,
        },
      );
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to report error: $e');
    }
  }

  /// گزارش خطای شبکه
  static Future<void> reportNetworkError({
    required String endpoint,
    required String error,
    int? statusCode,
    Map<String, dynamic>? requestData,
  }) async {
    FlutterErrorHandler.reportNetworkError(endpoint, statusCode, error);

    // اضافه کردن metadata بیشتر
    await _crashService.reportError(
      message: 'Network Error: $endpoint',
      logType: 'network_error',
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error': error,
        'request_data': requestData,
        'timestamp': DateTime.now().toIso8601String(),
        'network_available': await _checkNetworkAvailability(),
      },
    );
  }

  /// گزارش خطای database
  static Future<void> reportDatabaseError({
    required String operation,
    required String error,
    Map<String, dynamic>? queryInfo,
  }) async {
    await _crashService.reportError(
      message: 'Database Error in $operation: $error',
      logType: 'database_error',
      metadata: {
        'operation': operation,
        'error_details': error,
        'query_info': queryInfo,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// گزارش خطای UI/Widget
  static Future<void> reportUIError({
    required String widget,
    required String error,
    String? userAction,
    Map<String, dynamic>? widgetState,
  }) async {
    await _crashService.reportError(
      message: 'UI Error in $widget: $error',
      logType: 'ui_error',
      metadata: {
        'widget': widget,
        'error_details': error,
        'user_action': userAction,
        'widget_state': widgetState,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// گزارش خطای VPN
  static Future<void> reportVpnError({
    required String operation,
    required String error,
    bool? vpnStatus,
    Map<String, dynamic>? vpnConfig,
  }) async {
    await _crashService.reportError(
      message: 'VPN Error in $operation: $error',
      logType: 'vpn_error',
      metadata: {
        'operation': operation,
        'error_details': error,
        'vpn_status': vpnStatus,
        'vpn_config': vpnConfig,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// گزارش خطای DNS
  static Future<void> reportDnsError({
    required String operation,
    required String error,
    String? dnsServer,
    Map<String, dynamic>? dnsConfig,
  }) async {
    await _crashService.reportError(
      message: 'DNS Error in $operation: $error',
      logType: 'dns_error',
      metadata: {
        'operation': operation,
        'error_details': error,
        'dns_server': dnsServer,
        'dns_config': dnsConfig,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// گزارش مشکل عملکرد
  static Future<void> reportPerformanceIssue({
    required String operation,
    required Duration duration,
    int? threshold,
    Map<String, dynamic>? performanceData,
  }) async {
    final thresholdMs = threshold ?? 1000; // default 1 second

    if (duration.inMilliseconds > thresholdMs) {
      await _crashService.reportPerformance(
        operation: operation,
        duration: duration,
        additionalData: {
          'threshold_ms': thresholdMs,
          'performance_issue': true,
          'performance_data': performanceData,
        },
      );
    }
  }

  /// گزارش اطلاعات دیباگ
  static Future<void> reportDebugInfo({
    required String message,
    Map<String, dynamic>? debugData,
  }) async {
    if (kDebugMode) {
      await _crashService.reportInfo(
        message: message,
        logType: 'debug',
        metadata: {
          'debug_data': debugData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// گزارش warning
  static Future<void> reportWarning({
    required String message,
    String? context,
    Map<String, dynamic>? warningData,
  }) async {
    await _crashService.reportError(
      message: message,
      logType: 'warning',
      metadata: {
        'context': context,
        'warning_data': warningData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// بررسی وضعیت شبکه
  static Future<bool> _checkNetworkAvailability() async {
    try {
      // یک بررسی ساده شبکه
      return true; // TODO: پیاده‌سازی بررسی واقعی شبکه
    } catch (e) {
      return false;
    }
  }

  /// Performance timer helper
  static PerformanceTimer startPerformanceTimer(String operation) {
    return PerformanceTimer(operation);
  }
}

/// کلاس کمکی برای اندازه‌گیری performance
class PerformanceTimer {
  final String operation;
  final DateTime startTime;

  PerformanceTimer(this.operation) : startTime = DateTime.now();

  /// پایان timer و گزارش performance
  Future<void> end({Map<String, dynamic>? additionalData}) async {
    final duration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('[Performance] $operation took ${duration.inMilliseconds}ms');
    }

    await ErrorReporter.reportPerformanceIssue(
      operation: operation,
      duration: duration,
      performanceData: additionalData,
    );
  }
}
