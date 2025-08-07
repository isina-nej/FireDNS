/// مدل استفاده کاربر از DNS
class UserDnsUsage {
  final String id;
  final String userDnsId;
  final String userId;
  final String internetTag;
  final String? destination;
  final DateTime connectedAt;

  const UserDnsUsage({
    required this.id,
    required this.userDnsId,
    required this.userId,
    required this.internetTag,
    this.destination,
    required this.connectedAt,
  });

  factory UserDnsUsage.fromJson(Map<String, dynamic> json) {
    return UserDnsUsage(
      id: json['id'] as String,
      userDnsId: json['userDnsId'] as String,
      userId: json['userId'] as String,
      internetTag: json['internetTag'] as String,
      destination: json['destination'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userDnsId': userDnsId,
      'userId': userId,
      'internetTag': internetTag,
      'destination': destination,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserDnsUsage(id: $id, userDnsId: $userDnsId, userId: $userId, internetTag: $internetTag, destination: $destination)';
  }
}
