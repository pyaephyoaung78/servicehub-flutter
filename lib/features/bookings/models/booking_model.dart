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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>;

    return BookingModel(
      id: json['id'],
      serviceId: service['id'],
      serviceName: service['booked_name'],
      servicePrice: double.parse(
        service['booked_price'].toString(),
      ),
      scheduledAt: DateTime.parse(json['scheduled_at']).toLocal(),
      phone: json['phone'],
      address: json['address'],
      customerNote: json['customer_note'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }
}