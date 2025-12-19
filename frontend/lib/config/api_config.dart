class ApiConfig {
  // Base URL - Laravel API server (HTTPS)
  static const String baseUrl = 'https://hris.asukaindonesia.co.id/api';

  // API Endpoints
  static const String healthCheck = '/health';

  // Auth Endpoints
  static const String employees = '/auth/employees';
  static const String registerGetAvatar = '/auth/register/get-avatar';
  static const String registerCompareFace = '/auth/register/compare-face';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';
  static const String forgotPasswordVerify = '/auth/forgot-password/verify-identity';
  static const String forgotPasswordCompareFace = '/auth/forgot-password/compare-face';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';

  // Profile Endpoints (future implementation)
  static const String profile = '/profile';

  // Overtime Endpoints (future implementation)
  static const String overtime = '/overtime';

  // Leave Endpoints (future implementation)
  static const String leave = '/leave';

  // Attendance Endpoints (history from c3ais)
  static const String attendance = '/attendance';

  // Mobile Attendance Endpoints (check-in/check-out with GPS & Face Recognition)
  static const String mobileAttendance = '/mobile-attendance';

  // Payslip Endpoints (future implementation)
  static const String payslip = '/payslip';

  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';

  // Get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
