import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/invoice_model.dart';
import '../services/invoice_api_service.dart';

class CustomerInvoiceDetailScreen
    extends StatefulWidget {
  final int invoiceId;

  const CustomerInvoiceDetailScreen({
    required this.invoiceId,
    super.key,
  });

  @override
  State<CustomerInvoiceDetailScreen> createState() =>
      _CustomerInvoiceDetailScreenState();
}

class _CustomerInvoiceDetailScreenState
    extends State<CustomerInvoiceDetailScreen> {
  late final InvoiceApiService apiService;

  bool isLoading = true;
  String? errorMessage;

  InvoiceModel? invoice;

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
    try {
      final result =
          await apiService.getCustomerInvoice(
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
    return Scaffold(
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
                      'No payment has been recorded yet.',
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
                          Text(
                            'Date: ${formatDate(payment.paidAt)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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