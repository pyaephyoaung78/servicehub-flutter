import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/quotation_model.dart';
import '../services/quotation_api_service.dart';
import 'customer_quotation_detail_screen.dart';

class CustomerQuotationListScreen extends StatefulWidget {
  const CustomerQuotationListScreen({super.key});

  @override
  State<CustomerQuotationListScreen> createState() =>
      _CustomerQuotationListScreenState();
}

class _CustomerQuotationListScreenState
    extends State<CustomerQuotationListScreen> {
  late final QuotationApiService _apiService;
  List<QuotationModel> _quotations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = QuotationApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quotations = await _apiService.getCustomerQuotations();

      if (!mounted) {
        return;
      }

      setState(() => _quotations = quotations);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = 'Unable to load quotations.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _statusText(String status) =>
      status.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Quotations')),
      body: RefreshIndicator(
        onRefresh: _loadQuotations,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(_errorMessage!)),
                ],
              );
            }

            if (_quotations.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('No quotations yet.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _quotations.length,
              itemBuilder: (context, index) {
                final quotation = _quotations[index];

                return Card(
                  child: ListTile(
                    title: Text(quotation.quotationNo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quotation.serviceName),
                        Text(
                          'Total: ${quotation.totalAmount.toStringAsFixed(0)} MMK',
                        ),
                        if (quotation.validUntil != null)
                          Text(
                            'Valid until: ${quotation.validUntil!.day}/${quotation.validUntil!.month}/${quotation.validUntil!.year}',
                          ),
                      ],
                    ),
                    trailing: Chip(label: Text(_statusText(quotation.status))),
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CustomerQuotationDetailScreen(
                            quotationId: quotation.id,
                          ),
                        ),
                      );

                      if (changed == true && mounted) {
                        await _loadQuotations();
                      }
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
