import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_booking_model.dart';
import '../services/admin_booking_api_service.dart';
import 'assign_staff_screen.dart';

class AdminBookingDetailScreen
    extends StatefulWidget {
  final int bookingId;

  const AdminBookingDetailScreen({
    required this.bookingId,
    super.key,
  });

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState
    extends State<AdminBookingDetailScreen> {
  late final AdminBookingApiService apiService;

  AdminBookingModel? booking;
  bool isLoading = true;
  String? errorMessage;
  bool wasChanged = false;

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

    loadBooking();
  }

  Future<void> loadBooking() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await apiService.getBooking(
        widget.bookingId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        booking = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Failed to load booking: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openAssignStaff() async {
    final currentBooking = booking;

    if (currentBooking == null) {
      return;
    }

    final assigned = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssignStaffScreen(
          booking: currentBooking,
        ),
      ),
    );

    if (assigned == true) {
      wasChanged = true;
      await loadBooking();
    }
  }

  String formatDateTime(DateTime dateTime) {
    final hour =
        dateTime.hour.toString().padLeft(2, '0');
    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  String formatStatus(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
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
          title: const Text('Booking Details'),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: loadBooking,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final current = booking!;

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
                  label: 'Status',
                  value: formatStatus(current.status),
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

                if (current.latestAssignment != null) ...[
                  _DetailRow(
                    label: 'Assigned staff',
                    value: current
                        .latestAssignment!.staffName,
                  ),
                  _DetailRow(
                    label: 'Assignment status',
                    value: formatStatus(
                      current
                          .latestAssignment!.status,
                    ),
                  ),
                ],

                if (current.status == 'pending') ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: openAssignStaff,
                    icon: const Icon(
                      Icons.person_add_alt_1,
                    ),
                    label: const Text('Assign Staff'),
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 16),
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