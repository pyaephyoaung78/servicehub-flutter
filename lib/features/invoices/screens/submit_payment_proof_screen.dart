import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../services/invoice_api_service.dart';

class SubmitPaymentProofScreen extends StatefulWidget {
  final int invoiceId;
  final double remainingAmount;

  const SubmitPaymentProofScreen({
    required this.invoiceId,
    required this.remainingAmount,
    super.key,
  });

  @override
  State<SubmitPaymentProofScreen> createState() =>
      _SubmitPaymentProofScreenState();
}

class _SubmitPaymentProofScreenState extends State<SubmitPaymentProofScreen> {
  final amountController = TextEditingController();
  final paymentMethodController = TextEditingController();
  final noteController = TextEditingController();

  late final InvoiceApiService apiService;

  String? selectedFilePath;
  String? selectedFileName;
  String? errorMessage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    amountController.text = widget.remainingAmount.toStringAsFixed(0);
    apiService = InvoiceApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    paymentMethodController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> chooseFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (!mounted || result.isEmpty) return;

    final file = result.firstOrNull;
    if (file == null || file.path == null) {
      setState(() {
        errorMessage = 'This device did not provide a readable file path.';
      });
      return;
    }

    setState(() {
      selectedFilePath = file.path;
      selectedFileName = file.name;
      errorMessage = null;
    });
  }

  Future<void> submit() async {
    final amount = double.tryParse(amountController.text.trim());
    final method = paymentMethodController.text.trim();

    if (amount == null || amount <= 0) {
      setState(() {
        errorMessage = 'Enter a valid payment amount.';
      });
      return;
    }

    if (amount > widget.remainingAmount) {
      setState(() {
        errorMessage = 'Amount cannot exceed the remaining invoice balance.';
      });
      return;
    }

    if (method.isEmpty) {
      setState(() {
        errorMessage = 'Enter the payment method.';
      });
      return;
    }

    if (selectedFilePath == null) {
      setState(() {
        errorMessage = 'Select your payment receipt first.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await apiService.submitCustomerPaymentProof(
        invoiceId: widget.invoiceId,
        amount: amount,
        paymentMethod: method,
        filePath: selectedFilePath!,
        note: noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof submitted for review.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not submit payment proof: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Payment Proof')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Upload your payment receipt',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining balance: ${widget.remainingAmount.toStringAsFixed(0)} MMK',
          ),
          const SizedBox(height: 24),
          if (errorMessage != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              suffixText: 'MMK',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: paymentMethodController,
            decoration: const InputDecoration(
              labelText: 'Payment method',
              hintText: 'KPay, WavePay, bank transfer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : chooseFile,
            icon: const Icon(Icons.attach_file),
            label: Text(selectedFileName ?? 'Choose receipt image or PDF'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : submit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit for review'),
          ),
        ],
      ),
    );
  }
}
