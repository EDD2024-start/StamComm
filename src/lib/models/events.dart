class Event {
  String id;
  String name;
  String descriptionText;
  String descriptionImageUrl;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime deletedAt;

  Event({
    required this.id,
    required this.name,
    required this.descriptionText,
    required this.descriptionImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });
}