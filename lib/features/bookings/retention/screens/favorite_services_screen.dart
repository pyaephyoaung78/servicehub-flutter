import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';
import 'package:flutter_laravel_testing/features/bookings/screens/create_booking_screen.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/services/models/service_model.dart';
import '../services/customer_retention_api_service.dart';

class FavoriteServicesScreen extends StatefulWidget {
  const FavoriteServicesScreen({super.key});

  @override
  State<FavoriteServicesScreen> createState() => _FavoriteServicesScreenState();
}

class _FavoriteServicesScreenState extends State<FavoriteServicesScreen> {
  late final CustomerRetentionApiService retentionApiService;
  List<ServiceModel> services = [];
  bool isLoading = true;
  String? errorMessage;
  final Set<int> changingServiceIds = {};

  @override
  void initState() {
    super.initState();
    retentionApiService = CustomerRetentionApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await retentionApiService.getFavoriteServices();
      if (!mounted) return;
      setState(() => services = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = ApiErrorHandler.message(error));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _removeFavorite(ServiceModel service) async {
    if (changingServiceIds.contains(service.id)) return;
    setState(() => changingServiceIds.add(service.id));

    try {
      final isFavorite = await retentionApiService.toggleFavorite(service.id);
      if (!mounted) return;
      if (!isFavorite) {
        setState(() => services.removeWhere((item) => item.id == service.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(ApiErrorHandler.message(error))),
          );
      }
    } finally {
      if (mounted) setState(() => changingServiceIds.remove(service.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite services')),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(errorMessage!, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              );
            }
            if (services.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text('Save services you want to book again later.'),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(service.name),
                    subtitle: Text(
                      '${service.basePrice.toStringAsFixed(0)} MMK${service.category == null ? '' : ' · ${service.category!.name}'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove from favourites',
                      onPressed: changingServiceIds.contains(service.id)
                          ? null
                          : () => _removeFavorite(service),
                      icon: changingServiceIds.contains(service.id)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CreateBookingScreen(service: service),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
