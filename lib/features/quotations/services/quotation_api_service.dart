import '../../../core/network/api_client.dart';
import '../models/quotation_model.dart';

class QuotationApiService {
  final ApiClient apiClient;

  QuotationApiService({required this.apiClient});

  Future<QuotationModel> createForBooking({
    required int bookingId,
    required double extraFee,
    required double discountAmount,
    String? adminNote,
    DateTime? validUntil,
  }) async {
    final response = await apiClient.dio.post(
      '/admin/bookings/$bookingId/quotation',
      data: {
        'extra_fee': extraFee,
        'discount_amount': discountAmount,
        'admin_note': adminNote?.trim().isEmpty == true
            ? null
            : adminNote?.trim(),
        'valid_until': validUntil?.toUtc().toIso8601String(),
      },
    );

    return QuotationModel.fromJson(
      response.data['data']['quotation'] as Map<String, dynamic>,
    );
  }

  Future<List<QuotationModel>> getCustomerQuotations() async {
    final response = await apiClient.dio.get('/customer/quotations');
    final items = response.data['data']['data'] as List<dynamic>;

    return items
        .map((item) => QuotationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<QuotationModel> getCustomerQuotation(int quotationId) async {
    final response = await apiClient.dio.get(
      '/customer/quotations/$quotationId',
    );

    return QuotationModel.fromJson(
      response.data['data']['quotation'] as Map<String, dynamic>,
    );
  }

  Future<QuotationModel> respond({
    required int quotationId,
    required String action,
    String? note,
  }) async {
    final response = await apiClient.dio.patch(
      '/customer/quotations/$quotationId/respond',
      data: {
        'action': action,
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      },
    );

    return QuotationModel.fromJson(
      response.data['data']['quotation'] as Map<String, dynamic>,
    );
  }
}
