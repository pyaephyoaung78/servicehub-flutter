class AdminBookingModel {
  final int id;

  final int customerId;
  final String customerName;
  final String customerEmail;

  final int serviceId;
  final String serviceName;
  final double servicePrice;

  final DateTime scheduledAt;
  final String phone;
  final String address;
  final String? customerNote;
  final String status;

  final AssignmentSummaryModel? latestAssignment;

  const AdminBookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.scheduledAt,
    required this.phone,
    required this.address,
    required this.customerNote,
    required this.status,
    required this.latestAssignment,
  });

  factory AdminBookingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final customer =
        json['customer'] as Map<String, dynamic>? ?? {};

    final service =
        json['service'] as Map<String, dynamic>? ?? {};

    final assignmentJson =
        json['latest_assignment'] as Map<String, dynamic>?;

    return AdminBookingModel(
      id: json['id'] as int,

      customerId: customer['id'] as int? ?? 0,
      customerName:
          customer['name']?.toString() ?? 'Unknown customer',
      customerEmail:
          customer['email']?.toString() ?? '',

      serviceId: service['id'] as int? ?? 0,
      serviceName:
          service['booked_name']?.toString() ??
              'Unknown service',
      servicePrice: double.tryParse(
            service['booked_price'].toString(),
          ) ??
          0,

      scheduledAt:
          DateTime.parse(json['scheduled_at']).toLocal(),

      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      customerNote: json['customer_note']?.toString(),
      status: json['status']?.toString() ?? '',

      latestAssignment: assignmentJson != null
          ? AssignmentSummaryModel.fromJson(
              assignmentJson,
            )
          : null,
    );
  }
}

class AssignmentSummaryModel {
  final int id;
  final String status;
  final int staffProfileId;
  final String staffName;
  final String? adminNote;

  const AssignmentSummaryModel({
    required this.id,
    required this.status,
    required this.staffProfileId,
    required this.staffName,
    required this.adminNote,
  });

  factory AssignmentSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final staff =
        json['staff'] as Map<String, dynamic>? ?? {};

    return AssignmentSummaryModel(
      id: json['id'] as int,
      status: json['status']?.toString() ?? '',
      staffProfileId: staff['id'] as int? ?? 0,
      staffName:
          staff['name']?.toString() ?? 'Unknown staff',
      adminNote: json['admin_note']?.toString(),
    );
  }
}