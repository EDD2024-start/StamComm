class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.userComment,
    required this.updatedAt,
  });

  /// User ID of the profile
  final String id;

  /// Username of the profile
  final String username;

  /// Date and time when the profile was created
  final DateTime createdAt;

  /// User comment of the profile
  final String? userComment;

  /// Date and time when the profile was last updated
  final DateTime updatedAt;

  factory Profile.fromMap(
      {required Map<String, dynamic> map, required String myUserId}) {
    return Profile(
      id: map['id'],
      username: map['username'],
      createdAt: DateTime.parse(map['created_at']),
      userComment: map['user_comment'],
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'user_comment': userComment,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
