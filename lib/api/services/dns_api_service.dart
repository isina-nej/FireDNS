import 'package:flutter/foundation.dart';
import '../../path/path.dart';


/// سرویس API برای مدیریت DNS
class DnsApiService {
  late final ApiClient _apiClient;

  DnsApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ?? ApiClient();
  }

  /// دریافت همه رکوردهای DNS
  Future<ApiResponse<List<DnsRecord>>> getAllDnsRecords() async {
    try {
      final response = await _apiClient.get<List<DnsRecord>>(
        '/api/dns',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DnsRecord.fromJson(item)).toList();
          }
          return <DnsRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting all DNS records: $e');
      return ApiResponse<List<DnsRecord>>(
        status: false,
        message: 'خطا در دریافت لیست DNS: ${e.toString()}',
        errorCode: 'GET_ALL_ERROR',
      );
    }
  }

  /// دریافت رکوردهای DNS بر اساس نوع
  Future<ApiResponse<List<DnsRecord>>> getDnsRecordsByType(DnsType type) async {
    try {
      final response = await _apiClient.get<List<DnsRecord>>(
        '/api/dns',
        queryParameters: {'type': dnsTypeToString(type)},
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DnsRecord.fromJson(item)).toList();
          }
          return <DnsRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS records by type: $e');
      return ApiResponse<List<DnsRecord>>(
        status: false,
        message: 'خطا در دریافت لیست DNS بر اساس نوع: ${e.toString()}',
        errorCode: 'GET_BY_TYPE_ERROR',
      );
    }
  }

  /// دریافت رکورد DNS بر اساس ID
  Future<ApiResponse<DnsRecord>> getDnsRecordById(String id) async {
    try {
      final response = await _apiClient.get<DnsRecord>(
        '/api/dns/$id',
        fromJson: (data) => DnsRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS record by ID: $e');
      return ApiResponse<DnsRecord>(
        status: false,
        message: 'خطا در دریافت رکورد DNS: ${e.toString()}',
        errorCode: 'GET_BY_ID_ERROR',
      );
    }
  }

  /// ایجاد رکورد DNS جدید
  Future<ApiResponse<DnsRecord>> createDnsRecord(
    DnsRecordRequest request,
  ) async {
    try {
      final response = await _apiClient.post<DnsRecord>(
        '/api/dns',
        body: request.toJson(),
        fromJson: (data) => DnsRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error creating DNS record: $e');
      return ApiResponse<DnsRecord>(
        status: false,
        message: 'خطا در ایجاد رکورد DNS: ${e.toString()}',
        errorCode: 'CREATE_ERROR',
      );
    }
  }

  /// ویرایش رکورد DNS
  Future<ApiResponse<DnsRecord>> updateDnsRecord(
    String id,
    DnsRecordRequest request,
  ) async {
    try {
      final response = await _apiClient.patch<DnsRecord>(
        '/api/dns/$id',
        body: request.toJson(),
        fromJson: (data) => DnsRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error updating DNS record: $e');
      return ApiResponse<DnsRecord>(
        status: false,
        message: 'خطا در ویرایش رکورد DNS: ${e.toString()}',
        errorCode: 'UPDATE_ERROR',
      );
    }
  }

  /// حذف رکورد DNS
  Future<ApiResponse<bool>> deleteDnsRecord(String id) async {
    try {
      final response = await _apiClient.delete<bool>(
        '/api/dns/$id',
        fromJson: (data) => true,
      );

      return response;
    } catch (e) {
      debugPrint('Error deleting DNS record: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در حذف رکورد DNS: ${e.toString()}',
        errorCode: 'DELETE_ERROR',
      );
    }
  }

  /// جستجو در رکوردهای DNS
  Future<ApiResponse<List<DnsRecord>>> searchDnsRecords(String query) async {
    try {
      final response = await _apiClient.get<List<DnsRecord>>(
        '/api/dns/search',
        queryParameters: {'q': query},
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DnsRecord.fromJson(item)).toList();
          }
          return <DnsRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error searching DNS records: $e');
      return ApiResponse<List<DnsRecord>>(
        status: false,
        message: 'خطا در جستجو: ${e.toString()}',
        errorCode: 'SEARCH_ERROR',
      );
    }
  }

  /// فیلتر کردن رکوردها بر اساس چندین معیار
  Future<ApiResponse<List<DnsRecord>>> filterDnsRecords({
    DnsType? type,
    String? label,
    String? ip,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParameters = <String, String>{};

      if (type != null) {
        queryParameters['type'] = dnsTypeToString(type);
      }
      if (label != null && label.isNotEmpty) {
        queryParameters['label'] = label;
      }
      if (ip != null && ip.isNotEmpty) {
        queryParameters['ip'] = ip;
      }
      if (fromDate != null) {
        queryParameters['from'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParameters['to'] = toDate.toIso8601String();
      }

      final response = await _apiClient.get<List<DnsRecord>>(
        '/api/dns/filter',
        queryParameters: queryParameters,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DnsRecord.fromJson(item)).toList();
          }
          return <DnsRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error filtering DNS records: $e');
      return ApiResponse<List<DnsRecord>>(
        status: false,
        message: 'خطا در فیلتر کردن: ${e.toString()}',
        errorCode: 'FILTER_ERROR',
      );
    }
  }

  /// بررسی دسترسی به DNS
  Future<ApiResponse<bool>> checkDnsAccess(String ip1, String ip2) async {
    try {
      final response = await _apiClient.post<bool>(
        '/api/dns/check',
        body: {'ip1': ip1, 'ip2': ip2},
        fromJson: (data) => data['accessible'] as bool? ?? false,
      );

      return response;
    } catch (e) {
      debugPrint('Error checking DNS access: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در بررسی دسترسی DNS: ${e.toString()}',
        errorCode: 'CHECK_ACCESS_ERROR',
      );
    }
  }

  /// دریافت آمار DNS
  Future<ApiResponse<Map<String, int>>> getDnsStats() async {
    try {
      final response = await _apiClient.get<Map<String, int>>(
        '/api/dns/stats',
        fromJson: (data) {
          if (data is Map<String, dynamic>) {
            return data.map((key, value) => MapEntry(key, value as int));
          }
          return <String, int>{};
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS stats: $e');
      return ApiResponse<Map<String, int>>(
        status: false,
        message: 'خطا در دریافت آمار: ${e.toString()}',
        errorCode: 'GET_STATS_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
