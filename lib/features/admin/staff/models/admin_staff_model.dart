class AdminStaffModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final bool isActive;
  final bool isAvailable;
  final List<AdminStaffServiceModel> services;

  const AdminStaffModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.isActive,
    required this.isAvailable,
    required this.services,
  });

  factory AdminStaffModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final user =
        json['user'] as Map<String, dynamic>? ?? {};

    final servicesJson =
        json['services'] as List<dynamic>? ?? [];

    return AdminStaffModel(
      id: json['id'] as int,
      userId: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString(),
      isActive: json['is_active'] == true,
      isAvailable: json['is_available'] == true,
      services: servicesJson
          .map(
            (item) => AdminStaffServiceModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class AdminStaffServiceModel {
  final int id;
  final String name;
  final String? categoryName;

  const AdminStaffServiceModel({
    required this.id,
    required this.name,
    required this.categoryName,
  });

  factory AdminStaffServiceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final category =
        json['category'] as Map<String, dynamic>?;

    return AdminStaffServiceModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      categoryName: category?['name']?.toString(),
    );
  }
}