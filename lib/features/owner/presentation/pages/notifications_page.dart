import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: l10n.notifications,
            actions: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.setting, color: Colors.white),
              ),
            ],
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Today',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  context,
                  Iconsax.notification,
                  'Tenant Access Revoked!',
                  'Tenant +25194 123 1321 Account Revoked For MBT217 Property',
                  '10:26 - Tirr 24',
                  AppColors.primary,
                ),
                const Divider(),
                _buildNotificationItem(
                  context,
                  Iconsax.star,
                  'Security Update!',
                  'There is a security update, you must update the app to v3.24.6',
                  '09:45 - Tirr 13',
                  AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Yesterday',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  context,
                  Iconsax.dollar_circle,
                  'Rent Received! Thanks!',
                  'Due rent is paid for Yekatit_Miyazia Month Total MBR417 Rent ON 02-Yekatit-2018',
                  '04:59 - Tehsas 27',
                  AppColors.primary,
                ),
                const Divider(),
                _buildNotificationItem(
                  context,
                  Iconsax.notification,
                  'Pending Receipt Review...',
                  'Review the uploaded Rent Receipt Month Yekatit-Miyazia for MBT417 Rent, Reject if it is false receipt.',
                  '02:22 - Tehsas 18',
                  AppColors.primary,
                  showArrow: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    String title,
    String message,
    String time,
    Color iconColor, {
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 20),
              child: Icon(Icons.arrow_forward, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
