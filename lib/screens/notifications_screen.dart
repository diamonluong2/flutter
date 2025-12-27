import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../models/notification.dart' as app_notification;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          // Update unread count when leaving notifications screen
          context.read<NotificationProvider>().updateUnreadCount();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(AppStrings.notifications, style: AppTextStyles.headline3),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                if (notificationProvider.hasUnread) {
                  return TextButton(
                    onPressed: () {
                      notificationProvider.markAllAsRead();
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading &&
                notificationProvider.notifications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (notificationProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${notificationProvider.error}',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        notificationProvider.refreshNotifications();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (notificationProvider.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: AppTextStyles.headline3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When someone follows you, likes your post, or comments, you\'ll see it here.',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => notificationProvider.refreshNotifications(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notificationProvider.notifications.length + 1,
                itemBuilder: (context, index) {
                  if (index == notificationProvider.notifications.length) {
                    // Show load more button or loading indicator
                    if (notificationProvider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final notification =
                      notificationProvider.notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () {
                      // Handle notification tap
                      if (!notification.isRead) {
                        notificationProvider.markAsRead(notification.id);
                      }

                      // Navigate to relevant screen based on notification type
                      _handleNotificationTap(context, notification);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    app_notification.Notification notification,
  ) {
    switch (notification.type) {
      case app_notification.NotificationType.follow:
        // Navigate to user profile
        // Navigator.pushNamed(context, '/user-profile', arguments: notification.senderId);
        break;
      case app_notification.NotificationType.like:
      case app_notification.NotificationType.comment:
        // Navigate to post detail
        if (notification.postId != null) {
          // Navigator.pushNamed(context, '/post-detail', arguments: notification.postId);
        }
        break;
      case app_notification.NotificationType.mention:
        // Navigate to comment or post
        break;
    }
  }
}
