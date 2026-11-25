import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/constants/app_colors.dart';
import 'tenant_home_page.dart';
import 'tenant_units_page.dart';
import 'tenant_payments_page.dart';
import 'tenant_notifications_page.dart';
import 'tenant_profile_page.dart';

class TenantMainPage extends ConsumerStatefulWidget {
  const TenantMainPage({super.key});

  @override
  ConsumerState<TenantMainPage> createState() => _TenantMainPageState();
}

class _TenantMainPageState extends ConsumerState<TenantMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TenantHomePage(),
    const TenantUnitsPage(),
    const TenantPaymentsPage(),
    const TenantNotificationsPage(),
    const TenantProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(icon: const Icon(Iconsax.home), label: l10n.home),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.building),
              label: l10n.myUnits,
            ),
            BottomNavigationBarItem(icon: const Icon(Iconsax.card), label: l10n.payments),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.notification),
              label: l10n.alerts,
            ),
            BottomNavigationBarItem(icon: const Icon(Iconsax.user), label: l10n.profile),
          ],
        ),
      ),
    );
  }
}
