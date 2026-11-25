import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/constants/app_colors.dart';
import 'owner_home_page.dart';
import 'owner_buildings_page.dart';
import 'owner_tenants_page.dart';
import 'owner_analytics_page.dart';
import 'owner_profile_page.dart';

class OwnerMainPage extends ConsumerStatefulWidget {
  const OwnerMainPage({super.key});

  @override
  ConsumerState<OwnerMainPage> createState() => _OwnerMainPageState();
}

class _OwnerMainPageState extends ConsumerState<OwnerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OwnerHomePage(),
    const OwnerBuildingsPage(),
    const OwnerTenantsPage(),
    const OwnerAnalyticsPage(),
    const OwnerProfilePage(),
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
              blurRadius: 20,
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
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(icon: const Icon(Iconsax.home), label: l10n.home),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.building),
              label: l10n.buildings,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.profile_2user),
              label: l10n.tenants,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.chart_2),
              label: l10n.analytics,
            ),
            BottomNavigationBarItem(icon: const Icon(Iconsax.user), label: l10n.profile),
          ],
        ),
      ),
    );
  }
}
