import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/features/admin/bookings/screens/admin_booking_list_screen.dart';
import 'package:flutter_laravel_testing/features/admin/catalog/screens/admin_catalog_screen.dart';
import 'package:flutter_laravel_testing/features/admin/staff/screens/admin_staff_list_screen.dart';
import 'package:flutter_laravel_testing/features/bookings/screens/my_bookings_screen.dart';
import 'package:flutter_laravel_testing/features/staff/assignments/screens/staff_assignment_list_screen.dart';
import 'package:flutter_laravel_testing/features/staff/profile/screens/staff_profile_screen.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/services/screens/service_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceHub'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome, ${user?.name ?? 'User'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Role: ${user?.role ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),

          if (user?.role == 'admin') ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Manage bookings'),
                subtitle: const Text('View booking requests and assign staff.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminBookingListScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Manage staff'),
                subtitle: const Text(
                  'Create staff, assign skills and manage availability.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminStaffListScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage catalog'),
                subtitle: const Text(
                  'Manage service categories, prices and durations.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminCatalogScreen(),
                    ),
                  );
                },
              ),
            ),
          ],

          if (user?.role == 'staff') ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text('My assignments'),
                subtitle: const Text(
                  'Review assigned jobs and update progress.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StaffAssignmentListScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Staff profile'),
                subtitle: const Text(
                  'View your skills and control availability.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StaffProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],

          if (user?.role == 'customer') ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.home_repair_service),
                title: const Text('Browse services'),
                subtitle: const Text(
                  'View available service categories and services.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ServiceListScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('My bookings'),
                subtitle: const Text(
                  'View your service requests and current status.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyBookingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
