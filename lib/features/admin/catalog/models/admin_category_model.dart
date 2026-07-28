class AdminCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;

  const AdminCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
  });

  factory AdminCategoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminCategoryModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}