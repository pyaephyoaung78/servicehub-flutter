import '../../../../core/network/api_client.dart';
import '../models/app_notification_model.dart';

class NotificationApiService {
  final ApiClient apiClient;

  NotificationApiService({required this.apiClient});

  Future<List<AppNotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get('/notifications');
    final items = response.data['data']['data'] as List;

    return items
        .map(
          (item) => AppNotificationModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await apiClient.dio.patch('/notifications/$notificationId/read');
  }
}
