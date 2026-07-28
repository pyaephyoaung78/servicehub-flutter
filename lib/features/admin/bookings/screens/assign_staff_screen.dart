import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_booking_model.dart';
import '../models/eligible_staff_model.dart';
import '../services/admin_booking_api_service.dart';

class AssignStaffScreen extends StatefulWidget {
  final AdminBookingModel booking;

  const AssignStaffScreen({
    required this.booking,
    super.key,
  });

  @override
  State<AssignStaffScreen> createState() =>
      _AssignStaffScreenState();
}

class _AssignStaffScreenState
    extends State<AssignStaffScreen> {
  late final AdminBookingApiService apiService;

  final noteController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  List<EligibleStaffModel> staff = [];
  int? selectedStaffId;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
    );

    apiService = AdminBookingApiService(
      apiClient: apiClient,
    );

    loadEligibleStaff();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> loadEligibleStaff() async {
    try {
      final results =
          await apiService.getEligibleStaff(
        widget.booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        staff = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Failed to load eligible staff: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> assignStaff() async {
    if (selectedStaffId == null) {
      showMessage('Select a staff member.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.assignStaff(
        bookingId: widget.booking.id,
        staffProfileId: selectedStaffId!,
        adminNote: noteController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Staff assigned successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Assignment failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Staff'),
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
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (staff.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No active and available staff are '
                  'qualified for this service.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.booking.serviceName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Customer: '
                '${widget.booking.customerName}',
              ),
              const SizedBox(height: 20),

              Text(
                'Eligible staff',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),

              ...staff.map(
                (member) => Card(
                  child: RadioListTile<int>(
                    value: member.id,
                    groupValue: selectedStaffId,
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              selectedStaffId = value;
                            });
                          },
                    title: Text(member.name),
                    subtitle: Text(
                      '${member.phone}\n${member.email}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Admin note (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed:
                    isSubmitting ? null : assignStaff,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Assignment',
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}