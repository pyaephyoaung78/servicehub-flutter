class QuotationModel {
  final int id;
  final String quotationNo;
  final int bookingId;
  final String? customerName;
  final String serviceName;
  final double servicePrice;
  final double extraFee;
  final double discountAmount;
  final double totalAmount;
  final String status;
  final String? adminNote;
  final String? customerResponseNote;
  final DateTime? validUntil;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  const QuotationModel({
    required this.id,
    required this.quotationNo,
    required this.bookingId,
    required this.customerName,
    required this.serviceName,
    required this.servicePrice,
    required this.extraFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    required this.adminNote,
    required this.customerResponseNote,
    required this.validUntil,
    required this.sentAt,
    required this.acceptedAt,
    required this.rejectedAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>? ?? {};
    final amounts = json['amounts'] as Map<String, dynamic>? ?? {};

    return QuotationModel(
      id: json['id'] as int,
      quotationNo: json['quotation_no']?.toString() ?? '',
      bookingId: json['booking_id'] as int? ?? 0,
      customerName: customer?['name']?.toString(),
      serviceName: service['name']?.toString() ?? '',
      servicePrice: _toDouble(service['price']),
      extraFee: _toDouble(amounts['extra_fee']),
      discountAmount: _toDouble(amounts['discount_amount']),
      totalAmount: _toDouble(amounts['total_amount']),
      status: json['status']?.toString() ?? '',
      adminNote: json['admin_note']?.toString(),
      customerResponseNote: json['customer_response_note']?.toString(),
      validUntil: _toDateTime(json['valid_until']),
      sentAt: _toDateTime(json['sent_at']),
      acceptedAt: _toDateTime(json['accepted_at']),
      rejectedAt: _toDateTime(json['rejected_at']),
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value.toString()).toLocal();
  }
}
