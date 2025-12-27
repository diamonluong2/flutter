import 'dart:convert';
import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' show MultipartFile;
import '../models/user.dart';
import '../models/like.dart';
import '../models/notification.dart';
import '../models/message.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  final PocketBase _pb = PocketBase('http://127.0.0.1:8090');

  // Get PocketBase instance
  PocketBase get pb => _pb;

  // Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;

  // Get current user
  User? get currentUser {
    if (!isAuthenticated) return null;

    final authModel = _pb.authStore.model;
    if (authModel == null) return null;

    return User(
      id: authModel.id,
      username: authModel.data?['username'] ?? authModel.data?['name'] ?? '',
      email: authModel.data?['email'] ?? '',
      profileImage: _buildAvatarUrl(authModel),
      bio: authModel.data?['bio'] ?? '',
      followersCount: authModel.data?['followersCount'] ?? 0,
      followingCount: authModel.data?['followingCount'] ?? 0,
      postsCount: authModel.data?['postsCount'] ?? 0,
      isVerified: authModel.data?['verified'] ?? false,
      createdAt: DateTime.parse(authModel.created),
    );
  }

  // Login user
  Future<User> login(String email, String password) async {
    try {
      final authData = await _pb
          .collection('users')
          .authWithPassword(email, password);

      if (authData.record == null) {
        throw Exception('Login failed');
      }

      return User(
        id: authData.record!.id,
        username:
            authData.record!.data?['username'] ??
            authData.record!.data?['name'] ??
            '',
        email: authData.record!.data?['email'] ?? '',
        profileImage: _buildAvatarUrl(authData.record!),
        bio: authData.record!.data?['bio'] ?? '',
        followersCount: authData.record!.data?['followersCount'] ?? 0,
        followingCount: authData.record!.data?['followingCount'] ?? 0,
        postsCount: authData.record!.data?['postsCount'] ?? 0,
        isVerified: authData.record!.data?['verified'] ?? false,
        createdAt: DateTime.parse(authData.record!.created),
      );
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Register user
  Future<User> register(String username, String email, String password) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'emailVisibility': true,
        'name': username,
        'password': password,
        'passwordConfirm': password,
        'username': username,
        'bio': '',
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
      };

      final record = await _pb.collection('users').create(body: body);

      // Auto login after registration
      final authData = await _pb
          .collection('users')
          .authWithPassword(email, password);

      if (authData.record == null) {
        throw Exception('Registration successful but auto-login failed');
      }

      return User(
        id: authData.record!.id,
        username:
            authData.record!.data?['username'] ??
            authData.record!.data?['name'] ??
            '',
        email: authData.record!.data?['email'] ?? '',
        profileImage: _buildAvatarUrl(authData.record!),
        bio: authData.record!.data?['bio'] ?? '',
        followersCount: authData.record!.data?['followersCount'] ?? 0,
        followingCount: authData.record!.data?['followingCount'] ?? 0,
        postsCount: authData.record!.data?['postsCount'] ?? 0,
        isVerified: authData.record!.data?['verified'] ?? false,
        createdAt: DateTime.parse(authData.record!.created),
      );
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Logout user
  void logout() {
    _pb.authStore.clear();
  }

  // Update user profile
  Future<User> updateProfile({
    String? username,
    String? bio,
    String? profileImage,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final body = <String, dynamic>{};
      if (username != null) body['name'] = username;
      if (bio != null) body['bio'] = bio;
      final List<MultipartFile> files = [];
      if (profileImage != null) {
        final fileBytes = await File(profileImage).readAsBytes();
        final fileName = profileImage.split('/').last;
        files.add(
          MultipartFile.fromBytes('avatar', fileBytes, filename: fileName),
        );
      }

      final record = await _pb
          .collection('users')
          .update(_pb.authStore.model!.id, body: body, files: files);

      // Get user stats
      final postsCount = await _pb
          .collection('posts')
          .getList(filter: 'author = "${record.id}"')
          .then((result) => result.totalItems);

      final followersCount = await _pb
          .collection('follows')
          .getList(filter: 'following = "${record.id}"')
          .then((result) => result.totalItems);

      final followingCount = await _pb
          .collection('follows')
          .getList(filter: 'followers = "${record.id}"')
          .then((result) => result.totalItems);

      // Update user stats
      await _pb
          .collection('users')
          .update(
            record.id,
            body: {
              'postsCount': postsCount,
              'followersCount': followersCount,
              'followingCount': followingCount,
            },
          );

      return User(
        id: record.id,
        username: record.data?['username'] ?? record.data?['name'] ?? '',
        email: record.data?['email'] ?? '',
        profileImage: _buildAvatarUrl(record),
        bio: record.data?['bio'] ?? '',
        followersCount: followersCount,
        followingCount: followingCount,
        postsCount: postsCount,
        isVerified: record.data?['verified'] ?? false,
        createdAt: DateTime.parse(record.created),
      );
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Get user stats
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final postsCount = await _pb
          .collection('posts')
          .getList(filter: 'author="$userId"')
          .then((result) => result.totalItems);

      final followersCount = await _pb
          .collection('follows')
          .getList(filter: 'following="$userId"')
          .then((result) => result.totalItems);

      final followingCount = await _pb
          .collection('follows')
          .getList(filter: 'followers="$userId"')
          .then((result) => result.totalItems);

      return {
        'postsCount': postsCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: ${e.toString()}');
    }
  }

  // Get posts
  Future<List<Map<String, dynamic>>> getPosts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // Try different filter syntaxes for boolean in PocketBase
      // PocketBase boolean filter syntax: isApproved=true (no spaces) or isApproved != false
      // If filter doesn't work, we'll filter client-side as backup
      final result = await _pb
          .collection('posts')
          .getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            expand: 'author',
            filter: 'isApproved=true',
          );

      final posts = await Future.wait(
        result.items.map((record) async {
          // Handle author data from expanded relation
          dynamic authorExpand = record.expand?['author'];
          RecordModel? authorRecord;

          // Extract author RecordModel safely
          try {
            if (authorExpand != null) {
              if (authorExpand is List && authorExpand.isNotEmpty) {
                authorRecord = authorExpand.first as RecordModel;
              } else if (authorExpand is RecordModel) {
                authorRecord = authorExpand;
              }
            }
          } catch (e) {
            authorRecord = null;
          }

          final commentsCount = await _pb
              .collection('comments')
              .getList(filter: 'post = "${record.id}"')
              .then((result) => result.totalItems);

          // Check if current user has liked this post
          final hasLiked = await hasLikedPost(record.id);

          // Handle isApproved field - could be bool, string, or null
          final isApprovedValue = record.data['isApproved'];
          final isApproved = isApprovedValue != null
              ? (isApprovedValue is bool
                    ? isApprovedValue
                    : (isApprovedValue.toString().toLowerCase() == 'true'))
              : true;

          return {
            'id': record.id,
            'content': record.data['content'] ?? '',
            'images': _parseImages(record.data['images'], record.id),
            'likesCount': record.data['likesCount'] ?? 0,
            'commentsCount': commentsCount,
            'hasLiked': hasLiked,
            'sharesCount': record.data['sharesCount'] ?? 0,
            'createdAt': record.created,
            'isApproved': isApproved,
            'author': authorRecord != null
                ? {
                    'id': authorRecord.id,
                    'username':
                        authorRecord.data?['username'] ??
                        authorRecord.data?['name'] ??
                        '',
                    'email': authorRecord.data?['email'] ?? '',
                    'profileImage': _buildAvatarUrl(authorRecord),
                    'bio': authorRecord.data?['bio'] ?? '',
                    'followersCount': authorRecord.data?['followersCount'] ?? 0,
                    'followingCount': authorRecord.data?['followingCount'] ?? 0,
                    'postsCount': authorRecord.data?['postsCount'] ?? 0,
                    'isVerified': authorRecord.data?['verified'] ?? false,
                    'createdAt': authorRecord.created,
                  }
                : null,
          };
        }),
      );

      return posts;
    } catch (e) {
      throw Exception('Failed to fetch posts: ${e.toString()}');
    }
  }

  // Create post
  Future<Map<String, dynamic>> createPost(
    String content,
    List<String> imagePaths,
  ) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Prepare files for upload
      final files = <MultipartFile>[];
      for (String imagePath in imagePaths) {
        final fileBytes = await File(imagePath).readAsBytes();
        final fileName = imagePath.split('/').last;
        files.add(
          await MultipartFile.fromBytes(
            'images',
            fileBytes,
            filename: fileName,
          ),
        );
      }

      final body = <String, dynamic>{
        'content': content,
        'likesCount': 0,
        'sharesCount': 0,
        'author': _pb.authStore.model!.id,
        'isApproved': true,
      };

      // Create post with files
      final record = await _pb
          .collection('posts')
          .create(body: body, files: files);

      return {
        'id': record.id,
        'content': record.data['content'] ?? '',
        'images': _parseImages(record.data['images'], record.id),
        'likesCount': record.data['likesCount'] ?? 0,
        'commentsCount': record.data['commentsCount'] ?? 0,
        'sharesCount': record.data['sharesCount'] ?? 0,
        'createdAt': record.created,
        'isApproved': record.data['isApproved'] ?? true,
        'author': currentUser?.toJson(),
      };
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  // Check if user has liked a post
  Future<bool> hasLikedPost(String postId) async {
    try {
      if (!isAuthenticated) return false;

      final result = await _pb
          .collection('likes')
          .getList(
            filter: 'user="${_pb.authStore.model!.id}" && post="$postId"',
          );

      return result.items.isNotEmpty;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      if (await hasLikedPost(postId)) {
        throw Exception('Post already liked');
      }

      // Create like record
      await _pb
          .collection('likes')
          .create(body: {'user': _pb.authStore.model!.id, 'post': postId});

      // Get post author to create notification
      final postRecord = await _pb.collection('posts').getOne(postId);
      final postAuthorId = postRecord.data['author'];
      final postContent = postRecord.data['content'];

      // Create notification for like
      await createNotification(
        recipientId: postAuthorId,
        type: NotificationType.like,
        postId: postId,
        postContent: postContent,
      );

      // Update post likes count
    } catch (e) {
      print('Failed to like post: ${e.toString()}');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Find the like record
      final result = await _pb
          .collection('likes')
          .getList(
            filter: 'user="${_pb.authStore.model!.id}" && post="$postId"',
          );

      if (result.items.isEmpty) {
        throw Exception('Post not liked');
      }

      // Delete the like record
      await _pb.collection('likes').delete(result.items.first.id);
    } catch (e) {
      throw Exception('Failed to unlike post: ${e.toString()}');
    }
  }

  // Toggle like/unlike post
  Future<void> toggleLike(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final hasLiked = await hasLikedPost(postId);
      print('hasLiked: $hasLiked');
      if (hasLiked) {
        await unlikePost(postId);
      } else {
        await likePost(postId);
      }
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
    }
  }

  // Get likes for a post
  Future<List<Like>> getPostLikes(String postId) async {
    try {
      final result = await _pb
          .collection('likes')
          .getList(filter: 'post="$postId"', sort: '-created', expand: 'user');

      return result.items.map((record) {
        return Like(
          id: record.id,
          postId: record.data['post'] ?? '',
          userId: record.data['user'] ?? '',
          createdAt: DateTime.parse(record.created),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch post likes: ${e.toString()}');
    }
  }

  // Get likes count for a post
  Future<int> getPostLikesCount(String postId) async {
    try {
      final result = await _pb
          .collection('likes')
          .getList(filter: 'post="$postId"');

      return result.totalItems;
    } catch (e) {
      throw Exception('Failed to get post likes count: ${e.toString()}');
    }
  }

  // Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final result = await _pb
          .collection('comments')
          .getList(
            filter: 'post = "$postId"',
            sort: '-created',
            expand: 'author',
          );

      return result.items.map((record) {
        final authorData = record.expand?['author'];
        final author = authorData != null
            ? (authorData is List ? authorData.first : authorData)
                  as RecordModel
            : null;

        return {
          'id': record.id,
          'content': record.data['content'] ?? '',
          'post': record.data['post'],
          'createdAt': record.created,
          'author': author != null
              ? {
                  'id': author.id,
                  'username':
                      author.data?['username'] ?? author.data?['name'] ?? '',
                  'email': author.data?['email'] ?? '',
                  'profileImage': _buildAvatarUrl(author),
                  'bio': author.data?['bio'] ?? '',
                  'followersCount': author.data?['followersCount'] ?? 0,
                  'followingCount': author.data?['followingCount'] ?? 0,
                  'postsCount': author.data?['postsCount'] ?? 0,
                  'isVerified': author.data?['verified'] ?? false,
                  'createdAt': author.created,
                }
              : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: ${e.toString()}');
    }
  }

  // Add comment
  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final body = <String, dynamic>{
        'content': content,
        'post': postId,
        'author': _pb.authStore.model!.id,
      };

      final record = await _pb.collection('comments').create(body: body);

      // Get post author to create notification
      final postRecord = await _pb.collection('posts').getOne(postId);
      final postAuthorId = postRecord.data['author'];
      final postContent = postRecord.data['content'];

      // Create notification for comment
      await createNotification(
        recipientId: postAuthorId,
        type: NotificationType.comment,
        postId: postId,
        postContent: postContent,
        commentContent: content,
      );

      return {
        'id': record.id,
        'content': record.data['content'] ?? '',
        'post': record.data['post'],
        'createdAt': record.created,
        'author': currentUser?.toJson(),
      };
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Delete the post
      await _pb.collection('posts').delete(postId);

      // Delete all comments of the post
      final comments = await _pb
          .collection('comments')
          .getList(filter: 'post = "$postId"');

      for (final comment in comments.items) {
        await _pb.collection('comments').delete(comment.id);
      }
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  // Request email verification
  Future<void> requestEmailVerification(String email) async {
    try {
      await _pb.collection('users').requestVerification(email);
    } catch (e) {
      throw Exception('Failed to request email verification: ${e.toString()}');
    }
  }

  // Confirm email verification
  Future<void> confirmEmailVerification(String token) async {
    try {
      await _pb.collection('users').confirmVerification(token);
    } catch (e) {
      throw Exception('Failed to confirm email verification: ${e.toString()}');
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pb.collection('users').requestPasswordReset(email);
    } catch (e) {
      throw Exception('Failed to request password reset: ${e.toString()}');
    }
  }

  // Confirm password reset
  Future<void> confirmPasswordReset(
    String token,
    String password,
    String passwordConfirm,
  ) async {
    try {
      await _pb
          .collection('users')
          .confirmPasswordReset(token, password, passwordConfirm);
    } catch (e) {
      throw Exception('Failed to confirm password reset: ${e.toString()}');
    }
  }

  // Helper method to safely parse images
  List<String> _parseImages(dynamic imagesData, String recordId) {
    try {
      if (imagesData == null) return [];

      if (imagesData is String) {
        // If it's a string, try to parse as JSON
        try {
          final List<dynamic> parsed = jsonDecode(imagesData);
          return _addBaseUrlToImages(parsed, recordId);
        } catch (e) {
          // If JSON parsing fails, treat as single image URL
          return _addBaseUrlToImages([imagesData], recordId);
        }
      }

      if (imagesData is List) {
        return _addBaseUrlToImages(imagesData, recordId);
      }

      return [];
    } catch (e) {
      print('Error parsing images: $e');
      return [];
    }
  }

  // Helper method to add base URL to image paths
  List<String> _addBaseUrlToImages(List<dynamic> images, String recordId) {
    final collectionId = 'pbc_1125843985'; // Collection ID for posts
    return images.map((item) {
      final fileName = item.toString();
      // Check if it's already a full URL
      if (fileName.startsWith('http')) {
        return fileName;
      }
      // Construct the full URL using the post's ID
      return '${_pb.baseUrl}/api/files/$collectionId/$recordId/$fileName';
    }).toList();
  }

  // Helper method to build avatar URL
  String? _buildAvatarUrl(RecordModel record) {
    final avatar = record.data?['avatar'];
    if (avatar == null || avatar.toString().isEmpty) {
      return null;
    }

    // If it's already a full URL, return as is
    if (avatar.toString().startsWith('http')) {
      return avatar.toString();
    }

    // Build the full URL for avatar using the users collection
    return '${_pb.baseUrl}/api/files/users/${record.id}/$avatar';
  }

  // Check if current user is following a user
  Future<bool> isFollowing(String userId) async {
    try {
      if (!isAuthenticated) return false;

      final result = await _pb
          .collection('follows')
          .getList(
            filter:
                'followers="${_pb.authStore.model!.id}" && following="$userId"',
          );

      // final result2 = await _pb.collection('follows').getList();

      return result.items.isNotEmpty;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Check if already following
      if (await isFollowing(userId)) {
        throw Exception('Already following this user');
      }

      await _pb
          .collection('follows')
          .create(
            body: {'followers': _pb.authStore.model!.id, 'following': userId},
          );

      // Create notification for follow
      await createNotification(
        recipientId: userId,
        type: NotificationType.follow,
      );

      // Update follower and following counts
      // await _updateFollowCounts(userId);
    } catch (e) {
      throw Exception('Failed to follow user: ${e.toString()}');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Find the follow record
      final result = await _pb
          .collection('follows')
          .getList(
            filter:
                'followers="${_pb.authStore.model!.id}" && following="$userId"',
          );

      if (result.items.isEmpty) {
        throw Exception('Not following this user');
      }

      // Delete the follow record
      await _pb.collection('follows').delete(result.items.first.id);

      // Update follower and following counts
      // await _updateFollowCounts(userId);
    } catch (e) {
      throw Exception('Failed to unfollow user: ${e.toString()}');
    }
  }

  // Helper method to update follow counts

  // Create notification
  Future<void> createNotification({
    required String recipientId,
    required NotificationType type,
    String? postId,
    String? postContent,
    String? commentContent,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUser = this.currentUser;
      if (currentUser == null) {
        throw Exception('Current user not found');
      }

      // Don't create notification for own actions
      if (recipientId == currentUser.id) {
        return;
      }

      final body = <String, dynamic>{
        'recipientId': recipientId,
        'senderId': currentUser.id,
        'senderUsername': currentUser.username,
        'senderProfileImage': currentUser.profileImage,
        'type': type.toString().split('.').last,
        'postId': postId,
        'postContent': postContent,
        'commentContent': commentContent,
        'isRead': false,
      };

      await _pb.collection('notifications').create(body: body);
    } catch (e) {
      print('Failed to create notification: ${e.toString()}');
    }
  }

  // Get notifications for current user
  Future<List<Notification>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final result = await _pb
          .collection('notifications')
          .getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            filter: 'recipientId = "${_pb.authStore.model!.id}"',
          );

      return result.items.map((record) {
        return Notification.fromJson({
          'id': record.id,
          'recipientId': record.data['recipientId'],
          'senderId': record.data['senderId'],
          'senderUsername': record.data['senderUsername'],
          'senderProfileImage': record.data['senderProfileImage'],
          'type': record.data['type'],
          'postId': record.data['postId'],
          'postContent': record.data['postContent'],
          'commentContent': record.data['commentContent'],
          'isRead': record.data['isRead'],
          'createdAt': record.created,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await _pb
          .collection('notifications')
          .update(notificationId, body: {'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final notifications = await _pb
          .collection('notifications')
          .getList(
            filter:
                'recipientId = "${_pb.authStore.model!.id}" && isRead = false',
          );

      for (final notification in notifications.items) {
        await _pb
            .collection('notifications')
            .update(notification.id, body: {'isRead': true});
      }
    } catch (e) {
      throw Exception(
        'Failed to mark all notifications as read: ${e.toString()}',
      );
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      if (!isAuthenticated) return 0;

      final result = await _pb
          .collection('notifications')
          .getList(
            filter:
                'recipientId = "${_pb.authStore.model!.id}" && isRead = false',
          );

      return result.totalItems;
    } catch (e) {
      print('Failed to get unread notifications count: $e');
      return 0;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await _pb.collection('notifications').delete(notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final result = await _pb
          .collection('users')
          .getList(filter: 'name ~ "$query"', sort: '-created');

      print('result: ${result.items}');

      return result.items.map((record) {
        return {
          'id': record.id,
          'username': record.data['name'] ?? '',
          'email': record.data['email'] ?? '',
          'profileImage': _buildAvatarUrl(record),
          'bio': record.data['bio'] ?? '',
          'followersCount': record.data['followersCount'] ?? 0,
          'followingCount': record.data['followingCount'] ?? 0,
          'postsCount': record.data['postsCount'] ?? 0,
          'isVerified': record.data['verified'] ?? false,
          'createdAt': record.created,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  Future<void> _updateFollowCounts(String userId) async {
    try {
      // Get updated counts
      final stats = await getUserStats(userId);

      // Update user record
      await _pb
          .collection('users')
          .update(
            userId,
            body: {
              'followersCount': stats['followersCount'],
              'followingCount': stats['followingCount'],
            },
          );

      // Update current user's following count
      if (_pb.authStore.model != null) {
        final currentUserStats = await getUserStats(_pb.authStore.model!.id);
        await _pb
            .collection('users')
            .update(
              _pb.authStore.model!.id,
              body: {
                'followersCount': currentUserStats['followersCount'],
                'followingCount': currentUserStats['followingCount'],
              },
            );
      }
    } catch (e) {
      print('Error updating follow counts: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // First, verify current password by trying to login
      final currentEmail = _pb.authStore.model?.data?['email'];
      if (currentEmail == null) {
        throw Exception('User email not found');
      }

      // Try to login with current password to verify
      await _pb
          .collection('users')
          .authWithPassword(currentEmail, currentPassword);

      // If login successful, change password
      await _pb
          .collection('users')
          .update(
            _pb.authStore.model!.id,
            body: {'password': newPassword, 'passwordConfirm': newPassword},
          );

      // Re-authenticate with new password
      await _pb.collection('users').authWithPassword(currentEmail, newPassword);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // ========== MESSAGING METHODS ==========

  // Send a message
  Future<Message> sendMessage(String recipientId, String content) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final senderId = _pb.authStore.model!.id;

      final body = <String, dynamic>{
        'sender': senderId,
        'recipient': recipientId,
        'content': content,
        'isRead': false,
      };

      final record = await _pb.collection('messages').create(body: body);

      return Message(
        id: record.id,
        senderId: senderId,
        recipientId: recipientId,
        content: record.data['content'] ?? '',
        isRead: record.data['isRead'] ?? false,
        createdAt: DateTime.parse(record.created),
        sender: currentUser,
      );
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Get conversations (list of users you've messaged with)
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUserId = _pb.authStore.model!.id;

      // Get all messages where current user is sender or recipient
      final result = await _pb
          .collection('messages')
          .getList(
            sort: '-created',
            expand: 'sender,recipient',
            filter: 'sender = "$currentUserId" || recipient = "$currentUserId"',
          );

      // Group messages by conversation partner
      final Map<String, Map<String, dynamic>> conversationsMap = {};

      for (final record in result.items) {
        final senderId = record.data['sender'];
        final recipientId = record.data['recipient'];

        // Determine the other user in the conversation
        final otherUserId = senderId == currentUserId ? recipientId : senderId;

        if (!conversationsMap.containsKey(otherUserId)) {
          // Get the other user's info
          dynamic otherUserExpand;
          if (senderId == currentUserId) {
            otherUserExpand = record.expand?['recipient'];
          } else {
            otherUserExpand = record.expand?['sender'];
          }

          RecordModel? otherUserRecord;
          if (otherUserExpand != null) {
            if (otherUserExpand is List && otherUserExpand.isNotEmpty) {
              otherUserRecord = otherUserExpand.first as RecordModel;
            } else if (otherUserExpand is RecordModel) {
              otherUserRecord = otherUserExpand;
            }
          }

          conversationsMap[otherUserId] = {
            'userId': otherUserId,
            'lastMessage': record.data['content'] ?? '',
            'lastMessageTime': record.created,
            'isRead': record.data['isRead'] ?? false,
            'unreadCount': 0,
            'user': otherUserRecord != null
                ? {
                    'id': otherUserRecord.id,
                    'username':
                        otherUserRecord.data?['username'] ??
                        otherUserRecord.data?['name'] ??
                        '',
                    'email': otherUserRecord.data?['email'] ?? '',
                    'profileImage': _buildAvatarUrl(otherUserRecord),
                    'bio': otherUserRecord.data?['bio'] ?? '',
                    'followersCount':
                        otherUserRecord.data?['followersCount'] ?? 0,
                    'followingCount':
                        otherUserRecord.data?['followingCount'] ?? 0,
                    'postsCount': otherUserRecord.data?['postsCount'] ?? 0,
                    'isVerified': otherUserRecord.data?['verified'] ?? false,
                    'createdAt': otherUserRecord.created,
                  }
                : null,
          };
        }

        // Update last message if this is more recent
        final conversation = conversationsMap[otherUserId]!;
        final lastMessageTime = DateTime.parse(conversation['lastMessageTime']);
        final currentMessageTime = DateTime.parse(record.created);

        if (currentMessageTime.isAfter(lastMessageTime)) {
          conversation['lastMessage'] = record.data['content'] ?? '';
          conversation['lastMessageTime'] = record.created;
          conversation['isRead'] = record.data['isRead'] ?? false;
        }

        // Count unread messages
        if (recipientId == currentUserId &&
            (record.data['isRead'] == false || record.data['isRead'] == null)) {
          conversation['unreadCount'] =
              (conversation['unreadCount'] as int) + 1;
        }
      }

      // Convert to list and sort by last message time
      final conversations = conversationsMap.values.toList();
      conversations.sort((a, b) {
        final timeA = DateTime.parse(a['lastMessageTime']);
        final timeB = DateTime.parse(b['lastMessageTime']);
        return timeB.compareTo(timeA);
      });

      return conversations;
    } catch (e) {
      throw Exception('Failed to get conversations: ${e.toString()}');
    }
  }

  // Get messages between current user and another user
  Future<List<Message>> getMessages(
    String otherUserId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUserId = _pb.authStore.model!.id;

      final result = await _pb
          .collection('messages')
          .getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            expand: 'sender,recipient',
            filter:
                '(sender = "$currentUserId" && recipient = "$otherUserId") || (sender = "$otherUserId" && recipient = "$currentUserId")',
          );

      return result.items.map((record) {
        final senderExpand = record.expand?['sender'];
        final recipientExpand = record.expand?['recipient'];

        RecordModel? senderRecord;
        RecordModel? recipientRecord;

        // Extract sender RecordModel safely
        try {
          if (senderExpand != null) {
            if (senderExpand is List) {
              if (senderExpand.isNotEmpty) {
                final first = senderExpand.first;
                if (first is RecordModel) {
                  senderRecord = first;
                }
              }
            } else {
              senderRecord = senderExpand as RecordModel?;
            }
          }
        } catch (e) {
          senderRecord = null;
        }

        // Extract recipient RecordModel safely
        try {
          if (recipientExpand != null) {
            if (recipientExpand is List) {
              if (recipientExpand.isNotEmpty) {
                final first = recipientExpand.first;
                if (first is RecordModel) {
                  recipientRecord = first;
                }
              }
            } else {
              recipientRecord = recipientExpand as RecordModel?;
            }
          }
        } catch (e) {
          recipientRecord = null;
        }

        User? sender;
        User? recipient;

        if (senderRecord != null) {
          sender = User(
            id: senderRecord.id,
            username:
                senderRecord.data?['username'] ??
                senderRecord.data?['name'] ??
                '',
            email: senderRecord.data?['email'] ?? '',
            profileImage: _buildAvatarUrl(senderRecord),
            bio: senderRecord.data?['bio'] ?? '',
            followersCount: senderRecord.data?['followersCount'] ?? 0,
            followingCount: senderRecord.data?['followingCount'] ?? 0,
            postsCount: senderRecord.data?['postsCount'] ?? 0,
            isVerified: senderRecord.data?['verified'] ?? false,
            createdAt: DateTime.parse(senderRecord.created),
          );
        }

        if (recipientRecord != null) {
          recipient = User(
            id: recipientRecord.id,
            username:
                recipientRecord.data?['username'] ??
                recipientRecord.data?['name'] ??
                '',
            email: recipientRecord.data?['email'] ?? '',
            profileImage: _buildAvatarUrl(recipientRecord),
            bio: recipientRecord.data?['bio'] ?? '',
            followersCount: recipientRecord.data?['followersCount'] ?? 0,
            followingCount: recipientRecord.data?['followingCount'] ?? 0,
            postsCount: recipientRecord.data?['postsCount'] ?? 0,
            isVerified: recipientRecord.data?['verified'] ?? false,
            createdAt: DateTime.parse(recipientRecord.created),
          );
        }

        return Message(
          id: record.id,
          senderId: record.data['sender'],
          recipientId: record.data['recipient'],
          content: record.data['content'] ?? '',
          isRead: record.data['isRead'] ?? false,
          createdAt: DateTime.parse(record.created),
          sender: sender,
          recipient: recipient,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUserId = _pb.authStore.model!.id;

      // Get all unread messages from other user to current user
      final result = await _pb
          .collection('messages')
          .getList(
            filter:
                'sender = "$otherUserId" && recipient = "$currentUserId" && isRead = false',
          );

      // Mark all as read
      for (final record in result.items) {
        await _pb
            .collection('messages')
            .update(record.id, body: {'isRead': true});
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }

  // Get unread messages count
  Future<int> getUnreadMessagesCount() async {
    try {
      if (!isAuthenticated) return 0;

      final currentUserId = _pb.authStore.model!.id;

      final result = await _pb
          .collection('messages')
          .getList(filter: 'recipient = "$currentUserId" && isRead = false');

      return result.totalItems;
    } catch (e) {
      print('Failed to get unread messages count: $e');
      return 0;
    }
  }
}
