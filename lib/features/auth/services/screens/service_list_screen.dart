import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/features/bookings/screens/create_booking_screen.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';
import '../services/service_api_service.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late final ServiceApiService serviceApiService;

  bool isLoading = true;
  String? errorMessage;

  List<ServiceCategoryModel> categories = [];
  List<ServiceModel> services = [];

  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    serviceApiService = ServiceApiService(apiClient: apiClient);

    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedCategories = await serviceApiService.getCategories();
      final fetchedServices = await serviceApiService.getServices(
        serviceCategoryId: selectedCategoryId,
      );

      setState(() {
        categories = fetchedCategories;
        services = fetchedServices;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load services: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    setState(() {
      selectedCategoryId = categoryId;
    });

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(errorMessage!),
              ),
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: selectedCategoryId == null,
                        onSelected: (_) => selectCategory(null),
                      ),
                    ),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: selectedCategoryId == category.id,
                          onSelected: (_) => selectCategory(category.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: services.isEmpty
                    ? const Center(child: Text('No services found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(service.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (service.category != null)
                                    Text('Category: ${service.category!.name}'),
                                  if (service.description != null)
                                    Text(service.description!),
                                  if (service.estimatedDurationMinutes != null)
                                    Text(
                                      'Duration: ${service.estimatedDurationMinutes} min',
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${service.basePrice.toStringAsFixed(0)} MMK',
                                  ),
                                  const Icon(Icons.chevron_right, size: 18),
                                ],
                              ),
                              onTap: () async {
                                final booking = await Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => CreateBookingScreen(
                                          service: service,
                                        ),
                                      ),
                                    );

                                if (!context.mounted || booking == null) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Your booking is now pending.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
