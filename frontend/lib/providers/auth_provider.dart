import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  Future<String?> getToken() => _authService.getToken();

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Get cached user data first
        _user = await _authService.getCachedUser();
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Then refresh from API
        try {
          _user = await _authService.getCurrentUser();
          notifyListeners();
        } catch (e) {
          print('Failed to refresh user data: $e');
          // Force logout if token is invalid
          _user = null;
          _status = AuthStatus.unauthenticated;
          await _authService.logout();  // Clear all tokens
          notifyListeners();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('Initialize error: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register({
    required int employeeId,
    required String nik,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authService.register(
        employeeId: employeeId,
        nik: nik,
        username: username,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response['success']) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['message'];
        _setLoading(false);
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (e.errors != null) {
        // Format validation errors
        final errors = e.errors!.values.expand((e) => e).join('\n');
        _errorMessage = errors;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _authService.login(
        username: username,
        password: password,
      );

      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      _setLoading(false);
    }
  }

  // Set user manually (useful after login outside provider)
  void setUser(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;

    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Refresh user error: $e');
    }
  }

  // Get available employees for registration
  Future<List<Map<String, dynamic>>> getAvailableEmployees() async {
    try {
      return await _authService.getAvailableEmployees();
    } catch (e) {
      print('Get employees error: $e');
      rethrow;
    }
  }

  // Check API health
  Future<bool> checkApiHealth() async {
    return await _authService.checkHealth();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
