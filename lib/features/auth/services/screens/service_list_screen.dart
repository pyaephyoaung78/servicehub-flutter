import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/features/bookings/screens/create_booking_screen.dart';
import 'package:flutter_laravel_testing/features/bookings/retention/services/customer_retention_api_service.dart';

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
  late final CustomerRetentionApiService retentionApiService;

  bool isLoading = true;
  String? errorMessage;

  List<ServiceCategoryModel> categories = [];
  List<ServiceModel> services = [];

  int? selectedCategoryId;
  Set<int> favoriteServiceIds = {};
  final Set<int> changingFavoriteIds = {};

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    serviceApiService = ServiceApiService(apiClient: apiClient);
    retentionApiService = CustomerRetentionApiService(apiClient: apiClient);

    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        serviceApiService.getCategories(),
        serviceApiService.getServices(serviceCategoryId: selectedCategoryId),
        retentionApiService.getFavoriteServices(),
      ]);
      final fetchedCategories = results[0] as List<ServiceCategoryModel>;
      final fetchedServices = results[1] as List<ServiceModel>;
      final favoriteServices = results[2] as List<ServiceModel>;

      setState(() {
        categories = fetchedCategories;
        services = fetchedServices;
        favoriteServiceIds = favoriteServices
            .map((service) => service.id)
            .toSet();
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

  Future<void> _toggleFavorite(ServiceModel service) async {
    if (changingFavoriteIds.contains(service.id)) return;
    setState(() => changingFavoriteIds.add(service.id));

    try {
      final isFavorite = await retentionApiService.toggleFavorite(service.id);
      if (!mounted) return;
      setState(() {
        if (isFavorite) {
          favoriteServiceIds.add(service.id);
        } else {
          favoriteServiceIds.remove(service.id);
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not update favourites: $error')),
          );
      }
    } finally {
      if (mounted) setState(() => changingFavoriteIds.remove(service.id));
    }
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${service.basePrice.toStringAsFixed(0)} MMK',
                                      ),
                                      const Icon(Icons.chevron_right, size: 18),
                                    ],
                                  ),
                                  IconButton(
                                    tooltip:
                                        favoriteServiceIds.contains(service.id)
                                        ? 'Remove from favourites'
                                        : 'Save to favourites',
                                    onPressed:
                                        changingFavoriteIds.contains(service.id)
                                        ? null
                                        : () => _toggleFavorite(service),
                                    icon:
                                        changingFavoriteIds.contains(service.id)
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            favoriteServiceIds.contains(
                                                  service.id,
                                                )
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                favoriteServiceIds.contains(
                                                  service.id,
                                                )
                                                ? Colors.redAccent
                                                : null,
                                          ),
                                  ),
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
