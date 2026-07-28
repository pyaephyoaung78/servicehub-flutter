import 'package:flutter/material.dart';

import '../../../core/errors/api_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/quotation_model.dart';
import '../services/quotation_api_service.dart';

class CustomerQuotationDetailScreen extends StatefulWidget {
  final int quotationId;

  const CustomerQuotationDetailScreen({required this.quotationId, super.key});

  @override
  State<CustomerQuotationDetailScreen> createState() =>
      _CustomerQuotationDetailScreenState();
}

class _CustomerQuotationDetailScreenState
    extends State<CustomerQuotationDetailScreen> {
  late final QuotationApiService _apiService;
  QuotationModel? _quotation;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _wasChanged = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = QuotationApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quotation = await _apiService.getCustomerQuotation(
        widget.quotationId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _quotation = quotation);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = ApiErrorHandler.message(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _respond(String action) async {
    final note = await _showResponseDialog(action);
    if (!mounted || note == null || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quotation = await _apiService.respond(
        quotationId: widget.quotationId,
        action: action,
        note: note,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _quotation = quotation;
        _wasChanged = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept'
                ? 'Quotation accepted. The team will assign staff soon.'
                : 'Quotation rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorHandler.message(error))));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String?> _showResponseDialog(String action) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          action == 'accept' ? 'Accept quotation?' : 'Reject quotation?',
        ),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(action == 'accept' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  String _money(double amount) => '${amount.toStringAsFixed(0)} MMK';

  String _date(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _statusText(String status) =>
      status.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_wasChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Quotation Details')),
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return Center(child: Text(_errorMessage!));
            }

            final quotation = _quotation!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  quotation.quotationNo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Chip(label: Text(_statusText(quotation.status))),
                const SizedBox(height: 20),
                _DetailRow(label: 'Service', value: quotation.serviceName),
                _DetailRow(
                  label: 'Service price',
                  value: _money(quotation.servicePrice),
                ),
                _DetailRow(
                  label: 'Extra fee',
                  value: _money(quotation.extraFee),
                ),
                _DetailRow(
                  label: 'Discount',
                  value: _money(quotation.discountAmount),
                ),
                _DetailRow(
                  label: 'Total',
                  value: _money(quotation.totalAmount),
                ),
                _DetailRow(
                  label: 'Valid until',
                  value: _date(quotation.validUntil),
                ),
                if (quotation.adminNote?.isNotEmpty == true)
                  _DetailRow(label: 'Admin note', value: quotation.adminNote!),
                if (quotation.customerResponseNote?.isNotEmpty == true)
                  _DetailRow(
                    label: 'Your response note',
                    value: quotation.customerResponseNote!,
                  ),
                if (quotation.status == 'sent') ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : () => _respond('accept'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept Quotation'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () => _respond('reject'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject Quotation'),
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
