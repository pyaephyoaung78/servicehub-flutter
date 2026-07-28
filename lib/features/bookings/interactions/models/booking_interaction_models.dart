class BookingMessageModel {
  final int id;
  final String? body;
  final String senderName;
  final String senderRole;
  final String? attachmentName;
  final DateTime createdAt;

  const BookingMessageModel({
    required this.id,
    required this.body,
    required this.senderName,
    required this.senderRole,
    required this.attachmentName,
    required this.createdAt,
  });

  factory BookingMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    final attachment = json['attachment'] as Map<String, dynamic>?;
    return BookingMessageModel(
      id: json['id'] as int,
      body: json['body']?.toString(),
      senderName: sender['name']?.toString() ?? 'User',
      senderRole: sender['role']?.toString() ?? '',
      attachmentName: attachment?['name']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    );
  }
}

class ServiceProofModel {
  final int id;
  final String kind;
  final String imageName;
  final String? note;
  final DateTime capturedAt;

  const ServiceProofModel({
    required this.id,
    required this.kind,
    required this.imageName,
    required this.note,
    required this.capturedAt,
  });

  factory ServiceProofModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>? ?? {};
    return ServiceProofModel(
      id: json['id'] as int,
      kind: json['kind'].toString(),
      imageName: image['name']?.toString() ?? 'Photo',
      note: json['note']?.toString(),
      capturedAt: DateTime.parse(json['captured_at'].toString()).toLocal(),
    );
  }
}
