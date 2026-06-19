import '../../../core/network/api_client.dart';
import '../models/invoice_model.dart';

class InvoiceApiService {
  final ApiClient apiClient;

  InvoiceApiService({
    required this.apiClient,
  });

  Future<List<InvoiceModel>> getAdminInvoices({
    String? paymentStatus,
    String? search,
  }) async {
    final response = await apiClient.dio.get(
      '/admin/invoices',
      queryParameters: {
        if (paymentStatus != null &&
            paymentStatus.isNotEmpty &&
            paymentStatus != 'all')
          'payment_status': paymentStatus,
        if (search != null && search.isNotEmpty)
          'search': search,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => InvoiceModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<InvoiceModel> getAdminInvoice(
    int invoiceId,
  ) async {
    final response = await apiClient.dio.get(
      '/admin/invoices/$invoiceId',
    );

    final invoiceJson =
        response.data['data']['invoice']
            as Map<String, dynamic>;

    return InvoiceModel.fromJson(invoiceJson);
  }

  Future<InvoiceModel> createInvoiceFromBooking({
    required int bookingId,
    required double extraFee,
    required double discountAmount,
    required double paidAmount,
    String? paymentMethod,
    String? note,
  }) async {
    final response = await apiClient.dio.post(
      '/admin/bookings/$bookingId/invoice',
      data: {
        'extra_fee': extraFee,
        'discount_amount': discountAmount,
        'paid_amount': paidAmount,
        'payment_method':
            paymentMethod?.trim().isEmpty == true
                ? null
                : paymentMethod?.trim(),
        'note': note?.trim().isEmpty == true
            ? null
            : note?.trim(),
      },
    );

    final invoiceJson =
        response.data['data']['invoice']
            as Map<String, dynamic>;

    return InvoiceModel.fromJson(invoiceJson);
  }

  Future<InvoiceModel> recordPayment({
    required int invoiceId,
    required double amount,
    String? paymentMethod,
    String? note,
  }) async {
    final response = await apiClient.dio.post(
      '/admin/invoices/$invoiceId/payments',
      data: {
        'amount': amount,
        'payment_method':
            paymentMethod?.trim().isEmpty == true
                ? null
                : paymentMethod?.trim(),
        'note': note?.trim().isEmpty == true
            ? null
            : note?.trim(),
      },
    );

    final invoiceJson =
        response.data['data']['invoice']
            as Map<String, dynamic>;

    return InvoiceModel.fromJson(invoiceJson);
  }

  Future<List<InvoiceModel>> getCustomerInvoices() async {
    final response = await apiClient.dio.get(
      '/customer/invoices',
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => InvoiceModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<InvoiceModel> getCustomerInvoice(
    int invoiceId,
  ) async {
    final response = await apiClient.dio.get(
      '/customer/invoices/$invoiceId',
    );

    final invoiceJson =
        response.data['data']['invoice']
            as Map<String, dynamic>;

    return InvoiceModel.fromJson(invoiceJson);
  }
}