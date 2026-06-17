import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/staff_assignment_model.dart';
import '../services/staff_assignment_api_service.dart';
import 'staff_assignment_detail_screen.dart';

class StaffAssignmentListScreen extends StatefulWidget {
  const StaffAssignmentListScreen({super.key});

  @override
  State<StaffAssignmentListScreen> createState() =>
      _StaffAssignmentListScreenState();
}

class _StaffAssignmentListScreenState
    extends State<StaffAssignmentListScreen> {
  late final StaffAssignmentApiService apiService;

  bool isLoading = true;
  String? errorMessage;

  String selectedStatus = 'pending';
  List<StaffAssignmentModel> assignments = [];

  final statuses = const [
    'all',
    'pending',
    'accepted',
    'rejected',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
    );

    apiService = StaffAssignmentApiService(
      apiClient: apiClient,
    );

    loadAssignments();
  }

  Future<void> loadAssignments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await apiService.getAssignments(
        status: selectedStatus == 'all'
            ? null
            : selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        assignments = results;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load assignments: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> selectStatus(String status) async {
    setState(() {
      selectedStatus = status;
    });

    await loadAssignments();
  }

  String formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  String formatDateTime(DateTime value) {
    final hour =
        value.hour.toString().padLeft(2, '0');

    final minute =
        value.minute.toString().padLeft(2, '0');

    return '${value.day}/${value.month}/${value.year} '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];

                return ChoiceChip(
                  label: Text(
                    formatStatus(status),
                  ),
                  selected:
                      selectedStatus == status,
                  onSelected: (_) =>
                      selectStatus(status),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadAssignments,
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (errorMessage != null) {
                    return ListView(
                      children: [
                        const SizedBox(height: 160),
                        Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                errorMessage!,
                                textAlign:
                                    TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed:
                                    loadAssignments,
                                child:
                                    const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (assignments.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No assignments found.',
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final assignment =
                          assignments[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          title: Text(
                            assignment.serviceName,
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                assignment.customerName,
                              ),
                              Text(
                                formatDateTime(
                                  assignment.scheduledAt,
                                ),
                              ),
                              Text(
                                'Job: ${formatStatus(
                                  assignment.bookingStatus,
                                )}',
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              formatStatus(
                                assignment
                                    .assignmentStatus,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final changed =
                                await Navigator.of(
                              context,
                            ).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StaffAssignmentDetailScreen(
                                  assignmentId:
                                      assignment.id,
                                ),
                              ),
                            );

                            if (changed == true) {
                              await loadAssignments();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}