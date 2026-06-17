import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/staff_assignment_model.dart';
import '../services/staff_assignment_api_service.dart';

class StaffAssignmentDetailScreen
    extends StatefulWidget {
  final int assignmentId;

  const StaffAssignmentDetailScreen({
    required this.assignmentId,
    super.key,
  });

  @override
  State<StaffAssignmentDetailScreen> createState() =>
      _StaffAssignmentDetailScreenState();
}

class _StaffAssignmentDetailScreenState
    extends State<StaffAssignmentDetailScreen> {
  late final StaffAssignmentApiService apiService;

  final responseNoteController =
      TextEditingController();

  StaffAssignmentModel? assignment;

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  bool wasChanged = false;

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

    loadAssignment();
  }

  @override
  void dispose() {
    responseNoteController.dispose();
    super.dispose();
  }

  Future<void> loadAssignment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await apiService.getAssignment(
        widget.assignmentId,
      );

      if (!mounted) return;

      setState(() {
        assignment = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load assignment: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> respond(String action) async {
    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.respond(
        assignmentId: widget.assignmentId,
        action: action,
        responseNote:
            responseNoteController.text,
      );

      if (!mounted) return;

      wasChanged = true;

      showMessage(
        action == 'accept'
            ? 'Assignment accepted.'
            : 'Assignment rejected.',
      );

      await loadAssignment();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Failed to respond: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> updateWorkStatus(
    String action,
  ) async {
    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.updateWorkStatus(
        assignmentId: widget.assignmentId,
        action: action,
      );

      if (!mounted) return;

      wasChanged = true;
      showMessage(successMessage(action));

      await loadAssignment();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Failed to update status: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String successMessage(String action) {
    switch (action) {
      case 'mark_on_the_way':
        return 'Marked as on the way.';
      case 'start':
        return 'Service started.';
      case 'complete':
        return 'Service completed.';
      default:
        return 'Status updated.';
    }
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget? buildActionSection(
    StaffAssignmentModel current,
  ) {
    if (current.assignmentStatus == 'pending') {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: responseNoteController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Response note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : () => respond('accept'),
            icon: const Icon(Icons.check),
            label: const Text('Accept Assignment'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isSubmitting
                ? null
                : () => respond('reject'),
            icon: const Icon(Icons.close),
            label: const Text('Reject Assignment'),
          ),
        ],
      );
    }

    if (current.assignmentStatus != 'accepted') {
      return null;
    }

    switch (current.bookingStatus) {
      case 'accepted':
        return FilledButton.icon(
          onPressed: isSubmitting
              ? null
              : () => updateWorkStatus(
                    'mark_on_the_way',
                  ),
          icon: const Icon(Icons.directions_car),
          label: const Text('Mark On The Way'),
        );

      case 'on_the_way':
        return FilledButton.icon(
          onPressed: isSubmitting
              ? null
              : () => updateWorkStatus('start'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Service'),
        );

      case 'in_progress':
        return FilledButton.icon(
          onPressed: isSubmitting
              ? null
              : () => updateWorkStatus('complete'),
          icon: const Icon(Icons.task_alt),
          label: const Text('Complete Service'),
        );

      case 'completed':
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle),
                SizedBox(width: 10),
                Text('Service completed'),
              ],
            ),
          ),
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(wasChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Details'),
        ),
        body: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: loadAssignment,
                        child:
                            const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final current = assignment!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  current.serviceName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),

                Text(
                  '${current.servicePrice.toStringAsFixed(0)} MMK',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 24),

                _DetailRow(
                  label: 'Assignment status',
                  value: formatStatus(
                    current.assignmentStatus,
                  ),
                ),

                _DetailRow(
                  label: 'Job status',
                  value: formatStatus(
                    current.bookingStatus,
                  ),
                ),

                _DetailRow(
                  label: 'Customer',
                  value: current.customerName,
                ),

                _DetailRow(
                  label: 'Customer email',
                  value: current.customerEmail,
                ),

                _DetailRow(
                  label: 'Phone',
                  value: current.phone,
                ),

                _DetailRow(
                  label: 'Schedule',
                  value: formatDateTime(
                    current.scheduledAt,
                  ),
                ),

                _DetailRow(
                  label: 'Address',
                  value: current.address,
                ),

                if (current.customerNote != null)
                  _DetailRow(
                    label: 'Customer note',
                    value: current.customerNote!,
                  ),

                if (current.adminNote != null)
                  _DetailRow(
                    label: 'Admin note',
                    value: current.adminNote!,
                  ),

                if (current.staffResponseNote != null)
                  _DetailRow(
                    label: 'Your response',
                    value:
                        current.staffResponseNote!,
                  ),

                const SizedBox(height: 16),

                if (buildActionSection(current)
                    case final actionWidget?)
                  actionWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge,
          ),
          const SizedBox(height: 4),
          Text(value),
          const Divider(height: 20),
        ],
      ),
    );
  }
}