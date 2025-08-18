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
    try {
      // اول سعی می‌کنیم مستقیماً تیکت را ارسال کنیم
      final response = await _apiClient.post<Ticket>(
        '/api/user/tickets',
        body: {
          'type': type,
          'subject': subject,
          'message': message,
        },
        fromJson: (json) => Ticket.fromJson(json),
      );

      // اگر با خطای 401 یا 403 مواجه شدیم، سشن را تازه می‌کنیم
      if (!response.status &&
          (response.errorCode == '401' || response.errorCode == '403')) {
        final sessionResponse = await _sessionService.refreshSession();
        if (!sessionResponse.status) {
          return ApiResponse<Ticket>(
            status: false,
            message: 'خطا در احراز هویت. لطفا دوباره وارد شوید.',
            errorCode: 'AUTH_ERROR',
          );
        }
        // دوباره درخواست را با توکن جدید ارسال می‌کنیم
        return await _apiClient.post<Ticket>(
          '/api/user/tickets',
          body: {
            'type': type,
            'subject': subject,
            'message': message,
          },
          fromJson: (json) => Ticket.fromJson(json),
        );
      }

      return response;
    } catch (e) {
      return ApiResponse<Ticket>(
        status: false,
        message: 'خطا در ارسال تیکت. لطفا دوباره تلاش کنید.',
        errorCode: 'TICKET_ERROR',
      );
    }
  }
}
