import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/pocketbase_service.dart';

class AuthProvider extends ChangeNotifier {
  final PocketBaseService _pocketBaseService = PocketBaseService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser ?? _pocketBaseService.currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated =>
      _pocketBaseService.isAuthenticated || _currentUser != null;

  PocketBaseService get pocketBaseService => _pocketBaseService;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final user = await _pocketBaseService.login(email, password);
      _currentUser = user;

      // Refresh user stats after login
      final stats = await _pocketBaseService.getUserStats(user.id);
      _currentUser = _currentUser!.copyWith(
        postsCount: stats['postsCount'] ?? 0,
        followersCount: stats['followersCount'] ?? 0,
        followingCount: stats['followingCount'] ?? 0,
      );

      print('currentUser: ${_currentUser}');

      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final user = await _pocketBaseService.register(username, email, password);
      _currentUser = user;
      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _pocketBaseService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? bio,
    String? profileImage,
  }) async {
    try {
      final updatedUser = await _pocketBaseService.updateProfile(
        username: username,
        bio: bio,
        profileImage: profileImage,
      );
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }

  // Request email verification
  Future<void> requestEmailVerification(String email) async {
    try {
      await _pocketBaseService.requestEmailVerification(email);
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }

  // Confirm email verification
  Future<void> confirmEmailVerification(String token) async {
    try {
      await _pocketBaseService.confirmEmailVerification(token);
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pocketBaseService.requestPasswordReset(email);
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }

  // Confirm password reset
  Future<void> confirmPasswordReset(
    String token,
    String password,
    String passwordConfirm,
  ) async {
    try {
      await _pocketBaseService.confirmPasswordReset(
        token,
        password,
        passwordConfirm,
      );
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }

  // Refresh user stats
  Future<void> refreshUserStats() async {
    try {
      if (_currentUser == null) return;

      final stats = await _pocketBaseService.getUserStats(_currentUser!.id);
      _currentUser = _currentUser!.copyWith(
        postsCount: stats['postsCount'] ?? 0,
        followersCount: stats['followersCount'] ?? 0,
        followingCount: stats['followingCount'] ?? 0,
      );
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      notifyListeners();
    }
  }
}
