import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_category_model.dart';
import '../services/admin_catalog_api_service.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final AdminCategoryModel? category;

  const AdminCategoryFormScreen({
    this.category,
    super.key,
  });

  bool get isEditing => category != null;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState
    extends State<AdminCategoryFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  late final AdminCatalogApiService apiService;

  bool isActive = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(
      tokenStorage: TokenStorage(),
    );

    apiService = AdminCatalogApiService(
      apiClient: apiClient,
    );

    final category = widget.category;

    if (category != null) {
      nameController.text = category.name;
      descriptionController.text =
          category.description ?? '';
      isActive = category.isActive;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      if (widget.isEditing) {
        await apiService.updateCategory(
          categoryId: widget.category!.id,
          name: nameController.text.trim(),
          description: descriptionController.text,
          isActive: isActive,
        );
      } else {
        await apiService.createCategory(
          name: nameController.text.trim(),
          description: descriptionController.text,
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
            'Failed to save category: $error',
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
              ? 'Edit Category'
              : 'Create Category',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Enter a valid category name.';
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
            SwitchListTile(
              title: const Text('Active'),
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
              onPressed: isSubmitting ? null : submit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.isEditing
                          ? 'Update Category'
                          : 'Create Category',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}