import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../bookings/screens/booking_detail_screen.dart';
import '../models/app_notification_model.dart';
import '../services/notification_api_service.dart';

class NotificationListScreen extends StatefulWidget {
  final bool opensCustomerBooking;

  const NotificationListScreen({this.opensCustomerBooking = true, super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final NotificationApiService notificationApiService;

  List<AppNotificationModel> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    notificationApiService = NotificationApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await notificationApiService.getNotifications();
      if (!mounted) return;

      setState(() {
        notifications = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load notifications: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    if (!notification.isRead) {
      await notificationApiService.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        notifications = notifications
            .map(
              (item) => item.id == notification.id
                  ? AppNotificationModel(
                      id: item.id,
                      type: item.type,
                      title: item.title,
                      body: item.body,
                      bookingId: item.bookingId,
                      readAt: DateTime.now(),
                      createdAt: item.createdAt,
                    )
                  : item,
            )
            .toList();
      });
    }

    if (!mounted ||
        !widget.opensCustomerBooking ||
        notification.bookingId == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(bookingId: notification.bookingId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadNotifications,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (notifications.isEmpty) {
            return const Center(child: Text('No booking updates yet.'));
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Card(
                  color: notification.isRead
                      ? null
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      notification.type == 'service_completed'
                          ? Icons.task_alt_outlined
                          : Icons.notifications_active_outlined,
                    ),
                    title: Text(notification.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.body.isNotEmpty)
                          Text(notification.body),
                        const SizedBox(height: 4),
                        Text(_formatDateTime(notification.createdAt)),
                      ],
                    ),
                    onTap: () => _openNotification(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
