import '../../../../core/network/api_client.dart';
import '../../../auth/services/models/service_model.dart';
import '../../models/booking_model.dart';
import '../models/booking_review_model.dart';

class CustomerRetentionApiService {
  final ApiClient apiClient;

  CustomerRetentionApiService({required this.apiClient});

  Future<BookingReviewModel> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await apiClient.dio.post(
      '/customer/bookings/$bookingId/review',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );

    return BookingReviewModel.fromJson(
      response.data['data']['review'] as Map<String, dynamic>,
    );
  }

  Future<BookingModel> rebook({
    required int bookingId,
    required DateTime scheduledAt,
  }) async {
    final response = await apiClient.dio.post(
      '/customer/bookings/$bookingId/rebook',
      data: {'scheduled_at': scheduledAt.toUtc().toIso8601String()},
    );

    return BookingModel.fromJson(
      response.data['data']['booking'] as Map<String, dynamic>,
    );
  }

  Future<List<ServiceModel>> getFavoriteServices() async {
    final response = await apiClient.dio.get('/customer/favorite-services');
    final items = response.data['data']['services'] as List;

    return items
        .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> toggleFavorite(int serviceId) async {
    final response = await apiClient.dio.post(
      '/customer/services/$serviceId/favorite',
    );

    return response.data['data']['is_favorite'] == true;
  }
}
