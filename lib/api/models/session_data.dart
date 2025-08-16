/// مدل داده‌های سشن کاربر
class SessionData {
  final String jwt;
  final Map<String, dynamic> user;

  const SessionData({required this.jwt, required this.user});

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      jwt: json['jwt'] as String,
      user: json['user'] as Map<String, dynamic>,
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
