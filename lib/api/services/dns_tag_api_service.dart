import 'package:firedns/api/models/dns_tag.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/foundation.dart';

/// سرویس مدیریت تگ‌های DNS
class DnsTagApiService {
  late final ApiClient _apiClient;

  DnsTagApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ?? ApiClient();
  }

  /// دریافت لیست تگ‌ها
  Future<ApiResponse<List<DnsTag>>> getAllTags() async {
    try {
      final response = await _apiClient.get<List<DnsTag>>(
        '/api/dns-tags',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DnsTag.fromJson(item)).toList();
          }
          return <DnsTag>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error getting DNS tags: $e');
      return ApiResponse<List<DnsTag>>(
        status: false,
        message: 'خطا در دریافت تگ‌ها: ${e.toString()}',
        errorCode: 'GET_TAGS_ERROR',
      );
    }
  }

  /// ایجاد تگ جدید
  Future<ApiResponse<DnsTag>> createTag(
    String name,
    String? description,
  ) async {
    try {
      final response = await _apiClient.post<DnsTag>(
        '/api/dns-tags',
        body: {
          'name': name,
          if (description != null) 'description': description,
        },
        fromJson: (data) => DnsTag.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error creating DNS tag: $e');
      return ApiResponse<DnsTag>(
        status: false,
        message: 'خطا در ایجاد تگ: ${e.toString()}',
        errorCode: 'CREATE_TAG_ERROR',
      );
    }
  }

  /// حذف تگ
  Future<ApiResponse<bool>> deleteTag(String id) async {
    try {
      final response = await _apiClient.delete<bool>(
        '/api/dns-tags/$id',
        fromJson: (data) => true,
      );

      return response;
    } catch (e) {
      debugPrint('Error deleting DNS tag: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در حذف تگ: ${e.toString()}',
        errorCode: 'DELETE_TAG_ERROR',
      );
    }
  }

  /// بروزرسانی تگ‌های یک DNS
  Future<ApiResponse<Map<String, int>>> updateDnsTags(
    String dnsId, {
    List<String>? addTagIds,
    List<String>? removeTagIds,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, int>>(
        '/api/dns/$dnsId/tags',
        body: {
          if (addTagIds != null) 'addTagIds': addTagIds,
          if (removeTagIds != null) 'removeTagIds': removeTagIds,
        },
        fromJson: (data) {
          if (data is Map<String, dynamic>) {
            return {
              'added': data['added'] as int? ?? 0,
              'removed': data['removed'] as int? ?? 0,
            };
          }
          return {'added': 0, 'removed': 0};
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error updating DNS tags: $e');
      return ApiResponse<Map<String, int>>(
        status: false,
        message: 'خطا در بروزرسانی تگ‌ها: ${e.toString()}',
        errorCode: 'UPDATE_TAGS_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
