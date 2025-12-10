import '../config/api_config.dart';
import '../models/overtime_order.dart';
import '../models/employee_overtime_detail.dart';
import 'api_client.dart';

class OvertimeService {
  final ApiClient _apiClient = ApiClient();

  /// Get overtime list for authenticated user
  /// Only returns overtimes where user is involved
  Future<OvertimeListResponse> getOvertimeList() async {
    try {
      final response = await _apiClient.get(ApiConfig.overtime);

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Parse overtimes list
        final List<dynamic> overtimesJson = data['overtimes'] ?? [];
        final overtimes = overtimesJson
            .map((json) => OvertimeOrder.fromJson(json as Map<String, dynamic>))
            .toList();

        final overtimeCount = data['overtime_count'] as int? ?? 0;

        return OvertimeListResponse(
          overtimes: overtimes,
          overtimeCount: overtimeCount,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load overtime list');
      }
    } catch (e) {
      throw Exception('Failed to load overtime list: ${e.toString()}');
    }
  }

  /// Get overtime detail by ID
  /// Returns overtime header and list of employees involved
  Future<OvertimeDetailResponse> getOvertimeDetail(int id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.overtime}/$id');

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Parse overtime header
        final overtimeOrder = OvertimeOrder.fromJson(
          data['overtime'] as Map<String, dynamic>,
        );

        // Parse employees list
        final List<dynamic> employeesJson = data['employees'] ?? [];
        final employees = employeesJson
            .map((json) =>
                EmployeeOvertimeDetail.fromJson(json as Map<String, dynamic>))
            .toList();

        final employeeCount = data['employee_count'] as int? ?? 0;

        return OvertimeDetailResponse(
          overtime: overtimeOrder,
          employees: employees,
          employeeCount: employeeCount,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load overtime detail');
      }
    } catch (e) {
      throw Exception('Failed to load overtime detail: ${e.toString()}');
    }
  }
}

/// Response model for overtime list
class OvertimeListResponse {
  final List<OvertimeOrder> overtimes;
  final int overtimeCount;

  OvertimeListResponse({
    required this.overtimes,
    required this.overtimeCount,
  });

  // Helper to calculate statistics
  int get approvedCount =>
      overtimes.where((o) => o.isApproved).length;

  int get rejectedCount =>
      overtimes.where((o) => !o.isApproved).length;
}

/// Response model for overtime detail
class OvertimeDetailResponse {
  final OvertimeOrder overtime;
  final List<EmployeeOvertimeDetail> employees;
  final int employeeCount;

  OvertimeDetailResponse({
    required this.overtime,
    required this.employees,
    required this.employeeCount,
  });
}
