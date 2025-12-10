import '../config/api_config.dart';
import '../models/pay_slip_model.dart';
import 'api_client.dart';

class PaySlipService {
  final ApiClient _apiClient = ApiClient();

  /// Get available pay slip periods
  Future<AvailablePeriodsResponse> getAvailablePeriods() async {
    try {
      final response = await _apiClient.get('${ApiConfig.payslip}/periods');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return AvailablePeriodsResponse.fromJson(data);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load available periods');
      }
    } catch (e) {
      throw Exception('Failed to load available periods: ${e.toString()}');
    }
  }

  /// Get pay slip detail for specific period
  Future<PaySlipDetail?> getPaySlipDetail({
    required String month,
    required String year,
    String period = '1 - 31',
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.payslip}/detail',
        queryParameters: {
          'month': month,
          'year': year,
          'period': period,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return PaySlipDetail.fromJson(data);
      } else {
        // Return null if pay slip not found
        if (response.statusCode == 404) {
          return null;
        }
        throw Exception(
            response.data['message'] ?? 'Failed to load pay slip detail');
      }
    } catch (e) {
      // Return null for 404 errors (pay slip not found)
      if (e.toString().contains('404') ||
          e.toString().contains('not found')) {
        return null;
      }
      throw Exception('Failed to load pay slip detail: ${e.toString()}');
    }
  }
}
