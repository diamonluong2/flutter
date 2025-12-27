import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../utils/blacklist.dart';
import '../widgets/post_card.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load posts and notifications when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: AppStrings.search,
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Badge(
                    label: Text(
                      notificationProvider.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    isLabelVisible: notificationProvider.hasUnread,
                    child: const Icon(Icons.notifications_outlined),
                  );
                },
              ),
              activeIcon: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Badge(
                    label: Text(
                      notificationProvider.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    isLabelVisible: notificationProvider.hasUnread,
                    child: const Icon(Icons.notifications),
                  );
                },
              ),
              label: AppStrings.notifications,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _showCreatePostDialog();
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostSheet(),
    );
  }
}

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        // Clear error when user types
        if (_errorMessage != null) {
          _errorMessage = null;
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) return;

    // Kiểm tra blacklist trước khi tạo post
    final bannedWords = Blacklist.checkContent(content);
    if (bannedWords != null) {
      setState(() {
        _errorMessage = Blacklist.getErrorMessage(bannedWords);
      });
      return;
    }

    // Clear error nếu không có vi phạm
    setState(() {
      _errorMessage = null;
    });

    final postProvider = context.read<PostProvider>();
    await postProvider.createPost(content, _selectedImages);

    if (mounted) {
      // Kiểm tra nếu có lỗi khác (không phải blacklist)
      if (postProvider.error != null) {
        setState(() {
          _errorMessage = postProvider.error;
        });
      } else {
        // Chỉ đóng dialog nếu không có lỗi
        Navigator.of(context).pop();
        _contentController.clear();
        _selectedImages.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusL),
          topRight: Radius.circular(AppSizes.radiusL),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppStrings.cancel,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Consumer<PostProvider>(
                  builder: (context, postProvider, child) {
                    final isContentEmpty = _contentController.text
                        .trim()
                        .isEmpty;
                    final isLoading = postProvider.isLoading;

                    // Debug print
                    print(
                      'CreatePostSheet - Content empty: $isContentEmpty, Loading: $isLoading, Text: "${_contentController.text}"',
                    );

                    return ElevatedButton(
                      onPressed: isContentEmpty ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: postProvider.isLoading
                          ? const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              AppStrings.post,
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                // Text Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120, // Giảm chiều cao từ Expanded xuống 120px
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red
                              : AppColors.border,
                          width: _errorMessage != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: AppStrings.whatHappening,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(
                            AppSizes.paddingM,
                          ),
                          hintStyle: AppTextStyles.body1.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        style: AppTextStyles.body1,
                      ),
                    ),
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: AppSizes.paddingS),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSizes.paddingM),

                // Selected Images
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(
                            right: AppSizes.paddingS,
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                                child: Image.file(
                                  File(_selectedImages[index]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                ],

                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showImageSourceDialog(),
                      icon: const Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Add location functionality
                      },
                      icon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
