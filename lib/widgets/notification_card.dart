import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' as app_notification;
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationCard extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback? onTap;

  const NotificationCard({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 2,
      color: notification.isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  notification.senderUsername?.substring(0, 1).toUpperCase() ??
                      'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: notification.senderUsername ?? 'Someone',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: _getActionText()),
                        ],
                      ),
                    ),

                    // Post content preview (if available)
                    if (notification.postContent != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.postContent!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Comment content (if available)
                    if (notification.commentContent != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '"${notification.commentContent!}"',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    // Time
                    const SizedBox(height: 8),
                    Text(
                      Helpers.formatTimeAgo(notification.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  // Mark as read button
                  if (!notification.isRead)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      onPressed: () {
                        context.read<NotificationProvider>().markAsRead(
                          notification.id,
                        );
                      },
                      tooltip: 'Mark as read',
                      color: Colors.grey[600],
                    ),

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      _showDeleteDialog(context);
                    },
                    tooltip: 'Delete',
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText() {
    switch (notification.type) {
      case app_notification.NotificationType.follow:
        return 'started following you';
      case app_notification.NotificationType.like:
        return 'liked your post';
      case app_notification.NotificationType.comment:
        return 'commented on your post';
      case app_notification.NotificationType.mention:
        return 'mentioned you in a comment';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: const Text(
            'Are you sure you want to delete this notification?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NotificationProvider>().deleteNotification(
                  notification.id,
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
