import 'user.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final User? sender;
  final User? recipient;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.sender,
    this.recipient,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'] ?? json['sender'],
      recipientId: json['recipientId'] ?? json['recipient'],
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'] is Map<String, dynamic>
          ? User.fromJson(json['sender'])
          : null,
      recipient: json['recipient'] is Map<String, dynamic>
          ? User.fromJson(json['recipient'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender?.toJson(),
      'recipient': recipient?.toJson(),
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    User? sender,
    User? recipient,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
    );
  }
}
