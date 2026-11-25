import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pm/l10n/generated/L10n.dart';
import 'package:pm/shared/widgets/app_toast.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/tenant_api.dart';

class TenantNotificationsPage extends ConsumerStatefulWidget {
  const TenantNotificationsPage({super.key});

  @override
  ConsumerState<TenantNotificationsPage> createState() => _TenantNotificationsPageState();
}

class _TenantNotificationsPageState extends ConsumerState<TenantNotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await TenantApi.getNotifications();
      if (response.success && mounted) {
        setState(() {
          _notifications = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Error loading notifications: $e');
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await TenantApi.markNotificationRead(notificationId);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await TenantApi.markAllNotificationsRead();
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: l10n.notifications,
            subtitle: unreadCount > 0 ? '$unreadCount ${l10n.notifications}' : l10n.noData,
            actions: [
              if (unreadCount > 0)
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.tick_circle, color: Colors.white),
                  ),
                ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.notification, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No notifications',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            final isRead = notification['is_read'] ?? false;
                            final type = notification['type'] ?? 'general';
                            final createdAt = DateTime.parse(notification['created_at']);

                            return _buildNotificationItem(
                              context,
                              notification['id'],
                              _getIconForType(type),
                              notification['title'] ?? 'Notification',
                              notification['message'] ?? '',
                              createdAt,
                              _getColorForType(type),
                              isRead,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment_due':
        return Iconsax.dollar_circle;
      case 'lease_expiring':
        return Iconsax.calendar;
      case 'maintenance':
        return Iconsax.setting;
      default:
        return Iconsax.notification;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'payment_due':
        return const Color(0xFFD94444);
      case 'lease_expiring':
        return Colors.orange;
      case 'maintenance':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String id,
    IconData icon,
    String title,
    String message,
    DateTime createdAt,
    Color iconColor,
    bool isRead,
  ) {
    final dateFormat = DateFormat('HH:mm - MMM dd');

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : iconColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : iconColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      dateFormat.format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
