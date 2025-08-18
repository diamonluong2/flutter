class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profileImage: json['profileImage'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
