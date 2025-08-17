import 'update_type.dart';

/// مدل اطلاعات آپدیت برنامه
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final String description;
  final List<String> features;
  final List<String> changes;
  final UpdateType updateType;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.description,
    required this.features,
    required this.changes,
    required this.updateType,
  });

  /// Factory constructor برای ایجاد از JSON
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    // پشتیبانی از ساختار نمونه API
    final data = json['data'] ?? json;

    return UpdateInfo(
      currentVersion: data['currentVersion'] as String? ?? '',
      latestVersion: data['latestVersion'] as String? ?? '',
      updateUrl:
          data['updateUrl'] as String? ?? data['updateUri'] as String? ?? '',
      description: data['description'] as String? ?? '',
      features: (data['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      changes: (data['changes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      updateType: UpdateType.fromString(data['importance'] as String?),
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'updateUrl': updateUrl,
      'description': description,
      'features': features,
      'changes': changes,
      'importance': updateType.toString(),
    };
  }

  @override
  String toString() {
    return 'UpdateInfo(currentVersion: $currentVersion, latestVersion: $latestVersion, '
        'updateType: $updateType, features: ${features.length}, changes: ${changes.length})';
  }
}
