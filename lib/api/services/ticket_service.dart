import '../services/api_client.dart';
import '../../models/ticket.dart';
import '../../api/models/api_response.dart';
import '../services/session_api_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  late final ApiClient _apiClient;
  late final SessionApiService _sessionService;

  factory TicketService() {
    return _instance;
  }

  TicketService._internal() {
    _apiClient = ApiClient();
    _sessionService = SessionApiService();
  }

  Future<ApiResponse<Ticket>> createTicket({
    required String type,
    required String subject,
    required String message,
  }) async {
    // اول سشن را تازه می‌کنیم تا از معتبر بودن توکن مطمئن شویم
    final sessionResponse = await _sessionService.refreshSession();
    if (!sessionResponse.status) {
      return ApiResponse<Ticket>(
        status: false,
        message: 'خطا در احراز هویت. لطفا دوباره وارد شوید.',
        errorCode: 'AUTH_ERROR',
      );
    }

    final body = {
      'type': type,
      'subject': subject,
      'message': message,
    };
    return _apiClient.post<Ticket>(
      '/api/user/tickets',
      body: body,
      fromJson: (json) => Ticket.fromJson(json),
    );
  }
}
