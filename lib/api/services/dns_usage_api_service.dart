import 'package:flutter/foundation.dart';
import '../../path/path.dart';
import '../models/user_dns_usage.dart';

/// سرویس مدیریت اتصال کاربران به DNS
class DnsUsageApiService {
  late final ApiClient _apiClient;

  DnsUsageApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ?? ApiClient();
  }

  /// ثبت اتصال کاربر به DNS
  Future<ApiResponse<UserDnsUsage>> recordDnsUsage({
    required String userDnsId,
    required String internetTag,
    String? destination,
    required String userId,
  }) async {
    try {
      final response = await _apiClient.post<UserDnsUsage>(
        '/api/dns-usage',
        body: {
          'userDnsId': userDnsId,
          'internetTag': internetTag,
          'userId': userId,
          if (destination != null) 'destination': destination,
        },
        fromJson: (data) => UserDnsUsage.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error recording DNS usage: $e');
      return ApiResponse<UserDnsUsage>(
        status: false,
        message: 'خطا در ثبت استفاده از DNS: ${e.toString()}',
        errorCode: 'RECORD_USAGE_ERROR',
      );
    }
  }

  /// دریافت کاربران متصل به یک DNS
  Future<ApiResponse<List<UserDnsUsage>>> getDnsUsers(String userDnsId) async {
    try {
      final response = await _apiClient.get<List<UserDnsUsage>>(
        '/api/dns-usage/$userDnsId',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => UserDnsUsage.fromJson(item)).toList();
          }
          return <UserDnsUsage>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS users: $e');
      return ApiResponse<List<UserDnsUsage>>(
        status: false,
        message: 'خطا در دریافت کاربران DNS: ${e.toString()}',
        errorCode: 'GET_USERS_ERROR',
      );
    }
  }

  /// دریافت گزارش کلی اتصالات (ادمین)
  Future<ApiResponse<List<UserDnsUsage>>> getDnsUsageReport() async {
    try {
      final response = await _apiClient.get<List<UserDnsUsage>>(
        '/api/dns-usage',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => UserDnsUsage.fromJson(item)).toList();
          }
          return <UserDnsUsage>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS usage report: $e');
      return ApiResponse<List<UserDnsUsage>>(
        status: false,
        message: 'خطا در دریافت گزارش استفاده: ${e.toString()}',
        errorCode: 'GET_REPORT_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
