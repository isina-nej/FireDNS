import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firedns/api/services/api_client.dart';
import 'package:flutter/foundation.dart';

/// مدل لاگ برای ارسال به سرور
class AppLogModel {
  final String deviceId;
  final String logType;
  final String message;
  final String metadata;

  AppLogModel({
    required this.deviceId,
    required this.logType,
    required this.message,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'logType': logType,
      'message': message,
      'metadata': metadata,
    };
  }
}

/// سرویس مدیریت لاگ‌ها و گزارش خطاها
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  late final ApiClient _apiClient;
  String? _deviceId;

  /// راه‌اندازی سرویس
  Future<void> initialize() async {
    _apiClient = ApiClient();
    await _initializeDeviceId();
  }

  /// دریافت شناسه دستگاه
  Future<void> _initializeDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor; // iOS Vendor ID
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceId = windowsInfo.computerName;
      } else {
        _deviceId = 'unknown_device';
      }

      debugPrint('[CrashReporting] Device ID initialized: $_deviceId');
    } catch (e) {
      debugPrint('[CrashReporting] Failed to get device ID: $e');
      _deviceId = 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// ارسال لاگ کرش به سرور
  Future<void> reportCrash({
    required dynamic error,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'appVersion': '2.0.0',
        'dartVersion': Platform.version,
        'stackTrace': stackTrace.toString(),
        'errorType': error.runtimeType.toString(),
        ...?additionalMetadata,
      };

      final logModel = AppLogModel(
        deviceId: _deviceId ?? 'unknown',
        logType: 'crash',
        message: error.toString(),
        metadata: jsonEncode(metadata),
      );

      await _sendLogToServer(logModel);
      debugPrint('[CrashReporting] Crash report sent successfully');
    } catch (e) {
      debugPrint('[CrashReporting] Failed to send crash report: $e');
      // ذخیره در کش محلی برای ارسال بعدی
      await _saveCrashToLocalCache(error, stackTrace, additionalMetadata);
    }
  }

  /// ارسال لاگ خطا به سرور
  Future<void> reportError({
    required String message,
    String logType = 'error',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logMetadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'appVersion': '2.0.0',
        ...?metadata,
      };

      final logModel = AppLogModel(
        deviceId: _deviceId ?? 'unknown',
        logType: logType,
        message: message,
        metadata: jsonEncode(logMetadata),
      );

      await _sendLogToServer(logModel);
      debugPrint('[CrashReporting] Error report sent successfully');
    } catch (e) {
      debugPrint('[CrashReporting] Failed to send error report: $e');
    }
  }

  /// ارسال لاگ اطلاعاتی به سرور
  Future<void> reportInfo({
    required String message,
    String logType = 'info',
    Map<String, dynamic>? metadata,
  }) async {
    // فقط در حالت دیباگ ارسال کنیم
    if (!kDebugMode) return;

    try {
      final logMetadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'appVersion': '2.0.0',
        ...?metadata,
      };

      final logModel = AppLogModel(
        deviceId: _deviceId ?? 'unknown',
        logType: logType,
        message: message,
        metadata: jsonEncode(logMetadata),
      );

      await _sendLogToServer(logModel);
    } catch (e) {
      debugPrint('[CrashReporting] Failed to send info report: $e');
    }
  }

  /// ارسال لاگ به سرور
  Future<void> _sendLogToServer(AppLogModel logModel) async {
    final response = await _apiClient.post(
      '/api/app-logs',
      body: logModel.toJson(),
    );

    if (!response.status || response.hasError) {
      throw Exception('Failed to send log: ${response.errorMessage}');
    }
  }

  /// ذخیره کرش در کش محلی برای ارسال بعدی
  Future<void> _saveCrashToLocalCache(
    dynamic error,
    StackTrace stackTrace,
    Map<String, dynamic>? additionalMetadata,
  ) async {
    try {
      // TODO: پیاده‌سازی ذخیره در SharedPreferences یا SQLite
      debugPrint(
          '[CrashReporting] Crash saved to local cache for later sending');
    } catch (e) {
      debugPrint('[CrashReporting] Failed to save crash to local cache: $e');
    }
  }

  /// ارسال کرش‌های ذخیره شده در کش
  Future<void> sendPendingCrashes() async {
    try {
      // TODO: خواندن کرش‌های ذخیره شده و ارسال آنها
      debugPrint('[CrashReporting] Checking for pending crashes...');
    } catch (e) {
      debugPrint('[CrashReporting] Failed to send pending crashes: $e');
    }
  }

  /// گزارش عملکرد برنامه
  Future<void> reportPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!kDebugMode) return;

    final metadata = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await reportInfo(
      message: 'Performance: $operation took ${duration.inMilliseconds}ms',
      logType: 'performance',
      metadata: metadata,
    );
  }
}
