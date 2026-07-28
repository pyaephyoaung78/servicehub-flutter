class StaffAssignmentModel {
  final int id;
  final String assignmentStatus;

  final int bookingId;
  final String bookingStatus;

  final String customerName;
  final String customerEmail;

  final String serviceName;
  final double servicePrice;

  final DateTime scheduledAt;
  final String phone;
  final String address;
  final String? customerNote;

  final String? adminNote;
  final String? staffResponseNote;

  final DateTime? assignedAt;
  final DateTime? respondedAt;
  final DateTime? checkedInAt;

  const StaffAssignmentModel({
    required this.id,
    required this.assignmentStatus,
    required this.bookingId,
    required this.bookingStatus,
    required this.customerName,
    required this.customerEmail,
    required this.serviceName,
    required this.servicePrice,
    required this.scheduledAt,
    required this.phone,
    required this.address,
    required this.customerNote,
    required this.adminNote,
    required this.staffResponseNote,
    required this.assignedAt,
    required this.respondedAt,
    required this.checkedInAt,
  });

  factory StaffAssignmentModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>? ?? {};

    final customer = booking['customer'] as Map<String, dynamic>? ?? {};

    final service = booking['service'] as Map<String, dynamic>? ?? {};
    final checkIn = booking['check_in'] as Map<String, dynamic>? ?? {};

    return StaffAssignmentModel(
      id: json['id'] as int,
      assignmentStatus: json['status']?.toString() ?? '',

      bookingId: booking['id'] as int? ?? 0,
      bookingStatus: booking['status']?.toString() ?? '',

      customerName: customer['name']?.toString() ?? 'Unknown customer',

      customerEmail: customer['email']?.toString() ?? '',

      serviceName: service['booked_name']?.toString() ?? 'Unknown service',

      servicePrice: double.tryParse(service['booked_price'].toString()) ?? 0,

      scheduledAt: DateTime.parse(booking['scheduled_at'].toString()).toLocal(),

      phone: booking['phone']?.toString() ?? '',
      address: booking['address']?.toString() ?? '',
      customerNote: booking['customer_note']?.toString(),

      adminNote: json['admin_note']?.toString(),
      staffResponseNote: json['staff_response_note']?.toString(),

      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'].toString()).toLocal()
          : null,

      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'].toString()).toLocal()
          : null,

      checkedInAt: checkIn['verified_at'] != null
          ? DateTime.parse(checkIn['verified_at'].toString()).toLocal()
          : null,
    );
  }
}
