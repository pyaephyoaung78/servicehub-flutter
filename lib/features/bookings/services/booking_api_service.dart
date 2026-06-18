import '../../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingApiService {
  final ApiClient apiClient;

  BookingApiService({required this.apiClient});

  Future<BookingModel> createBooking({
    required int serviceId,
    required DateTime scheduledAt,
    required String phone,
    required String address,
    String? customerNote,
  }) async {
    final response = await apiClient.dio.post(
      '/customer/bookings',
      data: {
        'service_id': serviceId,

        // ISO-8601 keeps date, time and timezone information.
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),

        'phone': phone,
        'address': address,
        'customer_note': customerNote,
      },
    );

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return BookingModel.fromJson(bookingJson);
  }

  Future<List<BookingModel>> getBookings() async {
    final response = await apiClient.dio.get('/customer/bookings');

    final List items = response.data['data']['data'];

    return items
        .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> getBooking(int bookingId) async {
    final response = await apiClient.dio.get('/customer/bookings/$bookingId');

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return BookingModel.fromJson(bookingJson);
  }

  Future<BookingModel> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    final response = await apiClient.dio.patch(
      '/customer/bookings/$bookingId/cancel',
      data: {'reason': reason?.trim().isEmpty == true ? null : reason?.trim()},
    );

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return BookingModel.fromJson(bookingJson);
  }
}
