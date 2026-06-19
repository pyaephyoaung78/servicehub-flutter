import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/invoice_model.dart';
import '../services/invoice_api_service.dart';
import 'admin_invoice_detail_screen.dart';

class AdminInvoiceListScreen extends StatefulWidget {
  const AdminInvoiceListScreen({super.key});

  @override
  State<AdminInvoiceListScreen> createState() =>
      _AdminInvoiceListScreenState();
}

class _AdminInvoiceListScreenState
    extends State<AdminInvoiceListScreen> {
  late final InvoiceApiService apiService;

  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  String selectedStatus = 'all';
  List<InvoiceModel> invoices = [];

  final statuses = const [
    'all',
    'unpaid',
    'partial',
    'paid',
  ];

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadInvoices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results =
          await apiService.getAdminInvoices(
        paymentStatus: selectedStatus,
        search: searchController.text.trim(),
      );

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
        title: const Text('Invoices'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => loadInvoices(),
              decoration: InputDecoration(
                hintText:
                    'Search invoice, customer, service',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: loadInvoices,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];

                return ChoiceChip(
                  label: Text(statusText(status)),
                  selected: selectedStatus == status,
                  onSelected: (_) async {
                    setState(() {
                      selectedStatus = status;
                    });

                    await loadInvoices();
                  },
                );
              },
            ),
          ),

          Expanded(
            child: RefreshIndicator(
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
                        const SizedBox(height: 170),
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
                            'No invoices found.',
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
                              if (invoice.customerName != null)
                                Text(
                                  invoice.customerName!,
                                ),
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
                          onTap: () async {
                            final changed =
                                await Navigator.of(
                              context,
                            ).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminInvoiceDetailScreen(
                                  invoiceId:
                                      invoice.id,
                                ),
                              ),
                            );

                            if (changed == true) {
                              await loadInvoices();
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