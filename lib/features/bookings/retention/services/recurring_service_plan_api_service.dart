import '../../../../core/network/api_client.dart';
import '../models/recurring_service_plan_model.dart';

class RecurringServicePlanApiService {
  final ApiClient apiClient;
  RecurringServicePlanApiService({required this.apiClient});

  Future<List<RecurringServicePlanModel>> plans() async {
    final response = await apiClient.dio.get('/customer/service-plans');
    return (response.data['data']['plans'] as List)
        .map(
          (item) =>
              RecurringServicePlanModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> create(int bookingId, int intervalDays) async {
    await apiClient.dio.post(
      '/customer/bookings/$bookingId/service-plan',
      data: {
        'interval_days': intervalDays,
        'reminder_days_before': intervalDays >= 90 ? 14 : 7,
      },
    );
  }

  Future<void> setActive(int planId, bool isActive) async {
    await apiClient.dio.patch(
      '/customer/service-plans/$planId',
      data: {'is_active': isActive},
    );
  }
}
