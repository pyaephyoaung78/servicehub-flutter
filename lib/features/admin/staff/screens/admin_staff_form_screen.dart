import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/services/models/service_model.dart';
import '../models/admin_staff_model.dart';
import '../services/admin_staff_api_service.dart';

class AdminStaffFormScreen extends StatefulWidget {
  final int? staffProfileId;

  const AdminStaffFormScreen({
    this.staffProfileId,
    super.key,
  });

  bool get isEditing => staffProfileId != null;

  @override
  State<AdminStaffFormScreen> createState() =>
      _AdminStaffFormScreenState();
}

class _AdminStaffFormScreenState
    extends State<AdminStaffFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();

  late final AdminStaffApiService apiService;

  bool isLoading = true;
  bool isSubmitting = false;
  bool hidePassword = true;

  bool isActive = true;
  bool isAvailable = true;

  String? errorMessage;

  List<ServiceModel> services = [];
  final Set<int> selectedServiceIds = {};

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
    );

    apiService = AdminStaffApiService(
      apiClient: apiClient,
    );

    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    bioController.dispose();

    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final serviceResults =
          await apiService.getServices();

      AdminStaffModel? member;

      if (widget.isEditing) {
        member = await apiService.getStaffProfile(
          widget.staffProfileId!,
        );
      }

      if (!mounted) return;

      setState(() {
        services = serviceResults;

        if (member != null) {
          nameController.text = member.name;
          emailController.text = member.email;
          phoneController.text = member.phone;
          bioController.text = member.bio ?? '';

          isActive = member.isActive;
          isAvailable = member.isAvailable;

          selectedServiceIds.addAll(
            member.services.map(
              (service) => service.id,
            ),
          );
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
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedServiceIds.isEmpty) {
      showMessage(
        'Select at least one service skill.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      if (widget.isEditing) {
        await apiService.updateStaff(
          staffProfileId: widget.staffProfileId!,
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          bio: bioController.text,
          isActive: isActive,
          isAvailable:
              isActive ? isAvailable : false,
          serviceIds:
              selectedServiceIds.toList(),
        );
      } else {
        await apiService.createStaff(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          phone: phoneController.text.trim(),
          bio: bioController.text,
          isActive: isActive,
          isAvailable:
              isActive ? isAvailable : false,
          serviceIds:
              selectedServiceIds.toList(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Staff updated successfully.'
                : 'Staff created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Failed to save staff: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Staff'
              : 'Create Staff',
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon:
                        Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Enter a valid name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty ||
                        !email.contains('@')) {
                      return 'Enter a valid email.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                if (!widget.isEditing) ...[
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    textInputAction:
                        TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      border:
                          const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword =
                                !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 8) {
                        return 'Password must contain at least 8 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon:
                        Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 7) {
                      return 'Enter a valid phone number.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: bioController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Active staff'),
                  subtitle: const Text(
                    'Inactive staff cannot receive or manage work.',
                  ),
                  value: isActive,
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            isActive = value;

                            if (!value) {
                              isAvailable = false;
                            }
                          });
                        },
                ),

                SwitchListTile(
                  title: const Text('Available'),
                  subtitle: const Text(
                    'Available staff can receive new assignments.',
                  ),
                  value: isAvailable,
                  onChanged: !isActive || isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            isAvailable = value;
                          });
                        },
                ),

                const SizedBox(height: 20),

                Text(
                  'Service Skills',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(height: 8),

                ...services.map(
                  (service) {
                    final selected =
                        selectedServiceIds.contains(
                      service.id,
                    );

                    return CheckboxListTile(
                      value: selected,
                      title: Text(service.name),
                      subtitle:
                          service.category != null
                              ? Text(
                                  service.category!.name,
                                )
                              : null,
                      onChanged: isSubmitting
                          ? null
                          : (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedServiceIds.add(
                                    service.id,
                                  );
                                } else {
                                  selectedServiceIds.remove(
                                    service.id,
                                  );
                                }
                              });
                            },
                    );
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
                              ? 'Update Staff'
                              : 'Create Staff',
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