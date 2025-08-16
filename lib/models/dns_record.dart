class DnsRecord {
  final String id;
  final String label;
  final String ip1;
  final String ip2;

  DnsRecord({
    required this.id,
    required this.label,
    required this.ip1,
    this.ip2 = '',
  });

  factory DnsRecord.fromJson(Map<String, dynamic> json) {
    return DnsRecord(
      id: json['id'] as String,
      label: json['label'] as String,
      ip1: json['ip1'] as String,
      ip2: json['ip2'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'ip1': ip1,
      'ip2': ip2,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DnsRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ip1 == other.ip1 &&
          ip2 == other.ip2;

  @override
  int get hashCode => Object.hash(id, ip1, ip2);
}
