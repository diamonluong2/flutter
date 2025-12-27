import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPosts();
  }

  void _loadPosts() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    if (postProvider.posts.isEmpty) {
      postProvider.fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(AppStrings.profile, style: AppTextStyles.headline3),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PostProvider>(
        builder: (context, authProvider, postProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text(
                'Please login to view profile',
                style: AppTextStyles.body1,
              ),
            );
          }

          final user = authProvider.currentUser!;

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
                          backgroundImage: user.profileImage != null
                              ? CachedNetworkImageProvider(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Text(
                                  Helpers.getInitials(user.username),
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
                            Text(user.username, style: AppTextStyles.headline2),
                            if (user.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ],
                        ),

                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          Text(
                            user.bio!,
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
                              '${Helpers.formatNumber(postProvider.posts.where((post) => post.author.id == user.id).length)}',
                              AppStrings.posts,
                            ),
                            _buildStatItem(
                              '${Helpers.formatNumber(user.followersCount)}',
                              AppStrings.followers,
                            ),
                            _buildStatItem(
                              '${Helpers.formatNumber(user.followingCount)}',
                              AppStrings.following,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.paddingL),

                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                              // Refresh profile data if profile was updated
                              if (result == true && mounted) {
                                // Profile was updated, refresh data
                                setState(() {});
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusM,
                                ),
                              ),
                            ),
                            child: Text(
                              AppStrings.editProfile,
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Menu Items
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: AppStrings.settings,
                        onTap: () {
                          // Navigate to settings
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: AppStrings.help,
                        onTap: () {
                          // Navigate to help
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: AppStrings.about,
                        onTap: () {
                          // Navigate to about
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: AppStrings.privacy,
                        onTap: () {
                          // Navigate to privacy
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: AppStrings.terms,
                        onTap: () {
                          // Navigate to terms
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: AppStrings.logout,
                        onTap: () {
                          _showLogoutDialog(context, authProvider);
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          color: isDestructive ? Colors.red : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
