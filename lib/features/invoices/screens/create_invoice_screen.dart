import 'package:flutter/material.dart';

import '../../../core/errors/api_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../services/invoice_api_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;
  final double servicePrice;

  const CreateInvoiceScreen({
    required this.bookingId,
    required this.serviceName,
    required this.servicePrice,
    super.key,
  });

  @override
  State<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState
    extends State<CreateInvoiceScreen> {
  final formKey = GlobalKey<FormState>();

  final extraFeeController = TextEditingController(
    text: '0',
  );
  final discountController = TextEditingController(
    text: '0',
  );
  final paidController = TextEditingController(
    text: '0',
  );
  final methodController = TextEditingController();
  final noteController = TextEditingController();

  late final InvoiceApiService apiService;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    apiService = InvoiceApiService(
      apiClient: ApiClient(
        tokenStorage: TokenStorage(),
      ),
    );
  }

  @override
  void dispose() {
    extraFeeController.dispose();
    discountController.dispose();
    paidController.dispose();
    methodController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double get extraFee =>
      double.tryParse(extraFeeController.text.trim()) ?? 0;

  double get discount =>
      double.tryParse(discountController.text.trim()) ?? 0;

  double get paid =>
      double.tryParse(paidController.text.trim()) ?? 0;

  double get total =>
      widget.servicePrice + extraFee - discount;

  double get remaining => total - paid;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.createInvoiceFromBooking(
        bookingId: widget.bookingId,
        extraFee: extraFee,
        discountAmount: discount,
        paidAmount: paid,
        paymentMethod: methodController.text,
        note: noteController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.serviceName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Service price: ${money(widget.servicePrice)}',
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: extraFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Extra fee',
                suffixText: 'MMK',
                border: OutlineInputBorder(),
              ),
              validator: validateMoney,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Discount',
                suffixText: 'MMK',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final error = validateMoney(value);

                if (error != null) {
                  return error;
                }

                if (discount >
                    widget.servicePrice + extraFee) {
                  return 'Discount cannot exceed invoice amount.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: paidController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Initial paid amount',
                suffixText: 'MMK',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final error = validateMoney(value);

                if (error != null) {
                  return error;
                }

                if (paid > total) {
                  return 'Paid amount cannot exceed total.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: methodController,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                hintText: 'cash, kpay, wavepay',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'Total',
                      value: money(total),
                    ),
                    _AmountRow(
                      label: 'Paid',
                      value: money(paid),
                    ),
                    _AmountRow(
                      label: 'Remaining',
                      value: money(remaining),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed:
                  isSubmitting ? null : submit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  String? validateMoney(String? value) {
    final amount = double.tryParse(
      value?.trim() ?? '',
    );

    if (amount == null || amount < 0) {
      return 'Enter a valid amount.';
    }

    return null;
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;

  const _AmountRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}