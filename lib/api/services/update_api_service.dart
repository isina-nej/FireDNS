import 'package:firedns/api/models/api_response.dart';
import 'package:firedns/api/models/update_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'api_client.dart';

/// سرویس API برای دریافت اطلاعات آپدیت
class UpdateApiService {
  final ApiClient _apiClient;

  UpdateApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// دریافت اطلاعات آپدیت
  Future<ApiResponse<UpdateInfo>> getUpdateInfo(
      String currentAppVersion) async {
    try {
      print('🔍 درخواست اطلاعات آپدیت برای نسخه $currentAppVersion');

      // زبان را هم ارسال کنیم
      final String languageCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final response = await _apiClient.get<UpdateInfo>(
        '/api/update-info',
        queryParameters: {
          'currentVersion': currentAppVersion,
          'language': languageCode,
        },
        fromJson: (data) => UpdateInfo.fromJson({'data': data}),
      );

      print(response.status
          ? '✅ دریافت اطلاعات آپدیت موفق'
          : '❌ خطا در دریافت اطلاعات آپدیت: ${response.message}');

      return response;
    } catch (e, stackTrace) {
      print('⚠️ خطا در getUpdateInfo: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<UpdateInfo>(
        status: false,
        message: 'خطا در دریافت اطلاعات آپدیت',
        errorCode: 'UPDATE_INFO_ERROR',
      );
    }
  }

  /// بستن کلاینت
  void dispose() {
    _apiClient.dispose();
  }
}
