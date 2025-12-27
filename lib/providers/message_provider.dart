import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/pocketbase_service.dart';
import '../utils/blacklist.dart';

class MessageProvider extends ChangeNotifier {
  final PocketBaseService _pocketBaseService = PocketBaseService();

  List<Map<String, dynamic>> _conversations = [];
  Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Fetch conversations
  Future<void> fetchConversations() async {
    setLoading(true);
    setError(null);

    try {
      _conversations = await _pocketBaseService.getConversations();
      await updateUnreadCount();
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch conversations: ${e.toString()}');
      setLoading(false);
      notifyListeners();
    }
  }

  // Get messages with a specific user
  List<Message> getMessages(String userId) {
    return _messages[userId] ?? [];
  }

  // Fetch messages with a specific user
  Future<void> fetchMessages(String userId) async {
    setLoading(true);
    setError(null);

    try {
      final messagesList = await _pocketBaseService.getMessages(userId);
      _messages[userId] = messagesList;

      // Mark messages as read when fetching
      await _pocketBaseService.markMessagesAsRead(userId);
      await updateUnreadCount();

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch messages: ${e.toString()}');
      setLoading(false);
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(String recipientId, String content) async {
    setError(null);

    try {
      // Kiểm tra blacklist trước khi gửi message
      final bannedWords = Blacklist.checkContent(content);
      if (bannedWords != null) {
        setError(Blacklist.getErrorMessage(bannedWords));
        notifyListeners();
        return;
      }

      final message = await _pocketBaseService.sendMessage(
        recipientId,
        content,
      );

      // Add message to local state
      if (_messages[recipientId] == null) {
        _messages[recipientId] = [];
      }
      _messages[recipientId]!.insert(0, message);

      // Update conversation
      await fetchConversations();

      notifyListeners();
    } catch (e) {
      setError('Failed to send message: ${e.toString()}');
      notifyListeners();
    }
  }

  // Update unread count
  Future<void> updateUnreadCount() async {
    try {
      _unreadCount = await _pocketBaseService.getUnreadMessagesCount();
      notifyListeners();
    } catch (e) {
      print('Failed to update unread count: $e');
    }
  }

  // Initialize (fetch conversations and unread count)
  Future<void> initialize() async {
    await fetchConversations();
  }
}
