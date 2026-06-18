import '../../../../core/network/api_client.dart';
import '../models/admin_category_model.dart';
import '../models/admin_service_model.dart';

class AdminCatalogApiService {
  final ApiClient apiClient;

  AdminCatalogApiService({
    required this.apiClient,
  });

  Future<List<AdminCategoryModel>> getCategories({
    bool activeOnly = false,
  }) async {
    final response = await apiClient.dio.get(
      '/service-categories',
      queryParameters: {
        'active_only': activeOnly ? 1 : 0,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => AdminCategoryModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> createCategory({
    required String name,
    String? description,
    required bool isActive,
  }) async {
    await apiClient.dio.post(
      '/admin/service-categories',
      data: {
        'name': name,
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'is_active': isActive,
      },
    );
  }

  Future<void> updateCategory({
    required int categoryId,
    required String name,
    String? description,
    required bool isActive,
  }) async {
    await apiClient.dio.put(
      '/admin/service-categories/$categoryId',
      data: {
        'name': name,
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'is_active': isActive,
      },
    );
  }

  Future<void> deactivateCategory(
    int categoryId,
  ) async {
    await apiClient.dio.delete(
      '/admin/service-categories/$categoryId',
    );
  }

  Future<List<AdminServiceModel>> getServices({
    bool activeOnly = false,
    int? categoryId,
    String? search,
  }) async {
    final response = await apiClient.dio.get(
      '/services',
      queryParameters: {
        'active_only': activeOnly ? 1 : 0,
        if (categoryId != null)
          'service_category_id': categoryId,
        if (search != null && search.isNotEmpty)
          'search': search,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => AdminServiceModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> createService({
    required int categoryId,
    required String name,
    String? description,
    required double basePrice,
    int? estimatedDurationMinutes,
    required bool isActive,
  }) async {
    await apiClient.dio.post(
      '/admin/services',
      data: {
        'service_category_id': categoryId,
        'name': name,
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'base_price': basePrice,
        'estimated_duration_minutes':
            estimatedDurationMinutes,
        'is_active': isActive,
      },
    );
  }

  Future<void> updateService({
    required int serviceId,
    required int categoryId,
    required String name,
    String? description,
    required double basePrice,
    int? estimatedDurationMinutes,
    required bool isActive,
  }) async {
    await apiClient.dio.put(
      '/admin/services/$serviceId',
      data: {
        'service_category_id': categoryId,
        'name': name,
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'base_price': basePrice,
        'estimated_duration_minutes':
            estimatedDurationMinutes,
        'is_active': isActive,
      },
    );
  }

  Future<void> deactivateService(
    int serviceId,
  ) async {
    await apiClient.dio.delete(
      '/admin/services/$serviceId',
    );
  }
}