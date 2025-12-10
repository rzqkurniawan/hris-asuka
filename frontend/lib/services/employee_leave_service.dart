import '../config/api_config.dart';
import '../models/employee_leave_model.dart';
import 'api_client.dart';

class EmployeeLeaveService {
  final ApiClient _apiClient = ApiClient();

  /// Get all active employees for substitute dropdown
  Future<List<Employee>> getActiveEmployees() async {
    try {
      final response = await _apiClient.get('${ApiConfig.leave}/employees');

      if (response.data['success'] == true) {
        final List<dynamic> employeesJson = response.data['data'] ?? [];
        return employeesJson
            .map((json) => Employee.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load employees');
      }
    } catch (e) {
      throw Exception('Failed to load employees: ${e.toString()}');
    }
  }

  /// Get all available leave categories
  Future<List<LeaveCategory>> getLeaveCategories() async {
    try {
      final response = await _apiClient.get('${ApiConfig.leave}/categories');

      if (response.data['success'] == true) {
        final List<dynamic> categoriesJson = response.data['data'] ?? [];
        return categoriesJson
            .map((json) => LeaveCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load leave categories');
      }
    } catch (e) {
      throw Exception('Failed to load leave categories: ${e.toString()}');
    }
  }

  /// Get all employee leaves for authenticated user
  Future<EmployeeLeavesResponse> getEmployeeLeaves() async {
    try {
      final response = await _apiClient.get(ApiConfig.leave);

      print('===== EMPLOYEE LEAVE API RESPONSE =====');
      print('Success: ${response.data['success']}');

      if (response.data['success'] == true) {
        final data = response.data['data'];

        final List<dynamic> leavesJson = data['leaves'] ?? [];
        print('Total leaves from API: ${leavesJson.length}');

        // Print first 2 items for debugging dates
        if (leavesJson.isNotEmpty) {
          print('--- First leave item ---');
          print('date_begin: ${leavesJson[0]['date_begin']}');
          print('date_end: ${leavesJson[0]['date_end']}');
          print('date_begin_formatted: ${leavesJson[0]['date_begin_formatted']}');
          print('date_end_formatted: ${leavesJson[0]['date_end_formatted']}');
        }
        if (leavesJson.length > 1) {
          print('--- Second leave item ---');
          print('date_begin: ${leavesJson[1]['date_begin']}');
          print('date_end: ${leavesJson[1]['date_end']}');
          print('date_begin_formatted: ${leavesJson[1]['date_begin_formatted']}');
          print('date_end_formatted: ${leavesJson[1]['date_end_formatted']}');
        }

        final leaves = leavesJson
            .map((json) => EmployeeLeave.fromJson(json as Map<String, dynamic>))
            .toList();

        return EmployeeLeavesResponse(
          totalRecords: data['total_records'] as int,
          leaves: leaves,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load employee leaves');
      }
    } catch (e) {
      print('ERROR in getEmployeeLeaves: $e');
      throw Exception('Failed to load employee leaves: ${e.toString()}');
    }
  }

  /// Get employee leave detail by ID
  Future<EmployeeLeave> getEmployeeLeaveDetail(int id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.leave}/$id');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return EmployeeLeave.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load leave detail');
      }
    } catch (e) {
      throw Exception('Failed to load leave detail: ${e.toString()}');
    }
  }

  /// Create new employee leave request
  Future<CreateLeaveResponse> createEmployeeLeave(
      CreateLeaveRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.leave,
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return CreateLeaveResponse(
          employeeLeaveId: data['employee_leave_id'] as int,
          employeeLeaveNumber: data['employee_leave_number'] as String,
          message: response.data['message'] as String,
        );
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create leave request');
      }
    } catch (e) {
      throw Exception('Failed to create leave request: ${e.toString()}');
    }
  }

  /// Update existing employee leave
  Future<void> updateEmployeeLeave(
      int id, UpdateLeaveRequest request) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.leave}/$id',
        data: request.toJson(),
      );

      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'Failed to update leave request');
      }
    } catch (e) {
      throw Exception('Failed to update leave request: ${e.toString()}');
    }
  }

  /// Delete employee leave (soft delete)
  Future<void> deleteEmployeeLeave(int id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.leave}/$id');

      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'Failed to delete leave request');
      }
    } catch (e) {
      throw Exception('Failed to delete leave request: ${e.toString()}');
    }
  }
}

/// Response model for employee leaves list
class EmployeeLeavesResponse {
  final int totalRecords;
  final List<EmployeeLeave> leaves;

  EmployeeLeavesResponse({
    required this.totalRecords,
    required this.leaves,
  });
}

/// Response model for create leave request
class CreateLeaveResponse {
  final int employeeLeaveId;
  final String employeeLeaveNumber;
  final String message;

  CreateLeaveResponse({
    required this.employeeLeaveId,
    required this.employeeLeaveNumber,
    required this.message,
  });
}
