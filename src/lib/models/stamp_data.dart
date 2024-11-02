class StampData {
  final String id;
  final String eventId;
  final double latitude;
  final double longitude;
  final String name;
  final String descriptionText;
  final String descriptionImageUrl;

  StampData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.descriptionText,
    required this.descriptionImageUrl,
    required this.eventId,
  });

  factory StampData.fromJson(Map<String, dynamic> json) {
    print('StampData.fromJson_____: $json');
    return StampData(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      name: json['name'],
      descriptionText: json['description_text'],
      descriptionImageUrl: json['description_image_url'],
      eventId: json['event_id'],
    );
  }
}
