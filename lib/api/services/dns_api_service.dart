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
      debugPrint('Sending request to /api/dns with IPv4 type...');
      final response = await _apiClient.get<List<DnsRecord>>(
        '/api/dns',
        queryParameters: {
          'type': 'IPv4',
          'offset': '0',
          'limit': 'all',
        },
        fromJson: (json) {
          debugPrint('Raw JSON response type: ${json.runtimeType}');
          debugPrint('Raw JSON response:');
          debugPrint(json.toString());

          if (json == null) {
            throw const FormatException('پاسخ سرور خالی است');
          }

          // Handle the case where the response is directly a list (for backward compatibility)
          if (json is List) {
            debugPrint('Response is a List. Processing directly...');
            return json
                .map((item) => DnsRecord.fromJson(item as Map<String, dynamic>))
                .toList();
          }

          // Handle the case where the response is wrapped in a response object
          debugPrint('Response is a Map. Processing as wrapped response...');
          final responseMap = json as Map<String, dynamic>;
          debugPrint('Response map keys: ${responseMap.keys.join(', ')}');

          if (!responseMap.containsKey('data')) {
            throw const FormatException('پاسخ سرور فاقد فیلد data است');
          }

          debugPrint('Data field type: ${responseMap['data'].runtimeType}');
          final List<dynamic> dataList = responseMap['data'] as List;
          return dataList
              .map((item) => DnsRecord.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      debugPrint('API /api/dns?type=IPv4&offset=0&limit=all final response:');
      debugPrint(response.toString());
      return response;
    } on FormatException catch (e) {
      debugPrint('JSON Parse Error: $e');
      return ApiResponse<List<DnsRecord>>(
        status: false,
        message: 'خطا در تجزیه پاسخ سرور',
        errorCode: 'JSON_PARSE_ERROR',
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error getting all DNS records: $e');
      debugPrint('Stack trace: $stackTrace');
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
          debugPrint(
              'API /api/dns?type=${dnsTypeToString(type)} response data:');
          debugPrint(data.toString());
          if (data is List) {
            return data.map((item) => DnsRecord.fromJson(item)).toList();
          }
          return <DnsRecord>[];
        },
      );

      debugPrint('API /api/dns?type=${dnsTypeToString(type)} final response:');
      debugPrint(response.toString());
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

  /// ایجاد DNS کاربر
  Future<ApiResponse<DnsRecord>> createUserDns({
    required String label,
    required String ip1,
    required String ip2,
    required DnsType type,
  }) async {
    try {
      final response = await _apiClient.post<DnsRecord>(
        '/api/dns',
        body: {
          'label': label,
          'ip1': ip1,
          'ip2': ip2,
          'type': dnsTypeToString(type)
        },
        fromJson: (data) => DnsRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error creating user DNS: $e');
      return ApiResponse<DnsRecord>(
        status: false,
        message: 'خطا در ایجاد DNS: ${e.toString()}',
        errorCode: 'CREATE_DNS_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
