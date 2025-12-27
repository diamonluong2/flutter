import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../providers/post_provider.dart';
import '../providers/message_provider.dart';
import '../services/pocketbase_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  User user;

  UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _refreshUserStats();
  }

  Future<void> _refreshUserStats() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final stats = await postProvider.pocketBaseService.getUserStats(
      widget.user.id,
    );

    if (mounted) {
      setState(() {
        widget.user = widget.user.copyWith(
          followersCount: stats['followersCount'] ?? widget.user.followersCount,
          followingCount: stats['followingCount'] ?? widget.user.followingCount,
          postsCount: stats['postsCount'] ?? widget.user.postsCount,
        );
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    if (postProvider.currentUser?.id != widget.user.id) {
      final isFollowing = await Provider.of<PostProvider>(
        context,
        listen: false,
      ).pocketBaseService.isFollowing(widget.user.id);

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      if (_isFollowing) {
        await postProvider.pocketBaseService.unfollowUser(widget.user.id);
      } else {
        await postProvider.pocketBaseService.followUser(widget.user.id);
      }
      print("abccc ${widget.user}");

      // Get updated user stats
      final stats = await postProvider.pocketBaseService.getUserStats(
        widget.user.id,
      );

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          widget.user = widget.user.copyWith(
            followersCount:
                stats['followersCount'] ?? widget.user.followersCount,
            followingCount:
                stats['followingCount'] ?? widget.user.followingCount,
            postsCount: stats['postsCount'] ?? widget.user.postsCount,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final isCurrentUser = postProvider.currentUser?.id == widget.user.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.user.username, style: AppTextStyles.headline3),
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          final userPosts = postProvider.posts
              .where((post) => post.author.id == widget.user.id)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Column(
                      children: [
                        // Profile Image
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: widget.user.profileImage != null
                              ? CachedNetworkImageProvider(
                                  widget.user.profileImage!,
                                )
                              : null,
                          child: widget.user.profileImage == null
                              ? Text(
                                  Helpers.getInitials(widget.user.username),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // Username and Verification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.user.username,
                              style: AppTextStyles.headline2,
                            ),
                            if (widget.user.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ],
                        ),

                        if (widget.user.bio != null &&
                            widget.user.bio!.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          Text(
                            widget.user.bio!,
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: AppSizes.paddingL),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              '${Helpers.formatNumber(userPosts.length)}',
                              AppStrings.posts,
                            ),
                            _buildStatItem(
                              '${Helpers.formatNumber(widget.user.followersCount)}',
                              AppStrings.followers,
                            ),
                            _buildStatItem(
                              '${Helpers.formatNumber(widget.user.followingCount)}',
                              AppStrings.following,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.paddingL),

                        // Follow Button and Message Button
                        if (!isCurrentUser) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _toggleFollow,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _isFollowing
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusM,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isFollowing ? 'Following' : 'Follow',
                                          style: AppTextStyles.body1.copyWith(
                                            color: _isFollowing
                                                ? Colors.grey
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingS),
                              OutlinedButton(
                                onPressed: () {
                                  final currentUser =
                                      PocketBaseService().currentUser;
                                  if (currentUser != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChatScreen(otherUser: widget.user),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusM,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(
                                    AppSizes.paddingM,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.message_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingL),

                // User's Posts
                if (userPosts.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Posts', style: AppTextStyles.headline3),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  // TODO: Add PostCard list here
                ] else
                  const Center(
                    child: Text('No posts yet', style: AppTextStyles.body1),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
