import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../servicebook/presentation/servicebook_home_page.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = [
      (
        UserRole.client,
        'Client',
        'Find nearby services, book work and share a request.',
        'ደንበኛ',
        'በአቅራቢያ አገልግሎት ያግኙ፣ ይያዙ እና የስራ ጥያቄ ያጋሩ።',
        Icons.search,
      ),
      (
        UserRole.individualProvider,
        'Individual provider',
        'Show your services, availability and manage bookings.',
        'ግለሰብ አገልግሎት ሰጪ',
        'አገልግሎቶችዎን እና ተገኝነትዎን ያሳዩ፣ ቦታ ማስያዣዎችን ያስተዳድሩ።',
        Icons.handyman_outlined,
      ),
      (
        UserRole.companyStaff,
        'Company staff',
        'Review company service information and bookings.',
        'የድርጅት ሰራተኛ',
        'የድርጅቱን አገልግሎት መረጃ እና ቦታ ማስያዣዎችን ይመልከቱ።',
        Icons.business_outlined,
      ),
      (
        UserRole.broker,
        'Broker',
        'Connect people with available local services.',
        'ደላላ',
        'ሰዎችን ከአካባቢያዊ አገልግሎቶች ጋር ያገናኙ።',
        Icons.handshake_outlined,
      ),
      (
        UserRole.supportAgent,
        'Support agent',
        'Access service activity and submit issue reports.',
        'የድጋፍ ሰራተኛ',
        'የአገልግሎት እንቅስቃሴን ይመልከቱ እና የችግር ሪፖርቶችን ይላኩ።',
        Icons.support_agent,
      ),
      (
        UserRole.administrator,
        'Administrator',
        'Review service activity and access safety tools.',
        'አስተዳዳሪ',
        'የአገልግሎት እንቅስቃሴን ይመልከቱ እና የደህንነት መሳሪያዎችን ይጠቀሙ።',
        Icons.admin_panel_settings_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ServiceBook')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            Localizations.localeOf(context).languageCode == 'am'
                ? 'እንኳን ወደ ServiceBook በደህና መጡ'
                : 'Welcome to ServiceBook',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'am'
                ? 'ለመቀጠል ሚናዎን ይምረጡ።'
                : 'Choose a role to continue.',
          ),
          const SizedBox(height: 16),
          for (final role in roles)
            Card(
              child: ListTile(
                leading: Icon(role.$6),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'am'
                      ? role.$4
                      : role.$2,
                ),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'am'
                      ? role.$5
                      : role.$3,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(userRoleProvider.notifier).setRole(role.$1);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ServiceBookHomePage(role: role.$1),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'am'
                ? 'ሚናዎች የሚመደቡት በተጠቃሚ መለያዎ ላይ ባለው ፈቃድ መሰረት ነው።'
                : 'Access is still enforced by your account permissions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
