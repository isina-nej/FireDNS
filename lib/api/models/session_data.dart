/// مدل داده‌های سشن کاربر
class SessionData {
  final String userId;
  final String sessionToken;

  const SessionData({required this.userId, required this.sessionToken});

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      userId: json['userId'] as String,
      sessionToken: json['sessionToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'sessionToken': sessionToken};
  }

  @override
  String toString() {
    return 'SessionData(userId: $userId, sessionToken: $sessionToken)';
  }
}
