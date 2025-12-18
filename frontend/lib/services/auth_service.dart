import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_client.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/debug_logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService._internal();

  // Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    String deviceType = 'android';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        deviceName = '${iosInfo.name} ${iosInfo.model}';
        deviceType = 'ios';
      }
    } catch (e) {
      DebugLogger.error('Error getting device info', error: e, tag: 'AuthService');
    }

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
    };
  }

  // Get available employees for registration
  Future<List<Map<String, dynamic>>> getAvailableEmployees({String? query}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.employees,
        queryParameters: query != null ? {'search': query} : null,
      );

      DebugLogger.log('Employees API response received', tag: 'AuthService');

      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected Map, got ${response.data.runtimeType}',
        );
      }

      final responseMap = response.data as Map<String, dynamic>;

      // Check success
      if (responseMap['success'] != true) {
        throw ApiException(
          message: responseMap['message'] ?? 'Failed to get employees',
        );
      }

      // Get data field
      final data = responseMap['data'];

      if (data is! Map) {
        throw ApiException(
          message: 'Invalid data format: expected Map, got ${data.runtimeType}',
        );
      }

      // Get employees array from data
      final dataMap = data as Map<String, dynamic>;
      final employeesData = dataMap['employees'];

      if (employeesData is! List) {
        throw ApiException(
          message: 'Invalid employees format: expected List, got ${employeesData.runtimeType}',
        );
      }

      // Parse employees list
      final employees = (employeesData as List).map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return e as Map<String, dynamic>;
      }).toList();

      DebugLogger.log('Parsed ${employees.length} employees', tag: 'AuthService');
      return employees;
    } catch (e) {
      DebugLogger.error('Error in getAvailableEmployees', error: e, tag: 'AuthService');
      rethrow;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required int employeeId,
    required String nik,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await _apiClient.post(
        ApiConfig.register,
        data: {
          'employee_id': employeeId,
          'nik': nik,
          'username': username,
          'password': password,
          'password_confirmation': passwordConfirmation,
          ...deviceInfo,
        },
      );

      if (response.data['success']) {
        return response.data;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Login user
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await _apiClient.post(
        ApiConfig.login,
        data: {
          'username': username,
          'password': password,
          ...deviceInfo,
        },
      );

      if (response.data['success']) {
        final data = response.data['data'];

        DebugLogger.log('Login successful', tag: 'AuthService');

        // Save token
        final token = data['token']['access_token'];
        await _storage.write(key: ApiConfig.tokenKey, value: token);

        // Save user data
        final userData = jsonEncode(data['user']);
        await _storage.write(key: ApiConfig.userDataKey, value: userData);

        // Save device ID
        await _storage.write(
          key: ApiConfig.deviceIdKey,
          value: deviceInfo['device_id'],
        );

        final user = UserModel.fromJson(data['user']);

        return user;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get current user info
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConfig.me);

      if (response.data['success']) {
        final userData = response.data['data']['user'];

        // Update stored user data
        await _storage.write(
          key: ApiConfig.userDataKey,
          value: jsonEncode(userData),
        );

        return UserModel.fromJson(userData);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get user data',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get cached user data
  Future<UserModel?> getCachedUser() async {
    try {
      final userDataString = await _storage.read(key: ApiConfig.userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      DebugLogger.error('Error getting cached user', error: e, tag: 'AuthService');
    }
    return null;
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.logout);
    } catch (e) {
      DebugLogger.error('Logout API error', error: e, tag: 'AuthService');
    } finally {
      // Clear stored data
      await _storage.delete(key: ApiConfig.tokenKey);
      await _storage.delete(key: ApiConfig.userDataKey);
      await _storage.delete(key: ApiConfig.deviceIdKey);
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: ApiConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: ApiConfig.tokenKey);
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await _apiClient.post(ApiConfig.refreshToken);

      if (response.data['success']) {
        final newToken = response.data['data']['token']['access_token'];
        await _storage.write(key: ApiConfig.tokenKey, value: newToken);
        return true;
      }
    } catch (e) {
      DebugLogger.error('Refresh token error', error: e, tag: 'AuthService');
    }
    return false;
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': passwordConfirmation,
        },
      );

      if (!response.data['success']) {
        throw ApiException(
          message: response.data['message'] ?? 'Gagal mengubah password',
        );
      }
    } catch (e) {
      DebugLogger.error('Change password error', error: e, tag: 'AuthService');
      rethrow;
    }
  }

  // Check health
  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.get(ApiConfig.healthCheck);
      return response.data['success'] == true;
    } catch (e) {
      DebugLogger.error('Health check error', error: e, tag: 'AuthService');
      return false;
    }
  }

  // Verify identity for forgot password (Step 1)
  Future<Map<String, dynamic>> verifyIdentityForReset({
    required String username,
    required String nik,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.forgotPasswordVerify,
        data: {
          'username': username,
          'nik': nik,
        },
      );

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Gagal memverifikasi identitas',
        );
      }
    } catch (e) {
      DebugLogger.error('Verify identity error', error: e, tag: 'AuthService');
      rethrow;
    }
  }

  // Reset password with face verification (Step 2)
  Future<void> resetPasswordWithFace({
    required String resetToken,
    required String faceImage,
    required double faceConfidence,
    required bool livenessVerified,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.forgotPasswordReset,
        data: {
          'reset_token': resetToken,
          'face_image': faceImage,
          'face_confidence': faceConfidence,
          'liveness_verified': livenessVerified,
          'new_password': newPassword,
          'new_password_confirmation': passwordConfirmation,
        },
      );

      if (!response.data['success']) {
        throw ApiException(
          message: response.data['message'] ?? 'Gagal mereset password',
        );
      }
    } catch (e) {
      DebugLogger.error('Reset password error', error: e, tag: 'AuthService');
      rethrow;
    }
  }
}
