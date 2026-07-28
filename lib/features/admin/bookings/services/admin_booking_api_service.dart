import '../../../../core/network/api_client.dart';
import '../models/admin_booking_model.dart';
import '../models/eligible_staff_model.dart';

class AdminBookingApiService {
  final ApiClient apiClient;

  AdminBookingApiService({required this.apiClient});

  Future<List<AdminBookingModel>> getBookings({
    String? status,
    String? search,
  }) async {
    final response = await apiClient.dio.get(
      '/admin/bookings',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map((item) => AdminBookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBookingModel> getBooking(int bookingId) async {
    final response = await apiClient.dio.get('/admin/bookings/$bookingId');

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return AdminBookingModel.fromJson(bookingJson);
  }

  Future<List<EligibleStaffModel>> getEligibleStaff(int bookingId) async {
    final response = await apiClient.dio.get(
      '/admin/bookings/$bookingId/eligible-staff',
    );

    final List items = response.data['data']['staff'];

    return items
        .map(
          (item) => EligibleStaffModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> assignStaff({
    required int bookingId,
    required int staffProfileId,
    String? adminNote,
  }) async {
    await apiClient.dio.post(
      '/admin/bookings/$bookingId/assign',
      data: {
        'staff_profile_id': staffProfileId,
        'admin_note': adminNote?.trim().isEmpty == true
            ? null
            : adminNote?.trim(),
      },
    );
  }

  Future<AdminBookingModel> cancelBooking({
    required int bookingId,
    required String reason,
  }) async {
    final response = await apiClient.dio.patch(
      '/admin/bookings/$bookingId/cancel',
      data: {'reason': reason.trim()},
    );

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return AdminBookingModel.fromJson(bookingJson);
  }

  Future<AdminBookingModel> rejectBooking({
    required int bookingId,
    required String reason,
  }) async {
    final response = await apiClient.dio.patch(
      '/admin/bookings/$bookingId/reject',
      data: {'reason': reason.trim()},
    );

    final bookingJson =
        response.data['data']['booking'] as Map<String, dynamic>;

    return AdminBookingModel.fromJson(bookingJson);
  }
}
