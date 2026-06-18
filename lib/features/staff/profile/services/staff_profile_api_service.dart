import '../../../../core/network/api_client.dart';
import '../models/staff_profile_model.dart';

class StaffProfileApiService {
  final ApiClient apiClient;

  StaffProfileApiService({
    required this.apiClient,
  });

  Future<StaffProfileModel> getProfile() async {
    final response = await apiClient.dio.get(
      '/staff/profile',
    );

    final profileJson =
        response.data['data']['staff']
            as Map<String, dynamic>;

    return StaffProfileModel.fromJson(profileJson);
  }

  Future<StaffProfileModel> updateAvailability({
    required bool isAvailable,
  }) async {
    final response = await apiClient.dio.patch(
      '/staff/availability',
      data: {
        'is_available': isAvailable,
      },
    );

    final profileJson =
        response.data['data']['staff']
            as Map<String, dynamic>;

    return StaffProfileModel.fromJson(profileJson);
  }
}