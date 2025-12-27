enum NotificationType { follow, like, comment, mention }

class Notification {
  final String id;
  final String recipientId;
  final String senderId;
  final String? senderUsername;
  final String? senderProfileImage;
  final NotificationType type;
  final String? postId;
  final String? postContent;
  final String? commentContent;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    this.senderUsername,
    this.senderProfileImage,
    required this.type,
    this.postId,
    this.postContent,
    this.commentContent,
    this.isRead = false,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      recipientId: json['recipientId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderProfileImage: json['senderProfileImage'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.follow,
      ),
      postId: json['postId'],
      postContent: json['postContent'],
      commentContent: json['commentContent'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfileImage': senderProfileImage,
      'type': type.toString().split('.').last,
      'postId': postId,
      'postContent': postContent,
      'commentContent': commentContent,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get message {
    switch (type) {
      case NotificationType.follow:
        return '$senderUsername started following you';
      case NotificationType.like:
        return '$senderUsername liked your post';
      case NotificationType.comment:
        return '$senderUsername commented on your post';
      case NotificationType.mention:
        return '$senderUsername mentioned you in a comment';
    }
  }

  Notification copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderUsername,
    String? senderProfileImage,
    NotificationType? type,
    String? postId,
    String? postContent,
    String? commentContent,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      postContent: postContent ?? this.postContent,
      commentContent: commentContent ?? this.commentContent,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
