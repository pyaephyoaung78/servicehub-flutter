import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/booking_model.dart';
import '../services/booking_api_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({required this.bookingId, super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final BookingApiService bookingApiService;

  BookingModel? booking;
  bool isLoading = true;
  String? errorMessage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    bookingApiService = BookingApiService(apiClient: apiClient);

    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final result = await bookingApiService.getBooking(widget.bookingId);

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
        errorMessage = 'Failed to load booking: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> cancelBooking() async {
    if (isSubmitting) {
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _CustomerCancelReasonDialog();
      },
    );

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await bookingApiService.cancelBooking(
        bookingId: widget.bookingId,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ApiErrorHandler.message(error))));
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(errorMessage!, textAlign: TextAlign.center),
              ),
            );
          }

          final currentBooking = booking!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                currentBooking.serviceName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              Text(
                '${currentBooking.servicePrice.toStringAsFixed(0)} MMK',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),

              _DetailRow(
                label: 'Status',
                value: currentBooking.status.replaceAll('_', ' ').toUpperCase(),
              ),
              _DetailRow(
                label: 'Schedule',
                value: _formatDateTime(currentBooking.scheduledAt),
              ),
              _DetailRow(label: 'Phone', value: currentBooking.phone),
              _DetailRow(label: 'Address', value: currentBooking.address),

              if (currentBooking.customerNote != null)
                _DetailRow(label: 'Note', value: currentBooking.customerNote!),

              if (currentBooking.cancellationReason != null)
                _DetailRow(
                  label: 'Cancellation reason',
                  value: currentBooking.cancellationReason!,
                ),

              if (currentBooking.rejectionReason != null)
                _DetailRow(
                  label: 'Rejection reason',
                  value: currentBooking.rejectionReason!,
                ),

              if (['pending', 'assigned'].contains(currentBooking.status)) ...[
                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: isSubmitting ? null : cancelBooking,
                  icon: const Icon(Icons.cancel_outlined),
                  label: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel Booking'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
          const Divider(height: 20),
        ],
      ),
    );
  }
}

class _CustomerCancelReasonDialog extends StatefulWidget {
  const _CustomerCancelReasonDialog();

  @override
  State<_CustomerCancelReasonDialog> createState() =>
      _CustomerCancelReasonDialogState();
}

class _CustomerCancelReasonDialogState
    extends State<_CustomerCancelReasonDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _reasonController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Booking'),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Cancel Booking'),
        ),
      ],
    );
  }
}
