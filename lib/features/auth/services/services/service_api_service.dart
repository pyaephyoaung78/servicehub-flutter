import '../../../../core/network/api_client.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

class ServiceApiService {
  final ApiClient apiClient;

  ServiceApiService({
    required this.apiClient,
  });

  Future<List<ServiceCategoryModel>> getCategories() async {
    final response = await apiClient.dio.get('/service-categories');

    final List items = response.data['data']['data'];

    return items
        .map((item) => ServiceCategoryModel.fromJson(item))
        .toList();
  }

  Future<List<ServiceModel>> getServices({
    int? serviceCategoryId,
    String? search,
  }) async {
    final response = await apiClient.dio.get(
      '/services',
      queryParameters: {
        if (serviceCategoryId != null) 'service_category_id': serviceCategoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final List items = response.data['data']['data'];

    return items.map((item) => ServiceModel.fromJson(item)).toList();
  }
}