class FcmMessage {
  final String type;
  final Map<String, dynamic> data;

  const FcmMessage({required this.type, required this.data});

  factory FcmMessage.fromJson(Map<String, dynamic> json) {
    return FcmMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  static const String typeUpdateAvailable = 'UPDATE_AVAILABLE';
}
