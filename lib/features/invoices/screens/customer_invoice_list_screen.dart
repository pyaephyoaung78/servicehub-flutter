import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/invoice_model.dart';
import '../services/invoice_api_service.dart';
import 'customer_invoice_detail_screen.dart';

class CustomerInvoiceListScreen extends StatefulWidget {
  const CustomerInvoiceListScreen({super.key});

  @override
  State<CustomerInvoiceListScreen> createState() =>
      _CustomerInvoiceListScreenState();
}

class _CustomerInvoiceListScreenState
    extends State<CustomerInvoiceListScreen> {
  late final InvoiceApiService apiService;

  bool isLoading = true;
  String? errorMessage;

  List<InvoiceModel> invoices = [];

  @override
  void initState() {
    super.initState();

    apiService = InvoiceApiService(
      apiClient: ApiClient(
        tokenStorage: TokenStorage(),
      ),
    );

    loadInvoices();
  }

  Future<void> loadInvoices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results =
          await apiService.getCustomerInvoices();

      if (!mounted) return;

      setState(() {
        invoices = results;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load invoices: $error';
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

  String statusText(String status) {
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invoices'),
      ),
      body: RefreshIndicator(
        onRefresh: loadInvoices,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Text(errorMessage!),
                  ),
                ],
              );
            }

            if (invoices.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'No invoices yet.',
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];

                return Card(
                  child: ListTile(
                    title: Text(invoice.invoiceNo),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(invoice.serviceName),
                        Text(
                          'Total: ${money(invoice.totalAmount)}',
                        ),
                        Text(
                          'Remaining: ${money(invoice.remainingAmount)}',
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        statusText(
                          invoice.paymentStatus,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CustomerInvoiceDetailScreen(
                            invoiceId: invoice.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}