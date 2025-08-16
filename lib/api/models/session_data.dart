/// مدل داده‌های سشن کاربر
class SessionData {
  final String jwt;
  final String user;

  const SessionData({required this.jwt, required this.user});

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      jwt: json['jwt'] as String,
      user: json['user'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'jwt': jwt, 'user': user};
  }

  @override
  String toString() {
    return 'SessionData(jwt: $jwt, user: $user)';
  }
}
