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
    UpdateType type = UpdateType.minor;
    final typeString = json['updateType'] as String?;
    if (typeString != null) {
      switch (typeString.toLowerCase()) {
        case 'mandatory':
          type = UpdateType.mandatory;
          break;
        case 'important':
          type = UpdateType.important;
          break;
        case 'minor':
          type = UpdateType.minor;
          break;
      }
    }

    return UpdateInfo(
      currentVersion: json['currentVersion'] as String? ?? '',
      latestVersion: json['latestVersion'] as String? ?? '',
      updateUrl: json['updateUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      changes: (json['changes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      updateType: type,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    String typeString;
    switch (updateType) {
      case UpdateType.mandatory:
        typeString = 'mandatory';
        break;
      case UpdateType.important:
        typeString = 'important';
        break;
      case UpdateType.minor:
        typeString = 'minor';
        break;
    }

    return {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'updateUrl': updateUrl,
      'description': description,
      'features': features,
      'changes': changes,
      'updateType': typeString,
    };
  }

  @override
  String toString() {
    return 'UpdateInfo(currentVersion: $currentVersion, latestVersion: $latestVersion, updateUrl: $updateUrl, description: $description, features: $features, changes: $changes, updateType: $updateType)';
  }
}