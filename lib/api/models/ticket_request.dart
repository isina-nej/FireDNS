class TicketRequest {
  final String type;
  final String subject;
  final String message;

  TicketRequest(
      {required this.type, required this.subject, required this.message});

  Map<String, dynamic> toJson() => {
        'type': type,
        'subject': subject,
        'message': message,
      };
}
