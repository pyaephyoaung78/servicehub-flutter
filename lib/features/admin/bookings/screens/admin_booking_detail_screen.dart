import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';
import 'package:flutter_laravel_testing/features/invoices/screens/admin_invoice_detail_screen.dart';
import 'package:flutter_laravel_testing/features/invoices/screens/create_invoice_screen.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_booking_model.dart';
import '../services/admin_booking_api_service.dart';
import 'assign_staff_screen.dart';
import '../../../quotations/screens/create_quotation_screen.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const AdminBookingDetailScreen({required this.bookingId, super.key});

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late final AdminBookingApiService apiService;

  AdminBookingModel? booking;
  bool isLoading = true;
  String? errorMessage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    apiService = AdminBookingApiService(apiClient: apiClient);

    loadBooking();
  }

  Future<void> loadBooking() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await apiService.getBooking(widget.bookingId);

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

  Future<void> openAssignStaff() async {
    final currentBooking = booking;

    if (currentBooking == null) {
      return;
    }

    final assigned = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssignStaffScreen(booking: currentBooking),
      ),
    );

    if (assigned == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> openCreateQuotation() async {
    final current = booking;

    if (current == null) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateQuotationScreen(
          bookingId: current.id,
          serviceName: current.serviceName,
          servicePrice: current.servicePrice,
        ),
      ),
    );

    if (created == true && mounted) {
      await loadBooking();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation sent to the customer.')),
      );
    }
  }

  Future<String?> showReasonDialog({
    required String title,
    required String actionText,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _ReasonDialog(title: title, actionText: actionText);
      },
    );
  }

  Future<void> cancelBooking() async {
    if (isSubmitting) {
      return;
    }

    final reason = await showReasonDialog(
      title: 'Cancel Booking',
      actionText: 'Cancel Booking',
    );

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.cancelBooking(
        bookingId: widget.bookingId,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      // Return true so the booking list refreshes.
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

  Future<void> rejectBooking() async {
    if (isSubmitting) {
      return;
    }

    final reason = await showReasonDialog(
      title: 'Reject Booking',
      actionText: 'Reject Booking',
    );

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.rejectBooking(
        bookingId: widget.bookingId,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      // Return true so the booking list refreshes.
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

  Future<void> openCreateInvoice() async {
    final current = booking;

    if (current == null) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(
          bookingId: current.id,
          serviceName: current.serviceName,
          servicePrice: current.servicePrice,
        ),
      ),
    );

    if (created == true && mounted) {
      await loadBooking();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully.')),
      );
    }
  }

  Future<void> openInvoiceDetail() async {
    final current = booking;

    if (current?.invoice == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AdminInvoiceDetailScreen(invoiceId: current!.invoice!.id),
      ),
    );

    if (mounted) {
      await loadBooking();
    }
  }

  String formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  String formatStatus(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              Text(
                '${current.servicePrice.toStringAsFixed(0)} MMK',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              _DetailRow(label: 'Status', value: formatStatus(current.status)),
              _DetailRow(label: 'Customer', value: current.customerName),
              _DetailRow(label: 'Customer email', value: current.customerEmail),
              _DetailRow(label: 'Phone', value: current.phone),
              _DetailRow(
                label: 'Schedule',
                value: formatDateTime(current.scheduledAt),
              ),
              _DetailRow(label: 'Address', value: current.address),

              if (current.customerNote != null)
                _DetailRow(
                  label: 'Customer note',
                  value: current.customerNote!,
                ),

              if (current.latestAssignment != null) ...[
                _DetailRow(
                  label: 'Assigned staff',
                  value: current.latestAssignment!.staffName,
                ),
                _DetailRow(
                  label: 'Assignment status',
                  value: formatStatus(current.latestAssignment!.status),
                ),
              ],

              if (current.quotation != null) ...[
                _DetailRow(
                  label: 'Quotation',
                  value: current.quotation!.quotationNo,
                ),
                _DetailRow(
                  label: 'Quotation status',
                  value: formatStatus(current.quotation!.status),
                ),
                _DetailRow(
                  label: 'Quoted total',
                  value:
                      '${current.quotation!.totalAmount.toStringAsFixed(0)} MMK',
                ),
              ],

              if (current.status == 'pending' && current.quotation == null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: openCreateQuotation,
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Create Quotation'),
                ),
              ],

              if (current.status == 'pending' &&
                  current.quotation?.status == 'accepted') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: openAssignStaff,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Assign Staff'),
                ),
              ],

              if (current.status == 'pending' &&
                  current.quotation != null &&
                  current.quotation!.status != 'accepted')
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Staff can be assigned after the customer accepts the quotation.',
                  ),
                ),

              if (current.status == 'pending') ...[
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : rejectBooking,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Reject Booking'),
                ),
              ],

              if (current.status == 'completed' && current.invoice == null) ...[
                const SizedBox(height: 10),

                FilledButton.icon(
                  onPressed: openCreateInvoice,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Create Invoice'),
                ),
              ],

              if (current.invoice != null) ...[
                const SizedBox(height: 10),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(current.invoice!.invoiceNo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${current.invoice!.paymentStatus.toUpperCase()}',
                        ),
                        Text(
                          'Remaining: ${current.invoice!.remainingAmount.toStringAsFixed(0)} MMK',
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: openInvoiceDetail,
                  ),
                ),
              ],

              if ([
                'pending',
                'assigned',
                'accepted',
              ].contains(current.status)) ...[
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : cancelBooking,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Booking'),
                ),
              ],

              if (current.cancellationReason != null) ...[
                _DetailRow(
                  label: 'Cancellation reason',
                  value: current.cancellationReason!,
                ),

                if (current.cancelledByName != null)
                  _DetailRow(
                    label: 'Cancelled by',
                    value: current.cancelledByName!,
                  ),
              ],

              if (current.rejectionReason != null) ...[
                _DetailRow(
                  label: 'Rejection reason',
                  value: current.rejectionReason!,
                ),

                if (current.rejectedByName != null)
                  _DetailRow(
                    label: 'Rejected by',
                    value: current.rejectedByName!,
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

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String actionText;

  const _ReasonDialog({required this.title, required this.actionText});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reasonController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Reason',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Reason is required.';
            }

            return null;
          },
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
        FilledButton(onPressed: _submit, child: Text(widget.actionText)),
      ],
    );
  }
}
