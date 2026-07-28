class StaffProfileModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final bool isActive;
  final bool isAvailable;
  final List<StaffServiceSkillModel> services;

  const StaffProfileModel({
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

  factory StaffProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final user =
        json['user'] as Map<String, dynamic>? ?? {};

    final serviceItems =
        json['services'] as List<dynamic>? ?? [];

    return StaffProfileModel(
      id: json['id'] as int,
      userId: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString(),
      isActive: json['is_active'] == true,
      isAvailable: json['is_available'] == true,
      services: serviceItems
          .map(
            (item) => StaffServiceSkillModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  StaffProfileModel copyWith({
    bool? isAvailable,
  }) {
    return StaffProfileModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      bio: bio,
      isActive: isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      services: services,
    );
  }
}

class StaffServiceSkillModel {
  final int id;
  final String name;
  final String? categoryName;

  const StaffServiceSkillModel({
    required this.id,
    required this.name,
    required this.categoryName,
  });

  factory StaffServiceSkillModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final category =
        json['category'] as Map<String, dynamic>?;

    return StaffServiceSkillModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      categoryName: category?['name']?.toString(),
    );
  }
}