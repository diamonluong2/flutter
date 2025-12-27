import 'user.dart';

class Post {
  final String id;
  final User author;
  final String content;
  final List<String> images;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final bool isLiked;
  final bool isApproved;

  Post({
    required this.id,
    required this.author,
    required this.content,
    this.images = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.isLiked = false,
    this.isApproved = true,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: User.fromJson(json['author']),
      content: json['content'],
      images: List<String>.from(json['images'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
      isApproved: json['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'images': images,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'createdAt': createdAt.toIso8601String(),
      'isLiked': isLiked,
      'isApproved': isApproved,
    };
  }

  Post copyWith({
    String? id,
    User? author,
    String? content,
    List<String>? images,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? likedBy,
    DateTime? createdAt,
    bool? isLiked,
    bool? isApproved,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      images: images ?? this.images,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
