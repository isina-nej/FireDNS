/// مدل تگ DNS
class DnsTag {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const DnsTag({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory DnsTag.fromJson(Map<String, dynamic> json) {
    return DnsTag(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DnsTag(id: $id, name: $name, description: $description)';
  }
}
