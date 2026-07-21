import 'package:flutter/material.dart';

import '../../../core/errors/api_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../services/quotation_api_service.dart';

class CreateQuotationScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;
  final double servicePrice;

  const CreateQuotationScreen({
    required this.bookingId,
    required this.serviceName,
    required this.servicePrice,
    super.key,
  });

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _extraFeeController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _validForDaysController = TextEditingController(text: '7');
  final _noteController = TextEditingController();

  late final QuotationApiService _apiService;
  bool _isSubmitting = false;

  double get _extraFee => double.tryParse(_extraFeeController.text.trim()) ?? 0;
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;
  double get _total => widget.servicePrice + _extraFee - _discount;

  @override
  void initState() {
    super.initState();
    _apiService = QuotationApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
  }

  @override
  void dispose() {
    _extraFeeController.dispose();
    _discountController.dispose();
    _validForDaysController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final validForDays = int.parse(_validForDaysController.text.trim());

      await _apiService.createForBooking(
        bookingId: widget.bookingId,
        extraFee: _extraFee,
        discountAmount: _discount,
        adminNote: _noteController.text,
        validUntil: DateTime.now().add(Duration(days: validForDays)),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ApiErrorHandler.message(error))));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateMoney(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');

    if (amount == null || amount < 0) {
      return 'Enter a valid amount.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quotation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.serviceName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Service price: ${widget.servicePrice.toStringAsFixed(0)} MMK',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _extraFeeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Extra fee',
                suffixText: 'MMK',
                border: OutlineInputBorder(),
              ),
              validator: _validateMoney,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Discount',
                suffixText: 'MMK',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final error = _validateMoney(value);
                if (error != null) {
                  return error;
                }

                if (_discount > widget.servicePrice + _extraFee) {
                  return 'Discount cannot exceed the quotation amount.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _validForDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valid for',
                suffixText: 'days',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final days = int.tryParse(value?.trim() ?? '');
                if (days == null || days < 1) {
                  return 'Enter at least 1 day.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note for customer (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quoted total'),
                    Text(
                      '${_total.toStringAsFixed(0)} MMK',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(Icons.send_outlined),
              label: Text(_isSubmitting ? 'Sending...' : 'Send Quotation'),
            ),
          ],
        ),
      ),
    );
  }
}
