import 'dart:convert';
import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' show MultipartFile;
import '../models/user.dart';

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
      profileImage: null, // Will implement file handling later
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
        profileImage: null,
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
        profileImage: null,
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
      if (username != null) body['username'] = username;
      if (bio != null) body['bio'] = bio;

      final record = await _pb
          .collection('users')
          .update(_pb.authStore.model!.id, body: body);

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
        profileImage: null,
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
      final result = await _pb
          .collection('posts')
          .getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            expand: 'author',
          );

      final posts = await Future.wait(
        result.items.map((record) async {
          // Handle author data from expanded relation
          dynamic authorExpand = record.expand?['author'];
          RecordModel? authorRecord;

          print('Author expand type: ${authorExpand.runtimeType}');
          print('Author expand: $authorExpand');

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
            print('Error extracting author data: $e');
            authorRecord = null;
          }

          final commentsCount = await _pb
              .collection('comments')
              .getList(filter: 'post = "${record.id}"')
              .then((result) => result.totalItems);

          print('Author record: ${authorRecord?.id}');

          return {
            'id': record.id,
            'content': record.data['content'] ?? '',
            'images': _parseImages(record.data['images'], record.id),
            'likesCount': record.data['likesCount'] ?? 0,
            'commentsCount': commentsCount,
            'sharesCount': record.data['sharesCount'] ?? 0,
            'createdAt': record.created,
            'author': authorRecord != null
                ? {
                    'id': authorRecord.id,
                    'username':
                        authorRecord.data?['username'] ??
                        authorRecord.data?['name'] ??
                        '',
                    'email': authorRecord.data?['email'] ?? '',
                    'profileImage': null,
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
        'author': currentUser?.toJson(),
      };
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  // Like/Unlike post
  Future<void> toggleLike(String postId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // This is a simplified implementation
      // In a real app, you'd have a separate likes collection
      // For now, we'll just update the likes count
      final record = await _pb.collection('posts').getOne(postId);
      final currentLikes = record.data['likesCount'] ?? 0;

      await _pb
          .collection('posts')
          .update(postId, body: {'likesCount': currentLikes + 1});
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
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
                  'profileImage': null,
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
          'profileImage': null,
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
}
