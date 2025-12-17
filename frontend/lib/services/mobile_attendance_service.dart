import 'dart:convert';
import 'dart:typed_data';
import '../config/api_config.dart';
import 'api_client.dart';
import 'device_security_service.dart';

class MobileAttendanceService {
  final ApiClient _apiClient = ApiClient();

  /// Get all active attendance locations
  Future<List<AttendanceLocation>> getLocations() async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.mobileAttendance}/locations');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) =>
                AttendanceLocation.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load locations');
      }
    } catch (e) {
      throw Exception('Failed to load locations: ${e.toString()}');
    }
  }

  /// Get today's attendance status
  Future<TodayAttendanceStatus> getTodayStatus() async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.mobileAttendance}/today-status');

      if (response.data['success'] == true) {
        return TodayAttendanceStatus.fromJson(
            response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load today status');
      }
    } catch (e) {
      throw Exception('Failed to load today status: ${e.toString()}');
    }
  }

  /// Validate if current location is within allowed radius
  Future<LocationValidationResult> validateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.mobileAttendance}/validate-location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return LocationValidationResult.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to validate location: ${e.toString()}');
    }
  }

  /// Get employee avatar URL for face comparison
  Future<EmployeeAvatarResponse> getEmployeeAvatar() async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.mobileAttendance}/employee-avatar');

      if (response.data['success'] == true) {
        return EmployeeAvatarResponse.fromJson(
            response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load employee avatar');
      }
    } catch (e) {
      throw Exception('Failed to load employee avatar: ${e.toString()}');
    }
  }

  /// Submit attendance (check-in or check-out)
  Future<AttendanceSubmitResult> submitAttendance({
    required String checkType, // 'check_in' or 'check_out'
    required double latitude,
    required double longitude,
    required String faceImageBase64,
    required double faceConfidence,
    required bool livenessVerified, // Anti-spoofing liveness check
    String? deviceInfo,
    ExtendedLocationData? securityData, // Anti-fake GPS data
  }) async {
    try {
      // Build request data
      final Map<String, dynamic> data = {
        'check_type': checkType,
        'latitude': latitude,
        'longitude': longitude,
        'face_image': faceImageBase64,
        'face_confidence': faceConfidence,
        'liveness_verified': livenessVerified, // Required for anti-spoofing
        'device_info': deviceInfo,
      };

      // Add security data if available
      if (securityData != null) {
        data.addAll(securityData.toApiMap());
      }

      final response = await _apiClient.post(
        '${ApiConfig.mobileAttendance}/submit',
        data: data,
      );

      // Safely parse response data
      if (response.data == null) {
        return AttendanceSubmitResult(
          success: false,
          message: 'Empty response from server',
        );
      }

      // Handle response data - could be Map or other type
      if (response.data is Map) {
        return AttendanceSubmitResult.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      } else {
        return AttendanceSubmitResult(
          success: false,
          message: 'Invalid response format: ${response.data.runtimeType}',
        );
      }
    } on ApiException catch (e) {
      return AttendanceSubmitResult(
        success: false,
        message: e.message,
      );
    } catch (e) {
      // Log error for debugging
      print('Submit attendance error: $e');
      print('Error type: ${e.runtimeType}');
      return AttendanceSubmitResult(
        success: false,
        message: 'Gagal menyimpan absensi: ${e.toString()}',
      );
    }
  }

  /// Get attendance history
  Future<AttendanceHistoryResponse> getHistory({
    String? startDate,
    String? endDate,
    int? month,
    int? year,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      } else if (month != null && year != null) {
        queryParams['month'] = month;
        queryParams['year'] = year;
      }

      final response = await _apiClient.get(
        '${ApiConfig.mobileAttendance}/history',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return AttendanceHistoryResponse.fromJson(
            response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load attendance history');
      }
    } catch (e) {
      throw Exception('Failed to load attendance history: ${e.toString()}');
    }
  }
}

// ============== Models ==============

/// Attendance Location Model
class AttendanceLocation {
  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  AttendanceLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) {
    return AttendanceLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radiusMeters: json['radius_meters'] as int,
    );
  }
}

/// Today's Attendance Status Model
class TodayAttendanceStatus {
  final String date;
  final bool canCheckIn;
  final bool canCheckOut;
  final AttendanceCheckData? checkIn;
  final AttendanceCheckData? checkOut;

  TodayAttendanceStatus({
    required this.date,
    required this.canCheckIn,
    required this.canCheckOut,
    this.checkIn,
    this.checkOut,
  });

  factory TodayAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceStatus(
      date: json['date'] as String,
      canCheckIn: json['can_check_in'] as bool,
      canCheckOut: json['can_check_out'] as bool,
      checkIn: json['check_in'] != null
          ? AttendanceCheckData.fromJson(
              json['check_in'] as Map<String, dynamic>)
          : null,
      checkOut: json['check_out'] != null
          ? AttendanceCheckData.fromJson(
              json['check_out'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Attendance Check Data (for check_in/check_out details)
class AttendanceCheckData {
  final String time; // Formatted local time string (HH:mm:ss)
  final DateTime? dateTime; // Original DateTime for further processing
  final String location;
  final bool locationVerified;
  final bool faceVerified;

  AttendanceCheckData({
    required this.time,
    this.dateTime,
    required this.location,
    required this.locationVerified,
    required this.faceVerified,
  });

  factory AttendanceCheckData.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String;
    DateTime? parsedDateTime;
    String formattedTime = timeStr;

    // Try to parse ISO8601 format and convert to device local time
    try {
      parsedDateTime = DateTime.parse(timeStr);
      // Convert to local timezone
      final localTime = parsedDateTime.toLocal();
      // Format as HH:mm:ss
      formattedTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      // If parsing fails, use original string (might already be HH:mm:ss format)
      formattedTime = timeStr;
    }

    return AttendanceCheckData(
      time: formattedTime,
      dateTime: parsedDateTime?.toLocal(),
      location: json['location'] as String,
      locationVerified: json['location_verified'] as bool,
      faceVerified: json['face_verified'] as bool,
    );
  }
}

/// Location Validation Result
class LocationValidationResult {
  final bool success;
  final String message;
  final bool isValid;
  final int? locationId;
  final String? locationName;
  final double? distanceMeters;
  final int? radiusMeters;
  final String? nearestLocation;
  final double? distanceToNearest;
  final int? requiredRadius;

  LocationValidationResult({
    required this.success,
    required this.message,
    required this.isValid,
    this.locationId,
    this.locationName,
    this.distanceMeters,
    this.radiusMeters,
    this.nearestLocation,
    this.distanceToNearest,
    this.requiredRadius,
  });

  factory LocationValidationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final isValid = data?['is_valid'] as bool? ?? false;

    return LocationValidationResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      isValid: isValid,
      locationId: data?['location_id'] as int?,
      locationName: data?['location_name'] as String?,
      distanceMeters: data?['distance_meters'] != null
          ? double.parse(data!['distance_meters'].toString())
          : null,
      radiusMeters: data?['radius_meters'] as int?,
      nearestLocation: data?['nearest_location'] as String?,
      distanceToNearest: data?['distance_to_nearest'] != null
          ? double.parse(data!['distance_to_nearest'].toString())
          : null,
      requiredRadius: data?['required_radius'] as int?,
    );
  }
}

/// Employee Avatar Response
class EmployeeAvatarResponse {
  final String avatarUrl;
  final String avatarPath;

  EmployeeAvatarResponse({
    required this.avatarUrl,
    required this.avatarPath,
  });

  factory EmployeeAvatarResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeAvatarResponse(
      avatarUrl: json['avatar_url'] as String,
      avatarPath: json['avatar_path'] as String,
    );
  }
}

/// Attendance Submit Result
class AttendanceSubmitResult {
  final bool success;
  final String message;
  final int? id;
  final String? checkType;
  final String? time;
  final String? location;
  final bool? locationVerified;
  final bool? faceVerified;
  final double? faceConfidence;

  AttendanceSubmitResult({
    required this.success,
    required this.message,
    this.id,
    this.checkType,
    this.time,
    this.location,
    this.locationVerified,
    this.faceVerified,
    this.faceConfidence,
  });

  factory AttendanceSubmitResult.fromJson(Map<String, dynamic> json) {
    // Defensive parsing - handle various response formats
    final bool success = json['success'] == true;
    final String message = json['message']?.toString() ?? 'Unknown response';

    // Parse data field safely
    Map<String, dynamic>? data;
    if (json['data'] != null && json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    }

    // Parse id safely - handle both int and String
    int? id;
    if (data?['id'] != null) {
      final idValue = data!['id'];
      if (idValue is int) {
        id = idValue;
      } else if (idValue is String) {
        id = int.tryParse(idValue);
      }
    }

    // Parse face_confidence safely
    double? faceConfidence;
    if (data?['face_confidence'] != null) {
      final confValue = data!['face_confidence'];
      if (confValue is double) {
        faceConfidence = confValue;
      } else if (confValue is int) {
        faceConfidence = confValue.toDouble();
      } else if (confValue is String) {
        faceConfidence = double.tryParse(confValue);
      }
    }

    return AttendanceSubmitResult(
      success: success,
      message: message,
      id: id,
      checkType: data?['check_type']?.toString(),
      time: data?['time']?.toString(),
      location: data?['location']?.toString(),
      locationVerified: data?['location_verified'] == true,
      faceVerified: data?['face_verified'] == true,
      faceConfidence: faceConfidence,
    );
  }
}

/// Attendance History Response
class AttendanceHistoryResponse {
  final String startDate;
  final String endDate;
  final int totalDays;
  final List<DailyAttendanceRecord> records;

  AttendanceHistoryResponse({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.records,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recordsJson = json['records'] ?? [];

    return AttendanceHistoryResponse(
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      totalDays: json['total_days'] as int,
      records: recordsJson
          .map((r) =>
              DailyAttendanceRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Daily Attendance Record (grouped by date)
class DailyAttendanceRecord {
  final String date;
  final AttendanceCheckData? checkIn;
  final AttendanceCheckData? checkOut;

  DailyAttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecord(
      date: json['date'] as String,
      checkIn: json['check_in'] != null
          ? AttendanceCheckData.fromJson(
              json['check_in'] as Map<String, dynamic>)
          : null,
      checkOut: json['check_out'] != null
          ? AttendanceCheckData.fromJson(
              json['check_out'] as Map<String, dynamic>)
          : null,
    );
  }
}
