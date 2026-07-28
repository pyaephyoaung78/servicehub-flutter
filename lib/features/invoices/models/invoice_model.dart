class InvoiceModel {
  final int id;
  final String invoiceNo;
  final int bookingId;

  final String? customerName;
  final String? customerEmail;
  final String? issuedByName;

  final String serviceName;
  final double servicePrice;

  final double extraFee;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  final String paymentStatus;

  final DateTime? issuedAt;
  final DateTime? paidAt;

  final String? note;

  final List<InvoicePaymentModel> payments;
  final List<PaymentProofModel> paymentProofs;

  const InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.bookingId,
    required this.customerName,
    required this.customerEmail,
    required this.issuedByName,
    required this.serviceName,
    required this.servicePrice,
    required this.extraFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.issuedAt,
    required this.paidAt,
    required this.note,
    required this.payments,
    required this.paymentProofs,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;

    final issuedBy = json['issued_by'] as Map<String, dynamic>?;

    final service = json['service'] as Map<String, dynamic>? ?? {};

    final amounts = json['amounts'] as Map<String, dynamic>? ?? {};

    final paymentsJson = json['payments'] as List<dynamic>? ?? [];
    final paymentProofsJson = json['payment_proofs'] as List<dynamic>? ?? [];

    return InvoiceModel(
      id: json['id'] as int,
      invoiceNo: json['invoice_no']?.toString() ?? '',
      bookingId: json['booking_id'] as int? ?? 0,

      customerName: customer?['name']?.toString(),
      customerEmail: customer?['email']?.toString(),
      issuedByName: issuedBy?['name']?.toString(),

      serviceName: service['name']?.toString() ?? '',
      servicePrice: _toDouble(service['price']),

      extraFee: _toDouble(amounts['extra_fee']),
      discountAmount: _toDouble(amounts['discount_amount']),
      totalAmount: _toDouble(amounts['total_amount']),
      paidAmount: _toDouble(amounts['paid_amount']),
      remainingAmount: _toDouble(amounts['remaining_amount']),

      paymentStatus: json['payment_status']?.toString() ?? '',

      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'].toString()).toLocal()
          : null,

      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'].toString()).toLocal()
          : null,

      note: json['note']?.toString(),

      payments: paymentsJson
          .map(
            (item) =>
                InvoicePaymentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),

      paymentProofs: paymentProofsJson
          .map(
            (item) => PaymentProofModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0;
  }
}

class InvoicePaymentModel {
  final int id;
  final double amount;
  final String? paymentMethod;
  final String? note;
  final DateTime? paidAt;
  final String? receivedByName;

  const InvoicePaymentModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.note,
    required this.paidAt,
    required this.receivedByName,
  });

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    final receivedBy = json['received_by'] as Map<String, dynamic>?;

    return InvoicePaymentModel(
      id: json['id'] as int,
      amount: InvoiceModel._toDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString(),
      note: json['note']?.toString(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'].toString()).toLocal()
          : null,
      receivedByName: receivedBy?['name']?.toString(),
    );
  }
}

class PaymentProofModel {
  final int id;
  final int invoiceId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? note;
  final String? reviewNote;
  final String? fileName;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? invoicePaymentId;

  const PaymentProofModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.note,
    required this.reviewNote,
    required this.fileName,
    required this.submittedAt,
    required this.reviewedAt,
    required this.invoicePaymentId,
  });

  factory PaymentProofModel.fromJson(Map<String, dynamic> json) {
    final proof = json['proof'] as Map<String, dynamic>? ?? {};

    return PaymentProofModel(
      id: json['id'] as int,
      invoiceId: json['invoice_id'] as int? ?? 0,
      amount: InvoiceModel._toDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      reviewNote: json['review_note']?.toString(),
      fileName: proof['file_name']?.toString(),
      submittedAt: _parseDate(json['submitted_at']),
      reviewedAt: _parseDate(json['reviewed_at']),
      invoicePaymentId: json['invoice_payment_id'] as int?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
