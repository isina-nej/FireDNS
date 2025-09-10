import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// سرویس مدیریت Firebase Cloud Messaging
class FcmService {
  static const String _baseUrl =
      'https://fcm.googleapis.com/v1/projects/dns-changer-a1046';
  static const String _scope =
      'https://www.googleapis.com/auth/firebase.messaging';

  late final Map<String, dynamic> _serviceAccount;
  String? _accessToken;
  DateTime? _tokenExpiry;

  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  FcmService._internal();

  /// راه‌اندازی سرویس
  Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/firebase-service-account.json',
      );
      _serviceAccount = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading FCM service account: $e');
      rethrow;
    }
  }

  /// دریافت توکن دسترسی
  Future<String> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    try {
      final jwt = _createJWT();
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in'] - 300),
        );
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting access token: $e');
      rethrow;
    }
  }

  /// ایجاد JWT برای احراز هویت
  String _createJWT() {
    final header = base64Url.encode(
      utf8.encode(json.encode({'alg': 'RS256', 'typ': 'JWT'})),
    );

    final now = DateTime.now();
    final expiry = now.add(const Duration(hours: 1));

    final claims = base64Url.encode(
      utf8.encode(
        json.encode({
          'iss': _serviceAccount['client_email'],
          'scope': _scope,
          'aud': 'https://oauth2.googleapis.com/token',
          'exp': expiry.millisecondsSinceEpoch ~/ 1000,
          'iat': now.millisecondsSinceEpoch ~/ 1000,
        }),
      ),
    );

    // final key = _serviceAccount['private_key'];
    // TODO: Implement RS256 signing
    // For now, this is a placeholder. You need to implement actual RS256 signing
    const signature = '';

    return '$header.$claims.$signature';
  }

  /// ارسال نوتیفیکیشن به یک یا چند توکن
  Future<bool> sendNotification({
    required String title,
    required String body,
    required List<String> tokens,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      for (final token in tokens) {
        final response = await http.post(
          Uri.parse('$_baseUrl/messages:send'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'message': {
              'token': token,
              'notification': {'title': title, 'body': body},
              if (data != null) 'data': data,
            },
          }),
        );

        if (response.statusCode != 200) {
          debugPrint('Error sending FCM notification: ${response.body}');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
      return false;
    }
  }

  /// ارسال نوتیفیکیشن به یک topic
  Future<bool> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/messages:send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': {
            'topic': topic,
            'notification': {'title': title, 'body': body},
            if (data != null) 'data': data,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending FCM topic notification: $e');
      return false;
    }
  }
}
