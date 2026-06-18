import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/staff_profile_model.dart';
import '../services/staff_profile_api_service.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState
    extends State<StaffProfileScreen> {
  late final StaffProfileApiService apiService;

  StaffProfileModel? profile;

  bool isLoading = true;
  bool isUpdatingAvailability = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
    );

    apiService = StaffProfileApiService(
      apiClient: apiClient,
    );

    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await apiService.getProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        profile = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Failed to load staff profile: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateAvailability(
    bool isAvailable,
  ) async {
    final currentProfile = profile;

    if (currentProfile == null) {
      return;
    }

    if (!currentProfile.isActive) {
      showMessage(
        'Inactive staff cannot change availability.',
      );
      return;
    }

    setState(() {
      isUpdatingAvailability = true;

      // Immediate UI feedback.
      profile = currentProfile.copyWith(
        isAvailable: isAvailable,
      );
    });

    try {
      final updatedProfile =
          await apiService.updateAvailability(
        isAvailable: isAvailable,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        profile = updatedProfile;
      });

      showMessage(
        isAvailable
            ? 'You are now available for assignments.'
            : 'You are now unavailable for new assignments.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Restore previous value if API request fails.
      setState(() {
        profile = currentProfile;
      });

      showMessage(
        'Failed to update availability: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingAvailability = false;
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
        title: const Text('Staff Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: loadProfile,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final currentProfile = profile!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    currentProfile.name.isNotEmpty
                        ? currentProfile.name[0]
                            .toUpperCase()
                        : 'S',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  currentProfile.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 4),

                Text(
                  currentProfile.email,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Available for assignments',
                    ),
                    subtitle: Text(
                      currentProfile.isActive
                          ? currentProfile.isAvailable
                              ? 'You can receive new assignments.'
                              : 'You will not receive new assignments.'
                          : 'Your staff account is inactive.',
                    ),
                    value:
                        currentProfile.isAvailable,
                    onChanged:
                        !currentProfile.isActive ||
                                isUpdatingAvailability
                            ? null
                            : updateAvailability,
                    secondary:
                        isUpdatingAvailability
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                currentProfile
                                        .isAvailable
                                    ? Icons
                                        .check_circle_outline
                                    : Icons
                                        .pause_circle_outline,
                              ),
                  ),
                ),

                const SizedBox(height: 16),

                _ProfileRow(
                  label: 'Phone',
                  value: currentProfile.phone,
                ),

                _ProfileRow(
                  label: 'Employment status',
                  value: currentProfile.isActive
                      ? 'ACTIVE'
                      : 'INACTIVE',
                ),

                if (currentProfile.bio != null &&
                    currentProfile.bio!.isNotEmpty)
                  _ProfileRow(
                    label: 'Bio',
                    value: currentProfile.bio!,
                  ),

                const SizedBox(height: 12),

                Text(
                  'Service Skills',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 10),

                if (currentProfile.services.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No service skills assigned.',
                      ),
                    ),
                  )
                else
                  ...currentProfile.services.map(
                    (service) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.build_outlined,
                        ),
                        title: Text(service.name),
                        subtitle:
                            service.categoryName != null
                                ? Text(
                                    service.categoryName!,
                                  )
                                : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge,
          ),
          const SizedBox(height: 4),
          Text(value),
          const Divider(height: 20),
        ],
      ),
    );
  }
}