class Like {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? '',
      postId: json['post'] ?? '',
      userId: json['user'] ?? '',
      createdAt: DateTime.parse(
        json['created'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'user': userId,
      'created': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Like(id: $id, postId: $postId, userId: $userId, createdAt: $createdAt)';
  }
}
