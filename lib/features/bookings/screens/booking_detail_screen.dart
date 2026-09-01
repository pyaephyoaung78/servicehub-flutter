import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/booking_model.dart';
import '../models/booking_timeline_event_model.dart';
import '../services/booking_api_service.dart';
import '../interactions/screens/booking_interaction_screen.dart';
import '../retention/screens/leave_booking_review_screen.dart';
import '../retention/screens/service_plans_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({required this.bookingId, super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final BookingApiService bookingApiService;

  BookingModel? booking;
  bool isLoading = true;
  String? errorMessage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    bookingApiService = BookingApiService(apiClient: apiClient);

    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final result = await bookingApiService.getBooking(widget.bookingId);

      if (!mounted) {
        return;
      }

      setState(() {
        booking = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load booking: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> cancelBooking() async {
    if (isSubmitting) {
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _CustomerCancelReasonDialog();
      },
    );

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await bookingApiService.cancelBooking(
        bookingId: widget.bookingId,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ApiErrorHandler.message(error))));
    }
  }

  Future<void> _leaveReview() async {
    final currentBooking = booking;
    if (currentBooking == null) return;

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeaveBookingReviewScreen(
          bookingId: currentBooking.id,
          serviceName: currentBooking.serviceName,
        ),
      ),
    );

    if (submitted == true) {
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks! Your review is waiting for moderation.'),
          ),
        );
      }
    }
  }

  Future<void> _bookAgain() async {
    if (isSubmitting) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted || time == null) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future date and time.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await bookingApiService.rebook(
        bookingId: widget.bookingId,
        scheduledAt: scheduledAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(ApiErrorHandler.message(error))),
          );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(errorMessage!, textAlign: TextAlign.center),
              ),
            );
          }

          final currentBooking = booking!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                currentBooking.serviceName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              Text(
                '${currentBooking.servicePrice.toStringAsFixed(0)} MMK',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),

              _DetailRow(
                label: 'Status',
                value: currentBooking.status.replaceAll('_', ' ').toUpperCase(),
              ),
              _DetailRow(
                label: 'Schedule',
                value: _formatDateTime(currentBooking.scheduledAt),
              ),
              _DetailRow(label: 'Phone', value: currentBooking.phone),
              _DetailRow(label: 'Address', value: currentBooking.address),

              if (currentBooking.customerNote != null)
                _DetailRow(label: 'Note', value: currentBooking.customerNote!),

              if (currentBooking.status == 'completed') ...[
                const SizedBox(height: 4),
                if (currentBooking.review == null)
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : _leaveReview,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Rate this service'),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                      ),
                      title: Text(
                        'Your ${currentBooking.review!.rating}-star review',
                      ),
                      subtitle: Text(
                        'Status: ${currentBooking.review!.status.toUpperCase()}',
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : _bookAgain,
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Book this service again'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ServicePlansScreen(
                              bookingId: currentBooking.id,
                              serviceName: currentBooking.serviceName,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.autorenew_outlined),
                  label: const Text('Set maintenance reminder'),
                ),
              ],

              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingInteractionScreen(
                      bookingId: currentBooking.id,
                      isStaff: false,
                    ),
                  ),
                ),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Chat and service proof'),
              ),

              if (currentBooking.checkInCode != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined),
                            SizedBox(width: 8),
                            Text('Staff arrival check-in'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share this code only after the assigned staff member arrives.',
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          currentBooking.checkInCode!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (currentBooking.checkInCodeExpiresAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Expires ${_formatDateTime(currentBooking.checkInCodeExpiresAt!)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              if (currentBooking.timeline.isNotEmpty) ...[
                const SizedBox(height: 20),
                _TimelineSection(events: currentBooking.timeline),
              ],

              if (currentBooking.cancellationReason != null)
                _DetailRow(
                  label: 'Cancellation reason',
                  value: currentBooking.cancellationReason!,
                ),

              if (currentBooking.rejectionReason != null)
                _DetailRow(
                  label: 'Rejection reason',
                  value: currentBooking.rejectionReason!,
                ),

              if (['pending', 'assigned'].contains(currentBooking.status)) ...[
                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: isSubmitting ? null : cancelBooking,
                  icon: const Icon(Icons.cancel_outlined),
                  label: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel Booking'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<BookingTimelineEventModel> events;

  const _TimelineSection({required this.events});

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.circle, size: 10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (event.description != null) ...[
                            const SizedBox(height: 2),
                            Text(event.description!),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            _formatDateTime(event.occurredAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _CustomerCancelReasonDialog extends StatefulWidget {
  const _CustomerCancelReasonDialog();

  @override
  State<_CustomerCancelReasonDialog> createState() =>
      _CustomerCancelReasonDialogState();
}

class _CustomerCancelReasonDialogState
    extends State<_CustomerCancelReasonDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Booking'),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
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
        FilledButton(onPressed: _submit, child: const Text('Cancel Booking')),
      ],
    );
  }
}
