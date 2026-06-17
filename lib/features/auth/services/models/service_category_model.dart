class ServiceCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;

  ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      isActive: json['is_active'] ?? false,
    );
  }
}