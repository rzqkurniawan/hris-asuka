import '../models/position_history_model.dart';
import 'api_client.dart';

class PositionHistoryService {
  final ApiClient _apiClient = ApiClient();

  Future<PositionHistoryModel> getPositionHistory() async {
    try {
      final response = await _apiClient.get('/employee/position-history');

      if (response.data['success'] == true) {
        return PositionHistoryModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load position history');
      }
    } catch (e) {
      throw Exception('Failed to load position history: ${e.toString()}');
    }
  }
}
