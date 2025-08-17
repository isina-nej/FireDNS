import '../models/api_response.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketService {
  final ApiClient apiClient;

  TicketService(this.apiClient);

  Future<ApiResponse<dynamic>> sendTicket({
    required String type,
    required String subject,
    required String message,
  }) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/user/tickets');
      final body = jsonEncode({
        'type': type,
        'subject': subject,
        'message': message,
      });

      final response = await apiClient.post<dynamic>(
        '/api/user/tickets',
        body: {
          'type': type,
          'subject': subject,
          'message': message,
        },
      );

      print('[TicketService] HTTP Status Code: ${response.status}');
      print('[TicketService] Response Body: ${response.data}');

      return response;
    } catch (error) {
      print('[TicketService] Error: $error');
      return ApiResponse<dynamic>(
        status: false,
        message: 'خطا در ارسال تیکت',
        errorCode: 'TICKET_SEND_ERROR',
      );
    }
  }
}
