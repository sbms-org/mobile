import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class TenantAlertsPage extends ConsumerWidget {
  const TenantAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 180,
            showBackButton: true,
            title: l10n.alerts,
            actions: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.setting_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAlertItem(
                  icon: Iconsax.notification,
                  iconColor: AppColors.primary,
                  title: 'New Property Added Under Your Number!',
                  subtitle:
                      'Tenant +25194 123 1321 Account\nAdded to SREG299 Property',
                  time: '02:32 - Yekatit 14',
                ),
                const Divider(height: 32),
                _buildAlertItem(
                  icon: Iconsax.star,
                  iconColor: AppColors.primary,
                  title: 'Security Update!',
                  subtitle:
                      'There is a security update, you must\nupdate the app to v3.24.6',
                  time: '03:31 - Yekatit 11',
                ),
                const SizedBox(height: 32),
                const Text(
                  'Yesterday',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAlertItem(
                  icon: Iconsax.money,
                  iconColor: AppColors.primary,
                  title: 'Rent Received! Thanks!',
                  subtitle:
                      'Due rent is paid for Yekatit_Miyazia Month\nTotal MBR417 Rent ON 02-Yekatit-2018',
                  time: '06:53 - Yekatit 02',
                ),
                const Divider(height: 32),
                _buildAlertItem(
                  icon: Iconsax.notification,
                  iconColor: AppColors.primary,
                  title: 'Pending Receipt Review...',
                  subtitle:
                      'Uploaded Rent Reciept Month Yekatit-\nMiyazia for MBT417 Rent Pending\nApproval from Owner.',
                  time: '08:12 - Yekatit 01',
                ),
                const Divider(height: 32),
                _buildAlertItem(
                  icon: Iconsax.money,
                  iconColor: AppColors.primary,
                  title: 'Rent Received! Thanks!',
                  subtitle:
                      'Due rent is paid for Hedar-Tirr Month Total\nMBR417 Rent on 01-Hedar-2018',
                  time: '12:01 - Hedar 03',
                ),
                const Divider(height: 32),
                _buildAlertItem(
                  icon: Iconsax.notification,
                  iconColor: AppColors.primary,
                  title: 'Pending Receipt Review...',
                  subtitle:
                      'Uploaded Rent Reciept Month Hedar-\nTirr for MBT417 Rent Pending\nApproval from Owner',
                  time: '08:12 - Hedar 01',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
