import '../models/education_history_model.dart';
import 'api_client.dart';

class EducationHistoryService {
  final ApiClient _apiClient = ApiClient();

  Future<EducationHistoryModel> getEducationHistory() async {
    try {
      final response = await _apiClient.get('/employee/education-history');

      if (response.data['success'] == true) {
        return EducationHistoryModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load education history');
      }
    } catch (e) {
      throw Exception('Failed to load education history: ${e.toString()}');
    }
  }
}
