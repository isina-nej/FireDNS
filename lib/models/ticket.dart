class Ticket {
  final String? id;
  final String type;
  final String subject;
  final String message;
  final String? createdAt;
  final String? status;

  Ticket({
    this.id,
    required this.type,
    required this.subject,
    required this.message,
    this.createdAt,
    this.status,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String?,
      type: json['type'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'subject': subject,
      'message': message,
      if (createdAt != null) 'createdAt': createdAt,
      if (status != null) 'status': status,
    };
  }
}
