class BookingReviewModel {
  final int id;
  final int bookingId;
  final int rating;
  final String? comment;
  final String status;
  final DateTime? createdAt;

  const BookingReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  factory BookingReviewModel.fromJson(Map<String, dynamic> json) {
    return BookingReviewModel(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : null,
    );
  }
}
