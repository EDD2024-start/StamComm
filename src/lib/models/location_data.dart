class LocationData {
  final String id;
  final String name;
  final String descriptionText;
  final String descriptionImageUrl;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  LocationData({
    required this.id,
    required this.name,
    required this.descriptionText,
    required this.descriptionImageUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // JSONデータをLocationDataに変換するfactoryコンストラクタ
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['id'],
      name: json['name'],
      descriptionText: json['description_text'],
      descriptionImageUrl: json['description_image_url'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }
}
