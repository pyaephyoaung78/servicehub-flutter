import '../../../../core/network/api_client.dart';
import '../../../auth/services/models/service_model.dart';
import '../models/admin_staff_model.dart';

class AdminStaffApiService {
  final ApiClient apiClient;

  AdminStaffApiService({
    required this.apiClient,
  });

  Future<List<AdminStaffModel>> getStaff({
    String? search,
    bool? isActive,
    bool? isAvailable,
    int? serviceId,
  }) async {
    final response = await apiClient.dio.get(
      '/admin/staff',
      queryParameters: {
        if (search != null && search.isNotEmpty)
          'search': search,
        if (isActive != null)
          'is_active': isActive ? 1 : 0,
        if (isAvailable != null)
          'is_available': isAvailable ? 1 : 0,
        if (serviceId != null)
          'service_id': serviceId,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => AdminStaffModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AdminStaffModel> getStaffProfile(
    int staffProfileId,
  ) async {
    final response = await apiClient.dio.get(
      '/admin/staff/$staffProfileId',
    );

    final json = response.data['data']['staff']
        as Map<String, dynamic>;

    return AdminStaffModel.fromJson(json);
  }

  Future<List<ServiceModel>> getServices() async {
    final response = await apiClient.dio.get(
      '/services',
      queryParameters: {
        'active_only': 1,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => ServiceModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? bio,
    required bool isActive,
    required bool isAvailable,
    required List<int> serviceIds,
  }) async {
    await apiClient.dio.post(
      '/admin/staff',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'bio': bio?.trim().isEmpty == true
            ? null
            : bio?.trim(),
        'is_active': isActive,
        'is_available': isAvailable,
        'service_ids': serviceIds,
      },
    );
  }

  Future<void> updateStaff({
    required int staffProfileId,
    required String name,
    required String email,
    required String phone,
    String? bio,
    required bool isActive,
    required bool isAvailable,
    required List<int> serviceIds,
  }) async {
    await apiClient.dio.put(
      '/admin/staff/$staffProfileId',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio?.trim().isEmpty == true
            ? null
            : bio?.trim(),
        'is_active': isActive,
        'is_available': isAvailable,
        'service_ids': serviceIds,
      },
    );
  }

  Future<void> deactivateStaff(
    int staffProfileId,
  ) async {
    await apiClient.dio.delete(
      '/admin/staff/$staffProfileId',
    );
  }
}