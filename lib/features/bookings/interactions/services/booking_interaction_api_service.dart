import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/booking_interaction_models.dart';

class BookingInteractionApiService {
  final ApiClient apiClient;
  BookingInteractionApiService({required this.apiClient});

  Future<List<BookingMessageModel>> messages(int bookingId) async {
    final response = await apiClient.dio.get('/bookings/$bookingId/messages');
    return (response.data['data']['messages'] as List)
        .map(
          (item) => BookingMessageModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ServiceProofModel>> proofs(int bookingId) async {
    final response = await apiClient.dio.get(
      '/bookings/$bookingId/service-proofs',
    );
    return (response.data['data']['proofs'] as List)
        .map((item) => ServiceProofModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(int bookingId, String body, String? filePath) async {
    final data = FormData.fromMap({
      'body': body.trim(),
      if (filePath != null)
        'attachment': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split(RegExp(r'[/\\]')).last,
        ),
    });
    await apiClient.dio.post(
      '/bookings/$bookingId/messages',
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> uploadProof(
    int bookingId,
    String kind,
    String path,
    String? note,
  ) async {
    final data = FormData.fromMap({
      'kind': kind,
      'image': await MultipartFile.fromFile(
        path,
        filename: path.split(RegExp(r'[/\\]')).last,
      ),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    await apiClient.dio.post(
      '/bookings/$bookingId/service-proofs',
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
