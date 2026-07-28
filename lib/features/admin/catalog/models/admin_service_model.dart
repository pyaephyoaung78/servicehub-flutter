import 'admin_category_model.dart';

class AdminServiceModel {
  final int id;
  final int categoryId;
  final AdminCategoryModel? category;
  final String name;
  final String slug;
  final String? description;
  final double basePrice;
  final int? estimatedDurationMinutes;
  final bool isActive;

  const AdminServiceModel({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.estimatedDurationMinutes,
    required this.isActive,
  });

  factory AdminServiceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final categoryJson =
        json['category'] as Map<String, dynamic>?;

    return AdminServiceModel(
      id: json['id'] as int,
      categoryId:
          json['service_category_id'] as int? ?? 0,
      category: categoryJson != null
          ? AdminCategoryModel.fromJson(categoryJson)
          : null,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      basePrice: double.tryParse(
            json['base_price'].toString(),
          ) ??
          0,
      estimatedDurationMinutes:
          json['estimated_duration_minutes'] as int?,
      isActive: json['is_active'] == true,
    );
  }
}