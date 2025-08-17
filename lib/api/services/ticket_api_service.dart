import '../models/ticket_request.dart';
import 'api_client.dart';
import '../models/api_response.dart';

class TicketApiService {
  final ApiClient apiClient;
  TicketApiService(this.apiClient);

  Future<ApiResponse<dynamic>> sendTicket(TicketRequest request) async {
    // فقط endpoint را پاس بده، نه url کامل
    return await apiClient.post(
      '/api/user/tickets',
      body: request.toJson(),
    );
  }
}
