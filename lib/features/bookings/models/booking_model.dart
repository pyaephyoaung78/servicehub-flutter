import 'booking_timeline_event_model.dart';

class BookingModel {
  final int id;
  final int serviceId;
  final String serviceName;
  final double servicePrice;
  final DateTime scheduledAt;
  final String phone;
  final String address;
  final String? customerNote;
  final String status;
  final DateTime? createdAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? checkInCode;
  final DateTime? checkInCodeExpiresAt;
  final DateTime? checkedInAt;
  final List<BookingTimelineEventModel> timeline;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.scheduledAt,
    required this.phone,
    required this.address,
    required this.customerNote,
    required this.status,
    required this.createdAt,
    required this.cancellationReason,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.rejectedAt,
    required this.checkInCode,
    required this.checkInCodeExpiresAt,
    required this.checkedInAt,
    required this.timeline,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>;

    final closure = json['closure'] as Map<String, dynamic>? ?? {};
    final checkIn = json['check_in'] as Map<String, dynamic>? ?? {};
    final timeline = json['timeline'] as List? ?? [];

    return BookingModel(
      id: json['id'],
      serviceId: service['id'],
      serviceName: service['booked_name'],
      servicePrice: double.parse(service['booked_price'].toString()),
      scheduledAt: DateTime.parse(json['scheduled_at']).toLocal(),
      phone: json['phone'],
      address: json['address'],
      customerNote: json['customer_note'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,

      cancellationReason: closure['cancellation_reason']?.toString(),

      cancelledAt: closure['cancelled_at'] != null
          ? DateTime.parse(closure['cancelled_at'].toString()).toLocal()
          : null,

      rejectionReason: closure['rejection_reason']?.toString(),

      rejectedAt: closure['rejected_at'] != null
          ? DateTime.parse(closure['rejected_at'].toString()).toLocal()
          : null,

      checkInCode: checkIn['code']?.toString(),

      checkInCodeExpiresAt: checkIn['code_expires_at'] != null
          ? DateTime.parse(checkIn['code_expires_at'].toString()).toLocal()
          : null,

      checkedInAt: checkIn['verified_at'] != null
          ? DateTime.parse(checkIn['verified_at'].toString()).toLocal()
          : null,

      timeline: timeline
          .map(
            (item) => BookingTimelineEventModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
