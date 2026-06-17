import 'service_category_model.dart';

class ServiceModel {
  final int id;
  final int serviceCategoryId;
  final ServiceCategoryModel? category;
  final String name;
  final String slug;
  final String? description;
  final double basePrice;
  final int? estimatedDurationMinutes;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.serviceCategoryId,
    required this.category,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.estimatedDurationMinutes,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serviceCategoryId: json['service_category_id'],
      category: json['category'] != null
          ? ServiceCategoryModel.fromJson(json['category'])
          : null,
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      basePrice: double.parse(json['base_price'].toString()),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      isActive: json['is_active'] ?? false,
    );
  }
}