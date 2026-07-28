import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_category_model.dart';
import '../models/admin_service_model.dart';
import '../services/admin_catalog_api_service.dart';
import 'admin_category_form_screen.dart';
import 'admin_service_form_screen.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() =>
      _AdminCatalogScreenState();
}

class _AdminCatalogScreenState
    extends State<AdminCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  late final AdminCatalogApiService apiService;

  bool isLoading = true;
  String? errorMessage;

  List<AdminCategoryModel> categories = [];
  List<AdminServiceModel> services = [];

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      vsync: this,
    );

    apiService = AdminCatalogApiService(
      apiClient: ApiClient(
        tokenStorage: TokenStorage(),
      ),
    );

    loadCatalog();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> loadCatalog() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        apiService.getCategories(
          activeOnly: false,
        ),
        apiService.getServices(
          activeOnly: false,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        categories =
            results[0] as List<AdminCategoryModel>;
        services =
            results[1] as List<AdminServiceModel>;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load catalog: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openCategoryForm({
    AdminCategoryModel? category,
  }) async {
    final changed =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminCategoryFormScreen(
          category: category,
        ),
      ),
    );

    if (changed == true) {
      await loadCatalog();
    }
  }

  Future<void> openServiceForm({
    AdminServiceModel? service,
  }) async {
    final changed =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminServiceFormScreen(
          service: service,
        ),
      ),
    );

    if (changed == true) {
      await loadCatalog();
    }
  }

  Future<void> deactivateCategory(
    AdminCategoryModel category,
  ) async {
    await apiService.deactivateCategory(
      category.id,
    );

    await loadCatalog();
  }

  Future<void> deactivateService(
    AdminServiceModel service,
  ) async {
    await apiService.deactivateService(
      service.id,
    );

    await loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Catalog'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tabController.index == 0) {
            openCategoryForm();
          } else {
            openServiceForm();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (errorMessage != null) {
            return Center(
              child: Text(errorMessage!),
            );
          }

          return TabBarView(
            controller: tabController,
            children: [
              RefreshIndicator(
                onRefresh: loadCatalog,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    90,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category =
                        categories[index];

                    return Card(
                      child: ListTile(
                        title: Text(category.name),
                        subtitle: Text(
                          category.description ??
                              'No description',
                        ),
                        leading: Icon(
                          category.isActive
                              ? Icons.check_circle
                              : Icons.block,
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              openCategoryForm(
                                category: category,
                              );
                            }

                            if (action == 'deactivate') {
                              deactivateCategory(
                                category,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (category.isActive)
                              const PopupMenuItem(
                                value: 'deactivate',
                                child:
                                    Text('Deactivate'),
                              ),
                          ],
                        ),
                        onTap: () =>
                            openCategoryForm(
                          category: category,
                        ),
                      ),
                    );
                  },
                ),
              ),
              RefreshIndicator(
                onRefresh: loadCatalog,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    90,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];

                    return Card(
                      child: ListTile(
                        title: Text(service.name),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.category?.name ??
                                  'No category',
                            ),
                            Text(
                              '${service.basePrice.toStringAsFixed(0)} MMK',
                            ),
                            if (service
                                    .estimatedDurationMinutes !=
                                null)
                              Text(
                                '${service.estimatedDurationMinutes} minutes',
                              ),
                          ],
                        ),
                        leading: Icon(
                          service.isActive
                              ? Icons.check_circle
                              : Icons.block,
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              openServiceForm(
                                service: service,
                              );
                            }

                            if (action == 'deactivate') {
                              deactivateService(
                                service,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (service.isActive)
                              const PopupMenuItem(
                                value: 'deactivate',
                                child:
                                    Text('Deactivate'),
                              ),
                          ],
                        ),
                        onTap: () => openServiceForm(
                          service: service,
                        ),
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