import '../config/api_config.dart';
import '../models/employee_data_model.dart';
import 'api_client.dart';

class EmployeeService {
  final ApiClient _apiClient = ApiClient();

  /// Get complete employee data for authenticated user
  Future<EmployeeDataModel> getEmployeeData() async {
    try {
      final response = await _apiClient.get('/employee/data');

      if (response.data['success'] == true) {
        return EmployeeDataModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load employee data');
      }
    } catch (e) {
      throw Exception('Failed to load employee data: ${e.toString()}');
    }
  }
}
