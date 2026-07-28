class EligibleStaffModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final bool isAvailable;

  const EligibleStaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.isAvailable,
  });

  factory EligibleStaffModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final user =
        json['user'] as Map<String, dynamic>? ?? {};

    return EligibleStaffModel(
      id: json['id'] as int,
      name: user['name']?.toString() ?? 'Unknown staff',
      email: user['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isActive: json['is_active'] == true,
      isAvailable: json['is_available'] == true,
    );
  }
}