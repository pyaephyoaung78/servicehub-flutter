import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_booking_model.dart';
import '../services/admin_booking_api_service.dart';
import 'admin_booking_detail_screen.dart';

class AdminBookingListScreen extends StatefulWidget {
  const AdminBookingListScreen({super.key});

  @override
  State<AdminBookingListScreen> createState() => _AdminBookingListScreenState();
}

class _AdminBookingListScreenState extends State<AdminBookingListScreen> {
  late final AdminBookingApiService apiService;

  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  String selectedStatus = 'pending';
  List<AdminBookingModel> bookings = [];

  final statuses = const [
    'all',
    'pending',
    'assigned',
    'accepted',
    'on_the_way',
    'in_progress',
    'completed',
    'cancelled',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    apiService = AdminBookingApiService(apiClient: apiClient);

    loadBookings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await apiService.getBookings(
        status: selectedStatus == 'all' ? null : selectedStatus,
        search: searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        bookings = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load bookings: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> selectStatus(String status) async {
    setState(() {
      selectedStatus = status;
    });

    await loadBookings();
  }

  String formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute';
  }

  String formatStatus(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bookings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => loadBookings(),
              decoration: InputDecoration(
                hintText: 'Search customer, service, phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: loadBookings,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];

                return ChoiceChip(
                  label: Text(formatStatus(status)),
                  selected: selectedStatus == status,
                  onSelected: (_) => selectStatus(status),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadBookings,
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (errorMessage != null) {
                    return ListView(
                      children: [
                        const SizedBox(height: 150),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: loadBookings,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (bookings.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No bookings found.')),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(booking.serviceName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(booking.customerName),
                              Text(formatDateTime(booking.scheduledAt)),
                              if (booking.latestAssignment != null)
                                Text(
                                  'Assigned: '
                                  '${booking.latestAssignment!.staffName}',
                                ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(formatStatus(booking.status)),
                          ),
                          onTap: () async {
                            final changed = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => AdminBookingDetailScreen(
                                      bookingId: booking.id,
                                    ),
                                  ),
                                );

                            if (changed == true) {
                              await loadBookings();
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
