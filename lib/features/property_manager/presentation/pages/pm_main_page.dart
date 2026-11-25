import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../owner/presentation/pages/owner_buildings_page.dart';
import '../../../owner/presentation/pages/owner_tenants_page.dart';
import 'pm_home_page.dart';
import 'pm_profile_page.dart';

class PropertyManagerMainPage extends ConsumerStatefulWidget {
  const PropertyManagerMainPage({super.key});

  @override
  ConsumerState<PropertyManagerMainPage> createState() =>
      _PropertyManagerMainPageState();
}

class _PropertyManagerMainPageState
    extends ConsumerState<PropertyManagerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const PmHomePage(),
    const OwnerBuildingsPage(),
    const OwnerTenantsPage(),
    const PropertyManagerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.building),
            label: l10n.buildings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.people),
            label: l10n.tenants,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.user),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
