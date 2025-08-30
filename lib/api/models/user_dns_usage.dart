/// مدل استفاده کاربر از DNS
class UserDnsUsage {
  final String id;
  final String? userDnsId;
  final String? userId;
  final String? internetTag;
  final String? destination;
  final DateTime? connectedAt;

  const UserDnsUsage({
    required this.id,
    this.userDnsId,
    this.userId,
    this.internetTag,
    this.destination,
    this.connectedAt,
  });

  factory UserDnsUsage.fromJson(Map<String, dynamic> json) {
    return UserDnsUsage(
      id: json['id'] as String? ?? '',
      userDnsId: json['userDnsId'] as String?,
      userId: json['userId'] as String?,
      internetTag: json['internetTag'] as String?,
      destination: json['destination'] as String?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userDnsId': userDnsId,
      'userId': userId,
      'internetTag': internetTag,
      'destination': destination,
      'connectedAt': connectedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserDnsUsage(id: $id, userDnsId: $userDnsId, userId: $userId, internetTag: $internetTag, destination: $destination)';
  }
}

/// مدل پاسخ DNS usage از سرور
class DnsUsageResponse {
  final String id;
  final String? userId;
  final String dnsLabel;
  final String dnsIp1;
  final String dnsIp2;
  final DateTime timestamp;
  final String connectionState;
  final Map<String, dynamic> networkInfo;
  final DateTime createdAt;

  const DnsUsageResponse({
    required this.id,
    this.userId,
    required this.dnsLabel,
    required this.dnsIp1,
    required this.dnsIp2,
    required this.timestamp,
    required this.connectionState,
    required this.networkInfo,
    required this.createdAt,
  });

  factory DnsUsageResponse.fromJson(Map<String, dynamic> json) {
    return DnsUsageResponse(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      dnsLabel: json['dnsLabel']?.toString() ?? '',
      dnsIp1: json['dnsIp1']?.toString() ?? '',
      dnsIp2: json['dnsIp2']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      connectionState: json['connectionState']?.toString() ?? '',
      networkInfo: json['networkInfo'] is Map<String, dynamic>
          ? json['networkInfo']
          : {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dnsLabel': dnsLabel,
      'dnsIp1': dnsIp1,
      'dnsIp2': dnsIp2,
      'timestamp': timestamp.toIso8601String(),
      'connectionState': connectionState,
      'networkInfo': networkInfo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DnsUsageResponse(id: $id, dnsLabel: $dnsLabel, connectionState: $connectionState)';
  }
}
