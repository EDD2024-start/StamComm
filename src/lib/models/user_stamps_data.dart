class UserStampsData {
  final String id;
  final String userId;
  final String stampId;
  final String imageUrl;


  UserStampsData({
    required this.id,
    required this.userId,
    required this.stampId,
    required this.imageUrl,
  });

  factory UserStampsData.fromJson(Map<String, dynamic> json) {
    return UserStampsData(
      id: json['id'],
      userId: json['user_id'],
      stampId: json['stamp_id'],
      imageUrl: json['image_url'],
    );
  }
}
