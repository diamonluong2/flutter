import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_profile_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) {
    print('post: ${this.post.commentsCount}');
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileScreen(user: post.author),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: post.author.profileImage != null
                        ? CachedNetworkImageProvider(post.author.profileImage!)
                        : null,
                    child: post.author.profileImage == null
                        ? Text(
                            Helpers.getInitials(post.author.username),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserProfileScreen(user: post.author),
                                ),
                              );
                            },
                            child: Text(
                              post.author.username,
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (post.author.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        Helpers.formatTimeAgo(post.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (context) {
                    final currentUser = context
                        .read<PostProvider>()
                        .currentUser;
                    final isAuthor = currentUser?.id == post.author.id;

                    return [
                      if (isAuthor)
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: AppSizes.paddingS),
                              const Text('Delete'),
                            ],
                          ),
                          onTap: () async {
                            // Delay to allow popup to close
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );

                            // Show confirmation dialog
                            if (context.mounted) {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Post'),
                                  content: const Text(
                                    'Are you sure you want to delete this post?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete == true && context.mounted) {
                                try {
                                  await context.read<PostProvider>().deletePost(
                                    post.id,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Post deleted'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              }
                            }
                          },
                        ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingS),

            // Post Content
            if (post.content.isNotEmpty) ...[
              Text(post.content, style: AppTextStyles.body1),
              const SizedBox(height: AppSizes.paddingS),
            ],

            // Post Images
            if (post.images.isNotEmpty) ...[
              _buildImageGrid(),
              const SizedBox(height: AppSizes.paddingS),
            ],

            // Post Actions
            Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: Helpers.formatNumber(post.likesCount),
                  color: post.isLiked
                      ? AppColors.like
                      : AppColors.textSecondary,
                  onTap: () async {
                    await context.read<PostProvider>().toggleLike(post.id);
                  },
                ),
                const SizedBox(width: AppSizes.paddingL),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: Helpers.formatNumber(post.commentsCount),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSizes.paddingL),
                _buildActionButton(
                  icon: Icons.repeat,
                  label: Helpers.formatNumber(post.sharesCount),
                  onTap: () {
                    context.read<PostProvider>().sharePost(post.id);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share post
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (post.images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: CachedNetworkImage(
          imageUrl: post.images.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: AppColors.surface,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: AppColors.surface,
            child: const Icon(Icons.error),
          ),
        ),
      );
    } else if (post.images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusM),
                bottomLeft: Radius.circular(AppSizes.radiusM),
              ),
              child: CachedNetworkImage(
                imageUrl: post.images[0],
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppSizes.radiusM),
                bottomRight: Radius.circular(AppSizes.radiusM),
              ),
              child: CachedNetworkImage(
                imageUrl: post.images[1],
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    } else if (post.images.length >= 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusM),
                bottomLeft: Radius.circular(AppSizes.radiusM),
              ),
              child: CachedNetworkImage(
                imageUrl: post.images[0],
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppSizes.radiusM),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.images[1],
                    height: 99,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(AppSizes.radiusM),
                  ),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: post.images[2],
                        height: 99,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (post.images.length > 3)
                        Container(
                          height: 99,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(AppSizes.radiusM),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${post.images.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingS,
          vertical: AppSizes.paddingXS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconM,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
