import 'user.dart';

class Comment {
  final String id;
  final String content;
  final User author;
  final String postId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.postId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      author: User.fromJson(json['author']),
      postId: json['post'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author.toJson(),
      'post': postId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
