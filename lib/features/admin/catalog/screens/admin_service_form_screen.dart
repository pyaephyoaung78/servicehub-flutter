import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_category_model.dart';
import '../models/admin_service_model.dart';
import '../services/admin_catalog_api_service.dart';

class AdminServiceFormScreen extends StatefulWidget {
  final AdminServiceModel? service;

  const AdminServiceFormScreen({
    this.service,
    super.key,
  });

  bool get isEditing => service != null;

  @override
  State<AdminServiceFormScreen> createState() =>
      _AdminServiceFormScreenState();
}

class _AdminServiceFormScreenState
    extends State<AdminServiceFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();

  late final AdminCatalogApiService apiService;

  List<AdminCategoryModel> categories = [];
  int? selectedCategoryId;

  bool isActive = true;
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(
      tokenStorage: TokenStorage(),
    );

    apiService = AdminCatalogApiService(
      apiClient: apiClient,
    );

    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final results = await apiService.getCategories(
        activeOnly: false,
      );

      final service = widget.service;

      if (!mounted) return;

      setState(() {
        categories = results;

        if (service != null) {
          selectedCategoryId = service.categoryId;
          nameController.text = service.name;
          descriptionController.text =
              service.description ?? '';
          priceController.text =
              service.basePrice.toStringAsFixed(2);
          durationController.text =
              service.estimatedDurationMinutes
                      ?.toString() ??
                  '';
          isActive = service.isActive;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load form data: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      return;
    }

    final price = double.parse(
      priceController.text.trim(),
    );

    final duration =
        durationController.text.trim().isEmpty
            ? null
            : int.parse(
                durationController.text.trim(),
              );

    setState(() {
      isSubmitting = true;
    });

    try {
      if (widget.isEditing) {
        await apiService.updateService(
          serviceId: widget.service!.id,
          categoryId: selectedCategoryId!,
          name: nameController.text.trim(),
          description: descriptionController.text,
          basePrice: price,
          estimatedDurationMinutes: duration,
          isActive: isActive,
        );
      } else {
        await apiService.createService(
          categoryId: selectedCategoryId!,
          name: nameController.text.trim(),
          description: descriptionController.text,
          basePrice: price,
          estimatedDurationMinutes: duration,
          isActive: isActive,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save service: $error',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Service'
              : 'Create Service',
        ),
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

          return Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (category) =>
                            DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(
                            category.name,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Select a category.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Enter a valid service name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Base price',
                    suffixText: 'MMK',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price = double.tryParse(
                      value?.trim() ?? '',
                    );

                    if (price == null || price < 0) {
                      return 'Enter a valid price.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText:
                        'Estimated duration',
                    suffixText: 'minutes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return null;
                    }

                    final duration = int.tryParse(
                      value!.trim(),
                    );

                    if (duration == null ||
                        duration < 1) {
                      return 'Enter a valid duration.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active service'),
                  value: isActive,
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed:
                      isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isEditing
                              ? 'Update Service'
                              : 'Create Service',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}