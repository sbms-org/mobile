import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/features/owner/presentation/pages/owner_add_building_page.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_property_managers_page.dart';
import 'owner_payment_methods_page.dart';
import 'owner_notification_settings_page.dart';
import '../../../auth/presentation/pages/phone_number_page.dart';

class OwnerProfilePage extends ConsumerStatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  ConsumerState<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends ConsumerState<OwnerProfilePage> {
  String _name = 'Loading...';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await SecureStorageService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _phone = userData['mobile'] ?? '';
        _name = userData['name'] ?? 'Owner';
      });
    }
  }

  Future<void> _handleLogout() async {
    final l10n = L10n.of(context)!;
    final confirmed = await AppDialogs.showConfirm(
      context,
      title: l10n.logout,
      l10n.logoutConfirm,
      confirmText: l10n.logout,
      cancelText: l10n.cancel,
    );

    if (confirmed == true && mounted) {
      await SecureStorageService.clearAll();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PhoneNumberPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 250,
              title: l10n.ownerProfile,
              actions: [
                GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerNotificationsPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Badge(
                    isLabelVisible: false,
                    child: Icon(Iconsax.notification, color: Colors.white),
                  ),
                ),
              ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _phone,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D61E7), Color(0xFF4A8BFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.autoNotifyRentals,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sendRentDueRemainders,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  _buildSectionTitle(l10n.accountDetails),
                  _buildProfileItem(
                    icon: Iconsax.user_tick,
                    title: l10n.viewPropertyManagers,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerPropertyManagersPage(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Iconsax.card,
                    title: l10n.paymentsMethods,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerPaymentMethodsPage(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Iconsax.building,
                    title: l10n.registerABuilding,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerAddBuildingPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.settings),
                  _buildProfileItem(
                    icon: Iconsax.notification,
                    title: l10n.notificationSettings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerNotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildLanguageSelector(context, l10n),
                  _buildProfileItem(
                    icon: Iconsax.logout,
                    title: l10n.logout,
                    textColor: AppColors.error,
                    onTap: _handleLogout,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: textColor ?? AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, L10n l10n) {
    final currentLocale = ref.watch(localeProvider);
    final languageDisplay = currentLocale.languageCode == 'en' ? 'English' : 'አማርኛ';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Iconsax.global, color: AppColors.primary),
        title: Text(
          l10n.language,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageDisplay,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () => AppDialogs.showLanguageSelector(context),
      ),
    );
  }
}
