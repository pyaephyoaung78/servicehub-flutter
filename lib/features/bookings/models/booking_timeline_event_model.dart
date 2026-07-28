class BookingTimelineEventModel {
  final String eventType;
  final String title;
  final String? description;
  final DateTime occurredAt;

  const BookingTimelineEventModel({
    required this.eventType,
    required this.title,
    required this.description,
    required this.occurredAt,
  });

  factory BookingTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineEventModel(
      eventType: json['event_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      occurredAt: DateTime.parse(json['occurred_at'].toString()).toLocal(),
    );
  }
}
