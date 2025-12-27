import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/message_provider.dart';
import '../utils/constants.dart';
import '../widgets/post_card.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RefreshIndicator _refreshIndicator = RefreshIndicator(
    onRefresh: () async {
      // Refresh posts
    },
    child: const SizedBox(),
  );

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppStrings.appName,
          style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Badge(
                offset: const Offset(-7, 7),
                label: Text(
                  notificationProvider.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                isLabelVisible: notificationProvider.hasUnread,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    final navigatorContext = context;
                    Navigator.push(
                      navigatorContext,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ).then((_) {
                      // Refresh notifications count when returning from notifications screen
                      if (mounted) {
                        navigatorContext
                            .read<NotificationProvider>()
                            .updateUnreadCount();
                      }
                    });
                  },
                ),
              );
            },
          ),
          Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
              return Badge(
                offset: const Offset(-7, 7),
                label: Text(
                  messageProvider.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                isLabelVisible: messageProvider.hasUnread,
                child: IconButton(
                  icon: const Icon(Icons.message_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConversationsScreen(),
                      ),
                    ).then((_) {
                      // Refresh unread count when returning
                      if (mounted) {
                        context.read<MessageProvider>().updateUnreadCount();
                      }
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return _buildShimmerLoading();
          }

          if (postProvider.error != null && postProvider.posts.isEmpty) {
            return _buildErrorWidget(postProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await postProvider.fetchPosts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: AppSizes.paddingS),
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: Colors.grey.shade300,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: Colors.grey.shade300,
                            child: Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: Colors.grey.shade300,
                            child: Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingM),
                Shimmer.fromColors(
                  baseColor: AppColors.surface,
                  highlightColor: Colors.grey.shade300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingM),
                Shimmer.fromColors(
                  baseColor: AppColors.surface,
                  highlightColor: Colors.grey.shade300,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppSizes.paddingM),
          Text(
            'Oops! Something went wrong',
            style: AppTextStyles.headline3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingS),
          Text(error, style: AppTextStyles.body2, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.paddingL),
          ElevatedButton(
            onPressed: () {
              context.read<PostProvider>().fetchPosts();
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
}
