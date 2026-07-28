import '../../../../core/network/api_client.dart';
import '../models/staff_assignment_model.dart';

class StaffAssignmentApiService {
  final ApiClient apiClient;

  StaffAssignmentApiService({required this.apiClient});

  Future<List<StaffAssignmentModel>> getAssignments({String? status}) async {
    final response = await apiClient.dio.get(
      '/staff/assignments',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final List items = response.data['data']['data'];

    return items
        .map(
          (item) => StaffAssignmentModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<StaffAssignmentModel> getAssignment(int assignmentId) async {
    final response = await apiClient.dio.get(
      '/staff/assignments/$assignmentId',
    );

    final assignmentJson =
        response.data['data']['assignment'] as Map<String, dynamic>;

    return StaffAssignmentModel.fromJson(assignmentJson);
  }

  Future<void> respond({
    required int assignmentId,
    required String action,
    String? responseNote,
  }) async {
    await apiClient.dio.patch(
      '/staff/assignments/$assignmentId/respond',
      data: {
        'action': action,
        'response_note': responseNote?.trim().isEmpty == true
            ? null
            : responseNote?.trim(),
      },
    );
  }

  Future<void> updateWorkStatus({
    required int assignmentId,
    required String action,
    String? checkInCode,
  }) async {
    await apiClient.dio.patch(
      '/staff/assignments/$assignmentId/work-status',
      data: {'action': action, 'check_in_code': checkInCode},
    );
  }
}
