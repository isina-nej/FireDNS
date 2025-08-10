import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../models/update_info.dart';

/// سرویس API برای دریافت اطلاعات آپدیت
class UpdateApiService {
  final ApiClient _apiClient;

  UpdateApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// دریافت اطلاعات آپدیت
  Future<ApiResponse<UpdateInfo>> getUpdateInfo(String currentAppVersion) async {
    try {
      final response = await _apiClient.get<UpdateInfo>(
        '/api/update-info', // endpoint
        queryParameters: {'currentVersion': currentAppVersion},
        fromJson: (data) => UpdateInfo.fromJson(data as Map<String, dynamic>),
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('Error in getUpdateInfo: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<UpdateInfo>(
        status: false,
        message: 'خطا در دریافت اطلاعات آپدیت',
        errorCode: 'UPDATE_INFO_ERROR',
      );
    }
  }

  /// بستن client
  void dispose() {
    _apiClient.dispose();
  }
}