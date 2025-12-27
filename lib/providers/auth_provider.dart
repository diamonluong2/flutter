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

  // Helper method to parse error messages and return user-friendly messages
  String _parseErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    String errorString = error.toString();

    // Handle PocketBase specific errors
    if (errorString.contains('Failed to authenticate')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
    }

    if (errorString.contains('Invalid credentials')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
    }

    if (errorString.contains('User not found')) {
      return 'Tài khoản không tồn tại. Vui lòng kiểm tra email của bạn.';
    }

    if (errorString.contains('Email not confirmed')) {
      return 'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư của bạn.';
    }

    if (errorString.contains('Too many requests')) {
      return 'Quá nhiều yêu cầu. Vui lòng thử lại sau vài phút.';
    }

    if (errorString.contains('Network error') ||
        errorString.contains('Connection failed')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet của bạn.';
    }

    if (errorString.contains('Server error') ||
        errorString.contains('Internal server error')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    }

    if (errorString.contains('Validation failed')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin nhập vào.';
    }

    // Handle general exceptions
    if (errorString.contains('Login failed')) {
      return 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
    }

    if (errorString.contains('Registration failed')) {
      return 'Đăng ký thất bại. Vui lòng thử lại.';
    }

    // Default case - return a generic message
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

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
      setError(_parseErrorMessage(e));
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
      setError(_parseErrorMessage(e));
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
      setError(_parseErrorMessage(e));
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _pocketBaseService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      notifyListeners();
    } catch (e) {
      setError(_parseErrorMessage(e));
      notifyListeners();
      throw e; // Re-throw to handle in UI
    }
  }

  // Request email verification
  Future<void> requestEmailVerification(String email) async {
    try {
      await _pocketBaseService.requestEmailVerification(email);
    } catch (e) {
      setError(_parseErrorMessage(e));
      notifyListeners();
    }
  }

  // Confirm email verification
  Future<void> confirmEmailVerification(String token) async {
    try {
      await _pocketBaseService.confirmEmailVerification(token);
    } catch (e) {
      setError(_parseErrorMessage(e));
      notifyListeners();
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pocketBaseService.requestPasswordReset(email);
    } catch (e) {
      setError(_parseErrorMessage(e));
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
      setError(_parseErrorMessage(e));
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
      setError(_parseErrorMessage(e));
      notifyListeners();
    }
  }
}
