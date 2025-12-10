import '../models/work_experience_model.dart';
import 'api_client.dart';

class WorkExperienceService {
  final ApiClient _apiClient = ApiClient();

  Future<WorkExperienceModel> getWorkExperience() async {
    try {
      final response = await _apiClient.get('/employee/work-experience');

      if (response.data['success'] == true) {
        return WorkExperienceModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load work experience');
      }
    } catch (e) {
      throw Exception('Failed to load work experience: ${e.toString()}');
    }
  }
}
