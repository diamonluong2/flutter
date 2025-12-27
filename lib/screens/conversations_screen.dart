import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Messages',
          style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
        ),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading &&
              messageProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messageProvider.error != null &&
              messageProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    'Oops! Something went wrong',
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  Text(
                    messageProvider.error!,
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingL),
                  ElevatedButton(
                    onPressed: () {
                      messageProvider.fetchConversations();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    'No conversations yet',
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  Text(
                    'Start a conversation with someone!',
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await messageProvider.fetchConversations();
            },
            child: ListView.builder(
              itemCount: messageProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = messageProvider.conversations[index];
                final userData = conversation['user'] as Map<String, dynamic>?;

                if (userData == null) return const SizedBox.shrink();

                final user = User.fromJson(userData);
                final lastMessage =
                    conversation['lastMessage'] as String? ?? '';
                final lastMessageTime =
                    conversation['lastMessageTime'] as String?;
                final unreadCount = conversation['unreadCount'] as int? ?? 0;
                final isRead = conversation['isRead'] as bool? ?? true;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
                        ? Text(
                            user.username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 20),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.username,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: !isRead
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          _formatTime(lastMessageTime),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTextStyles.body2.copyWith(
                            color: !isRead
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: !isRead
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(otherUser: user),
                      ),
                    ).then((_) {
                      // Refresh conversations when returning
                      if (mounted) {
                        messageProvider.fetchConversations();
                      }
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays == 0) {
        // Today - show time
        final hour = time.hour;
        final minute = time.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        // This week - show day name
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[time.weekday - 1];
      } else {
        // Older - show date
        return '${time.day}/${time.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
