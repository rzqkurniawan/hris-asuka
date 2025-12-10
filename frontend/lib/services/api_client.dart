import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests (SKIP for public endpoints to avoid storage hangs)
        final isPublicEndpoint = options.path.contains('/auth/employees') || 
                               options.path.contains('/auth/login') || 
                               options.path.contains('/auth/register');

        if (!isPublicEndpoint) {
          final token = await _storage.read(key: ApiConfig.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        print('ERROR MESSAGE: ${error.message}');

        // Handle 401 Unauthorized - Try to refresh token
        // BUT: Skip refresh if the failing request is refresh itself (prevent infinite loop)
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/refresh')) {
          try {
            // Attempt to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final options = error.requestOptions;
              final token = await _storage.read(key: ApiConfig.tokenKey);
              options.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            }
          } catch (e) {
            print('Token refresh failed: $e');
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // Refresh token
  Future<bool> _refreshToken() async {
    try {
      final response = await _dio.post(ApiConfig.refreshToken);
      if (response.statusCode == 200 && response.data['success']) {
        final newToken = response.data['data']['token']['access_token'];
        await _storage.write(key: ApiConfig.tokenKey, value: newToken);
        return true;
      }
    } catch (e) {
      print('Refresh token error: $e');
    }
    return false;
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  ApiException _handleError(DioException error) {
    String message = 'An error occurred';

    // Enhanced logging for debugging
    print('=== API ERROR DEBUG ===');
    print('Error Type: ${error.type}');
    print('Error Message: ${error.message}');
    print('Request Path: ${error.requestOptions.path}');
    print('Request Method: ${error.requestOptions.method}');
    print('Request Base URL: ${error.requestOptions.baseUrl}');

    if (error.error != null) {
      print('Underlying Error: ${error.error}');
      print('Underlying Error Type: ${error.error.runtimeType}');
    }

    if (error.response != null) {
      print('Response Status Code: ${error.response?.statusCode}');
      print('Response Data: ${error.response?.data}');
    }
    print('======================');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout (${ApiConfig.connectionTimeout.inSeconds}s). Please check your internet connection.';
        print('TIMEOUT: Connection timeout after ${ApiConfig.connectionTimeout.inSeconds}s');
        break;

      case DioExceptionType.sendTimeout:
        message = 'Send timeout (${ApiConfig.connectionTimeout.inSeconds}s). Please try again.';
        print('TIMEOUT: Send timeout after ${ApiConfig.connectionTimeout.inSeconds}s');
        break;

      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout (${ApiConfig.receiveTimeout.inSeconds}s). Server is taking too long to respond.';
        print('TIMEOUT: Receive timeout after ${ApiConfig.receiveTimeout.inSeconds}s');
        break;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data != null && data is Map) {
          message = data['message'] ?? message;
        }

        if (statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          message = 'Access forbidden.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode == 422) {
          message = 'Validation failed.';
        } else if (statusCode! >= 500) {
          message = 'Server error. Please try again later.';
        }
        break;

      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          message = 'No internet connection. Please check your network.';
          print('SOCKET ERROR: ${(error.error as SocketException).message}');
        } else {
          message = 'Connection failed: ${error.error?.toString() ?? "Unknown error"}';
        }
        break;

      default:
        message = 'An unexpected error occurred.';
    }

    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      errors: error.response?.data?['errors'],
    );
  }
}

// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}
