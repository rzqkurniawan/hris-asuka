import '../config/api_config.dart';
import '../models/attendance_model.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  /// Get available periods (years and months) for attendance filtering
  Future<AvailablePeriodsResponse> getAvailablePeriods() async {
    try {
      final response = await _apiClient.get('${ApiConfig.attendance}/periods');

      if (response.data['success'] == true) {
        final data = response.data['data'];

        final List<int> availableYears =
            (data['available_years'] as List).cast<int>();

        final Map<String, dynamic> periodsByYearMap =
            data['periods_by_year'] as Map<String, dynamic>;

        // Convert map to proper structure
        final Map<int, List<int>> periodsByYear = {};
        periodsByYearMap.forEach((key, value) {
          periodsByYear[int.parse(key)] = (value as List).cast<int>();
        });

        return AvailablePeriodsResponse(
          availableYears: availableYears,
          periodsByYear: periodsByYear,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load available periods');
      }
    } catch (e) {
      throw Exception('Failed to load available periods: ${e.toString()}');
    }
  }

  /// Get attendance summary for specific month and year
  Future<MonthlySummary> getAttendanceSummary({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.attendance}/summary',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return MonthlySummary.fromApi(data);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load attendance summary');
      }
    } catch (e) {
      throw Exception('Failed to load attendance summary: ${e.toString()}');
    }
  }

  /// Get detailed attendance records for specific month and year
  Future<AttendanceDetailResponse> getAttendanceDetail({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.attendance}/detail',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Parse attendance records
        final List<dynamic> recordsJson = data['records'] ?? [];
        final records = recordsJson
            .map((json) =>
                AttendanceRecord.fromApi(json as Map<String, dynamic>))
            .toList();

        return AttendanceDetailResponse(
          month: data['month'] as int,
          year: data['year'] as int,
          monthName: data['month_name'] as String,
          monthYear: data['month_year'] as String,
          totalRecords: data['total_records'] as int,
          records: records,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load attendance detail');
      }
    } catch (e) {
      throw Exception('Failed to load attendance detail: ${e.toString()}');
    }
  }
}

/// Response model for available periods
class AvailablePeriodsResponse {
  final List<int> availableYears;
  final Map<int, List<int>> periodsByYear;

  AvailablePeriodsResponse({
    required this.availableYears,
    required this.periodsByYear,
  });

  /// Get available months for a specific year
  List<int> getMonthsForYear(int year) {
    return periodsByYear[year] ?? [];
  }
}

/// Response model for attendance detail
class AttendanceDetailResponse {
  final int month;
  final int year;
  final String monthName;
  final String monthYear;
  final int totalRecords;
  final List<AttendanceRecord> records;

  AttendanceDetailResponse({
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthYear,
    required this.totalRecords,
    required this.records,
  });
}
