import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/pocketbase_service.dart';
import '../utils/blacklist.dart';
import 'like_provider.dart';

class PostProvider extends ChangeNotifier {
  final PocketBaseService _pocketBaseService = PocketBaseService();
  List<Post> _posts = [];
  Map<String, List<Comment>> _comments = {};
  bool _isLoading = false;
  String? _error;
  LikeProvider? _likeProvider;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _pocketBaseService.currentUser;
  PocketBaseService get pocketBaseService => _pocketBaseService;

  // Set like provider reference
  void setLikeProvider(LikeProvider likeProvider) {
    _likeProvider = likeProvider;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> fetchPosts() async {
    setLoading(true);
    setError(null);

    try {
      final postsData = await _pocketBaseService.getPosts();

      // Filter posts to only include approved ones (client-side filter as backup)
      // This ensures that even if server-side filter fails, we only show approved posts
      _posts = postsData
          .where((postData) {
            final isApproved = postData['isApproved'];

            // Handle different types: bool, string, null
            bool approved;
            if (isApproved == null) {
              // If null, default to false (don't show unapproved posts)
              approved = false;
            } else if (isApproved is bool) {
              approved = isApproved;
            } else if (isApproved is String) {
              approved = isApproved.toLowerCase() == 'true';
            } else {
              // For any other type, try to convert to bool
              approved = isApproved.toString().toLowerCase() == 'true';
            }

            // Only return posts that are approved (explicitly true)
            return approved == true;
          })
          .map((postData) {
            final authorData = postData['author'] as Map<String, dynamic>?;
            final author = authorData != null
                ? User.fromJson(authorData)
                : User(
                    id: 'unknown',
                    username: 'Unknown User',
                    email: 'unknown@example.com',
                    createdAt: DateTime.now(),
                  );

            return Post(
              id: postData['id'],
              author: author,
              content: postData['content'],
              images: List<String>.from(postData['images'] ?? []),
              likesCount: postData['likesCount'] ?? 0,
              commentsCount: postData['commentsCount'] ?? 0,
              sharesCount: postData['sharesCount'] ?? 0,
              createdAt: DateTime.parse(postData['createdAt']),
              isApproved: postData['isApproved'] ?? true,
            );
          })
          .toList();

      // Initialize like data for all posts
      if (_likeProvider != null) {
        final postIds = _posts.map((post) => post.id).toList();
        await _likeProvider!.initializeLikeData(postIds);
      }

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch posts: ${e.toString()}');
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> createPost(String content, List<String> images) async {
    setLoading(true);
    setError(null);

    try {
      // Kiểm tra blacklist trước khi tạo post
      final bannedWords = Blacklist.checkContent(content);
      if (bannedWords != null) {
        setLoading(false);
        setError(Blacklist.getErrorMessage(bannedWords));
        notifyListeners();
        return;
      }

      // Create post with images
      final postData = await _pocketBaseService.createPost(content, images);

      final authorData = postData['author'] as Map<String, dynamic>?;
      final author = authorData != null
          ? User.fromJson(authorData)
          : User(
              id: 'unknown',
              username: 'Unknown User',
              email: 'unknown@example.com',
              createdAt: DateTime.now(),
            );

      final newPost = Post(
        id: postData['id'],
        author: author,
        content: postData['content'],
        images: List<String>.from(postData['images'] ?? []),
        likesCount: postData['likesCount'] ?? 0,
        commentsCount: postData['commentsCount'] ?? 0,
        sharesCount: postData['sharesCount'] ?? 0,
        createdAt: DateTime.parse(postData['createdAt']),
        isApproved: postData['isApproved'] ?? true,
      );

      _posts.insert(0, newPost);

      // Refresh user stats after creating post
      if (currentUser != null) {
        final stats = await _pocketBaseService.getUserStats(currentUser!.id);
        _pocketBaseService.updateProfile(
          username: currentUser!.username,
          bio: currentUser!.bio,
          profileImage: currentUser!.profileImage,
        );
      }

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Failed to create post: ${e.toString()}');
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      await _pocketBaseService.toggleLike(postId);

      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final isLiked = post.isLiked;

        _posts[postIndex] = post.copyWith(
          isLiked: !isLiked,
          likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );

        notifyListeners();
      }
    } catch (e) {
      setError('Failed to toggle like: ${e.toString()}');
      notifyListeners();
    }
  }

  List<Comment> getComments(String postId) {
    return _comments[postId] ?? [];
  }

  Future<void> fetchComments(String postId) async {
    try {
      final commentsData = await _pocketBaseService.getComments(postId);
      _comments[postId] = commentsData.map((commentData) {
        final authorData = commentData['author'] as Map<String, dynamic>;
        final author = User.fromJson(authorData);

        return Comment(
          id: commentData['id'],
          content: commentData['content'],
          author: author,
          postId: commentData['post'],
          createdAt: DateTime.parse(commentData['createdAt']),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch comments: ${e.toString()}');
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      // Kiểm tra blacklist trước khi tạo comment
      final bannedWords = Blacklist.checkContent(content);
      if (bannedWords != null) {
        setError(Blacklist.getErrorMessage(bannedWords));
        notifyListeners();
        return;
      }

      await _pocketBaseService.addComment(postId, content);

      // Fetch updated comments
      await fetchComments(postId);

      // Update post comment count
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          commentsCount: _comments[postId]?.length ?? 0,
        );
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to add comment: ${e.toString()}');
      notifyListeners();
    }
  }

  void sharePost(String postId) {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      _posts[postIndex] = post.copyWith(sharesCount: post.sharesCount + 1);
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _pocketBaseService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      _comments.remove(postId);
      notifyListeners();
    } catch (e) {
      setError('Failed to delete post: ${e.toString()}');
      notifyListeners();
      rethrow;
    }
  }
}
