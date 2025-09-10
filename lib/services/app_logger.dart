import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for the application
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Log debug information
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log information
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warnings
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log errors
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network requests
  static void network(String method, String url,
      {int? statusCode, dynamic data}) {
    if (kDebugMode) {
      final message = '$method $url';
      if (statusCode != null) {
        _logger.i('[$statusCode] $message', error: data);
      } else {
        _logger.d(message, error: data);
      }
    }
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration,
      {Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      final message =
          'Performance: $operation took ${duration.inMilliseconds}ms';
      _logger.i(message, error: metadata);
    }
  }

  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      _logger.i('User Action: $action', error: context);
    }
  }
}

/// Extension methods for easier logging
extension AppLoggerExtension on Object {
  void logDebug(String message) => AppLogger.debug('$runtimeType: $message');
  void logInfo(String message) => AppLogger.info('$runtimeType: $message');
  void logWarning(String message) =>
      AppLogger.warning('$runtimeType: $message');
  void logError(String message, [dynamic error, StackTrace? stackTrace]) =>
      AppLogger.error('$runtimeType: $message', error, stackTrace);
}
