import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/models/service_model.dart';
import '../services/booking_api_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final ServiceModel service;

  const CreateBookingScreen({
    required this.service,
    super.key,
  });

  @override
  State<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState
    extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  late final BookingApiService bookingApiService;

  DateTime? selectedDateTime;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
    );

    bookingApiService = BookingApiService(
      apiClient: apiClient,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _selectDateAndTime() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 9,
        minute: 0,
      ),
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      _showMessage(
        'Please choose a future date and time.',
      );
      return;
    }

    setState(() {
      selectedDateTime = dateTime;
    });
  }

  Future<void> _submitBooking() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDateTime == null) {
      _showMessage(
        'Please select a booking date and time.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final booking = await bookingApiService.createBooking(
        serviceId: widget.service.id,
        scheduledAt: selectedDateTime!,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        customerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully.'),
        ),
      );

      Navigator.of(context).pop(booking);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        context.read<AuthProvider>().errorMessage ??
            _extractError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String _extractError(Object error) {
    return error
        .toString()
        .replaceFirst('DioException [bad response]: ', '')
        .replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${service.basePrice.toStringAsFixed(0)} MMK',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        if (service.description != null) ...[
                          const SizedBox(height: 8),
                          Text(service.description!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : _selectDateAndTime,
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                  ),
                  label: Text(
                    selectedDateTime == null
                        ? 'Select date and time'
                        : _formatDateTime(
                            selectedDateTime!,
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Contact phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Phone number is required.';
                    }

                    if (phone.length < 7) {
                      return 'Enter a valid phone number.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Service address',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final address = value?.trim() ?? '';

                    if (address.isEmpty) {
                      return 'Service address is required.';
                    }

                    if (address.length < 5) {
                      return 'Enter a more complete address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : _submitBooking,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}