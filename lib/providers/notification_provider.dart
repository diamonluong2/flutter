import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/pocketbase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final PocketBaseService _pocketBaseService = PocketBaseService();

  List<Notification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _error;

  // Getters
  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  // Initialize notifications
  Future<void> initialize() async {
    await refreshNotifications();
    await updateUnreadCount();
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    try {
      _setLoading(true);
      _setError(null);

      final notifications = await _pocketBaseService.getNotifications();
      _notifications = notifications;

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    try {
      if (_isLoading) return;

      _setLoading(true);
      _setError(null);

      final currentPage = (_notifications.length / 20).ceil() + 1;
      final moreNotifications = await _pocketBaseService.getNotifications(
        page: currentPage,
        perPage: 20,
      );

      if (moreNotifications.isNotEmpty) {
        _notifications.addAll(moreNotifications);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _pocketBaseService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _pocketBaseService.markAllNotificationsAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _pocketBaseService.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      await updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Update unread count
  Future<void> updateUnreadCount() async {
    try {
      _unreadCount = await _pocketBaseService.getUnreadNotificationsCount();
      notifyListeners();
    } catch (e) {
      print('Failed to update unread count: $e');
    }
  }

  // Add notification to list (for real-time updates)
  void addNotification(Notification notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }

  // Clear all data
  void clear() {
    _notifications.clear();
    _isLoading = false;
    _unreadCount = 0;
    _error = null;
    notifyListeners();
  }
}
