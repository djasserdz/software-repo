import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  User? _user;
  bool _isLoading = false;
  String? _error;
  DateTime? _tokenExpiry;

  AuthProvider(this.authService) {
    _user = authService.getCurrentUser();
    _checkTokenValidity();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_isTokenExpired();
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isWarehouseAdmin => _user?.isWarehouseAdmin ?? false;
  bool get isFarmer => _user?.isFarmer ?? false;

  // Check if token has expired (approximately 24 hours)
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  void _checkTokenValidity() {
    if (_user != null && authService.getToken() != null) {
      // Set token expiry (default 24 hours from now)
      _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.login(email, password);
      _isLoading = false;

      if (result['success'] == true) {
        _user = result['user'] as User;
        _checkTokenValidity();
        print('✅ [AuthProvider] Login successful: ${_user?.name}');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Login failed';
        print('❌ [AuthProvider] Login failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Connection error: ${e.toString()}';
      print('❌ [AuthProvider] Login exception: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _isLoading = false;

      if (result['success'] == true) {
        _user = result['user'] as User;
        _checkTokenValidity();
        print('✅ [AuthProvider] Registration successful: ${_user?.email}');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Registration failed';
        print('❌ [AuthProvider] Registration failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Connection error: ${e.toString()}';
      print('❌ [AuthProvider] Register exception: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _user = null;
    _error = null;
    _tokenExpiry = null;
    print('🔵 [AuthProvider] Logged out');
    notifyListeners();
  }

  void handleUnauthorized() {
    print('🔴 [AuthProvider] Handling unauthorized access (401)');
    _user = null;
    _error = 'Session expired. Please login again.';
    _tokenExpiry = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

