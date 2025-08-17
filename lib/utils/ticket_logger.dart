import 'package:flutter/foundation.dart';

class TicketLogger {
  static int _stepCount = 0;

  static void logStep(String message, {String? details}) {
    _stepCount++;
    final timestamp = DateTime.now().toIso8601String();
    final stepInfo = '(Step $_stepCount)';
    final detailsText = details != null ? ' - Details: $details' : '';

    debugPrint('[TicketLog][$timestamp]$stepInfo $message$detailsText');
  }

  static void resetStepCount() {
    _stepCount = 0;
  }

  static void logValidation(String field, bool isValid,
      {String? errorMessage}) {
    final status = isValid ? 'Valid' : 'Invalid';
    final error = errorMessage != null ? ' - Error: $errorMessage' : '';
    logStep('Field Validation: $field', details: '$status$error');
  }

  static void logNetworkRequest(String type,
      {String? url, Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' - Data: $data' : '';
    final urlStr = url != null ? ' - URL: $url' : '';
    logStep('Network $type Request', details: 'Started$urlStr$dataStr');
  }

  static void logNetworkResponse(String type, bool success,
      {String? message, dynamic data}) {
    final status = success ? 'Success' : 'Failed';
    final messageStr = message != null ? ' - Message: $message' : '';
    final dataStr = data != null ? ' - Response: $data' : '';
    logStep('Network $type Response', details: '$status$messageStr$dataStr');
  }

  static void logError(String error, {String? stackTrace}) {
    final traceInfo = stackTrace != null ? ' - StackTrace: $stackTrace' : '';
    logStep('Error Occurred', details: 'Error: $error$traceInfo');
  }
}
