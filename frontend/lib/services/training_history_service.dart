import '../models/training_history_model.dart';
import 'api_client.dart';

class TrainingHistoryService {
  final ApiClient _apiClient = ApiClient();

  Future<TrainingHistoryModel> getTrainingHistory() async {
    try {
      final response = await _apiClient.get('/employee/training-history');

      if (response.data['success'] == true) {
        return TrainingHistoryModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load training history');
      }
    } catch (e) {
      throw Exception('Failed to load training history: ${e.toString()}');
    }
  }
}
