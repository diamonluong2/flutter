import 'package:flutter/foundation.dart';
import '../services/pocketbase_service.dart';

class LikeProvider extends ChangeNotifier {
  final PocketBaseService _pocketBaseService = PocketBaseService();

  // Map to store like status for posts: postId -> hasLiked
  final Map<String, bool> _likeStatus = {};

  // Map to store likes count for posts: postId -> count
  final Map<String, int> _likesCount = {};

  // Get like status for a post
  bool hasLikedPost(String postId) {
    return _likeStatus[postId] ?? false;
  }

  // Get likes count for a post
  int getLikesCount(String postId) {
    return _likesCount[postId] ?? 0;
  }

  // Set like status for a post
  void setLikeStatus(String postId, bool hasLiked) {
    _likeStatus[postId] = hasLiked;
    notifyListeners();
  }

  // Set likes count for a post
  void setLikesCount(String postId, int count) {
    _likesCount[postId] = count;
    notifyListeners();
  }

  // Toggle like for a post
  Future<void> toggleLike(String postId) async {
    try {
      // Optimistically update UI
      final currentStatus = hasLikedPost(postId);
      print('currentStatus: $currentStatus');
      final currentCount = getLikesCount(postId);
      print('currentCount: $currentCount');
      setLikeStatus(postId, !currentStatus);
      setLikesCount(
        postId,
        currentStatus ? currentCount - 1 : currentCount + 1,
      );

      // Call API
      await _pocketBaseService.toggleLike(postId);

      // Refresh actual data
      await refreshPostLikeData(postId);
    } catch (e) {
      // Revert optimistic update on error
      final currentStatus = hasLikedPost(postId);
      final currentCount = getLikesCount(postId);

      setLikeStatus(postId, !currentStatus);
      setLikesCount(
        postId,
        currentStatus ? currentCount + 1 : currentCount - 1,
      );

      rethrow;
    }
  }

  // Refresh like data for a post
  Future<void> refreshPostLikeData(String postId) async {
    try {
      final hasLiked = await _pocketBaseService.hasLikedPost(postId);
      final likesCount = await _pocketBaseService.getPostLikesCount(postId);

      setLikeStatus(postId, hasLiked);
      setLikesCount(postId, likesCount);
    } catch (e) {
      print('Error refreshing post like data: $e');
    }
  }

  // Initialize like data for multiple posts
  Future<void> initializeLikeData(List<String> postIds) async {
    try {
      for (final postId in postIds) {
        await refreshPostLikeData(postId);
      }
    } catch (e) {
      print('Error initializing like data: $e');
    }
  }

  // Clear all like data (useful for logout)
  void clearLikeData() {
    _likeStatus.clear();
    _likesCount.clear();
    notifyListeners();
  }
}
