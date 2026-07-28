import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/admin_staff_model.dart';
import '../services/admin_staff_api_service.dart';
import 'admin_staff_form_screen.dart';

class AdminStaffListScreen extends StatefulWidget {
  const AdminStaffListScreen({super.key});

  @override
  State<AdminStaffListScreen> createState() =>
      _AdminStaffListScreenState();
}

class _AdminStaffListScreenState
    extends State<AdminStaffListScreen> {
  late final AdminStaffApiService apiService;

  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  String selectedFilter = 'all';
  List<AdminStaffModel> staff = [];

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

    loadStaff();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadStaff() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    bool? isActive;
    bool? isAvailable;

    switch (selectedFilter) {
      case 'active':
        isActive = true;
        break;

      case 'available':
        isActive = true;
        isAvailable = true;
        break;

      case 'unavailable':
        isActive = true;
        isAvailable = false;
        break;

      case 'inactive':
        isActive = false;
        break;
    }

    try {
      final results = await apiService.getStaff(
        search: searchController.text.trim(),
        isActive: isActive,
        isAvailable: isAvailable,
      );

      if (!mounted) return;

      setState(() {
        staff = results;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load staff: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openCreateScreen() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AdminStaffFormScreen(),
      ),
    );

    if (changed == true) {
      await loadStaff();
    }
  }

  Future<void> openEditScreen(
    AdminStaffModel member,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminStaffFormScreen(
          staffProfileId: member.id,
        ),
      ),
    );

    if (changed == true) {
      await loadStaff();
    }
  }

  Future<void> deactivateStaff(
    AdminStaffModel member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate staff'),
          content: Text(
            'Deactivate ${member.name}? They will no '
            'longer receive new assignments.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await apiService.deactivateStaff(member.id);

      if (!mounted) return;

      showMessage(
        '${member.name} was deactivated.',
      );

      await loadStaff();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Failed to deactivate staff: $error',
      );
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

  String formatAvailability(
    AdminStaffModel member,
  ) {
    if (!member.isActive) {
      return 'INACTIVE';
    }

    return member.isAvailable
        ? 'AVAILABLE'
        : 'UNAVAILABLE';
  }

  @override
  Widget build(BuildContext context) {
    const filters = [
      'all',
      'active',
      'available',
      'unavailable',
      'inactive',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateScreen,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => loadStaff(),
              decoration: InputDecoration(
                hintText: 'Search name, email or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: loadStaff,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];

                return ChoiceChip(
                  label: Text(filter.toUpperCase()),
                  selected: selectedFilter == filter,
                  onSelected: (_) async {
                    setState(() {
                      selectedFilter = filter;
                    });

                    await loadStaff();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadStaff,
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
                        const SizedBox(height: 170),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: loadStaff,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (staff.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text('No staff found.'),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      90,
                    ),
                    itemCount: staff.length,
                    itemBuilder: (context, index) {
                      final member = staff[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name[0]
                                      .toUpperCase()
                                  : 'S',
                            ),
                          ),
                          title: Text(member.name),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(member.email),
                              Text(member.phone),
                              Text(
                                'Skills: '
                                '${member.services.length}',
                              ),
                              Text(
                                formatAvailability(member),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                openEditScreen(member);
                              }

                              if (action == 'deactivate') {
                                deactivateStaff(member);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              if (member.isActive)
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text('Deactivate'),
                                ),
                            ],
                          ),
                          onTap: () =>
                              openEditScreen(member),
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