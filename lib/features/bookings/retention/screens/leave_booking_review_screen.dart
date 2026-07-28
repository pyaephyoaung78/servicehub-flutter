import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../services/customer_retention_api_service.dart';

class LeaveBookingReviewScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;

  const LeaveBookingReviewScreen({
    required this.bookingId,
    required this.serviceName,
    super.key,
  });

  @override
  State<LeaveBookingReviewScreen> createState() =>
      _LeaveBookingReviewScreenState();
}

class _LeaveBookingReviewScreenState extends State<LeaveBookingReviewScreen> {
  final _commentController = TextEditingController();
  late final CustomerRetentionApiService retentionApiService;

  int rating = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    retentionApiService = CustomerRetentionApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (rating == 0) {
      _showMessage('Please choose a rating before submitting.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isSubmitting = true);

    try {
      await retentionApiService.submitReview(
        bookingId: widget.bookingId,
        rating: rating,
        comment: _commentController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(ApiErrorHandler.message(error));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your service')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.serviceName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'How was your service experience? Your review will be checked before it is published.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      tooltip: '$star star${star == 1 ? '' : 's'}',
                      onPressed: isSubmitting
                          ? null
                          : () => setState(() => rating = star),
                      iconSize: 38,
                      color: Colors.amber.shade700,
                      icon: Icon(
                        star <= rating ? Icons.star : Icons.star_border,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                enabled: !isSubmitting,
                maxLength: 1500,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Share feedback (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: const Text('Submit review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
