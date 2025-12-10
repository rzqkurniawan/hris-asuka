import '../models/family_data_model.dart';
import 'api_client.dart';

class FamilyService {
  final ApiClient _apiClient = ApiClient();

  Future<FamilyDataModel> getFamilyData() async {
    try {
      final response = await _apiClient.get('/employee/family');

      if (response.data['success'] == true) {
        return FamilyDataModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load family data');
      }
    } catch (e) {
      throw Exception('Failed to load family data: ${e.toString()}');
    }
  }
}
