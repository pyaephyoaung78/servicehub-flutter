class AppNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final int? bookingId;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'booking_update',
      title: json['title']?.toString() ?? 'Booking update',
      body: json['body']?.toString() ?? '',
      bookingId: json['booking_id'] as int?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'].toString()).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    );
  }
}
