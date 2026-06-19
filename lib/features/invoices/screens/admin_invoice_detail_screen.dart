import 'package:flutter/material.dart';

import '../../../core/errors/api_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/invoice_model.dart';
import '../services/invoice_api_service.dart';

class AdminInvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const AdminInvoiceDetailScreen({
    required this.invoiceId,
    super.key,
  });

  @override
  State<AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState
    extends State<AdminInvoiceDetailScreen> {
  late final InvoiceApiService apiService;

  InvoiceModel? invoice;

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  bool wasChanged = false;

  @override
  void initState() {
    super.initState();

    apiService = InvoiceApiService(
      apiClient: ApiClient(
        tokenStorage: TokenStorage(),
      ),
    );

    loadInvoice();
  }

  Future<void> loadInvoice() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await apiService.getAdminInvoice(
        widget.invoiceId,
      );

      if (!mounted) return;

      setState(() {
        invoice = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load invoice: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> recordPayment() async {
    final current = invoice;

    if (current == null ||
        current.paymentStatus == 'paid') {
      return;
    }

    final data = await showDialog<_PaymentDialogData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecordPaymentDialog(
        maxAmount: current.remainingAmount,
      ),
    );

    if (!mounted || data == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final updated =
          await apiService.recordPayment(
        invoiceId: current.id,
        amount: data.amount,
        paymentMethod: data.paymentMethod,
        note: data.note,
      );

      if (!mounted) return;

      setState(() {
        invoice = updated;
        wasChanged = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment recorded successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorHandler.message(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String money(double amount) {
    return '${amount.toStringAsFixed(0)} MMK';
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day}/${date.month}/${date.year}';
  }

  String statusText(String status) {
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && wasChanged) {
          // The parent list will still refresh only if this screen
          // is popped with true. AppBar back cannot return value here.
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoice Detail'),
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
                child: Text(errorMessage!),
              );
            }

            final current = invoice!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  current.invoiceNo,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    statusText(current.paymentStatus),
                  ),
                ),
                const SizedBox(height: 20),

                _DetailRow(
                  label: 'Customer',
                  value: current.customerName ?? '-',
                ),
                _DetailRow(
                  label: 'Service',
                  value: current.serviceName,
                ),
                _DetailRow(
                  label: 'Service price',
                  value: money(current.servicePrice),
                ),
                _DetailRow(
                  label: 'Extra fee',
                  value: money(current.extraFee),
                ),
                _DetailRow(
                  label: 'Discount',
                  value: money(current.discountAmount),
                ),
                _DetailRow(
                  label: 'Total amount',
                  value: money(current.totalAmount),
                ),
                _DetailRow(
                  label: 'Paid amount',
                  value: money(current.paidAmount),
                ),
                _DetailRow(
                  label: 'Remaining amount',
                  value: money(current.remainingAmount),
                ),
                _DetailRow(
                  label: 'Issued at',
                  value: formatDate(current.issuedAt),
                ),

                if (current.note != null)
                  _DetailRow(
                    label: 'Note',
                    value: current.note!,
                  ),

                const SizedBox(height: 16),

                if (current.paymentStatus != 'paid')
                  FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : recordPayment,
                    icon: const Icon(Icons.payments),
                    label: const Text('Record Payment'),
                  ),

                const SizedBox(height: 24),

                Text(
                  'Payment History',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 8),

                if (current.payments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No payments recorded.',
                      ),
                    ),
                  )
                else
                  ...current.payments.map(
                    (payment) => Card(
                      child: ListTile(
                        title: Text(
                          money(payment.amount),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.paymentMethod ??
                                  'No method',
                            ),
                            if (payment.receivedByName !=
                                null)
                              Text(
                                'Received by: ${payment.receivedByName}',
                              ),
                            Text(
                              'Date: ${formatDate(payment.paidAt)}',
                            ),
                            if (payment.note != null)
                              Text(payment.note!),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentDialogData {
  final double amount;
  final String? paymentMethod;
  final String? note;

  const _PaymentDialogData({
    required this.amount,
    required this.paymentMethod,
    required this.note,
  });
}

class _RecordPaymentDialog extends StatefulWidget {
  final double maxAmount;

  const _RecordPaymentDialog({
    required this.maxAmount,
  });

  @override
  State<_RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState
    extends State<_RecordPaymentDialog> {
  final formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final methodController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    methodController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _PaymentDialogData(
        amount: double.parse(
          amountController.text.trim(),
        ),
        paymentMethod: methodController.text.trim(),
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Remaining: ${widget.maxAmount.toStringAsFixed(0)} MMK',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount.';
                  }

                  if (amount > widget.maxAmount) {
                    return 'Amount cannot exceed remaining balance.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: methodController,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  hintText: 'cash, kpay, wavepay',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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
          onPressed: submit,
          child: const Text('Save Payment'),
        ),
      ],
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