import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/notification_api.dart';
import '../../../../core/models/notification_preferences.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'email_notification_settings_page.dart';

class EnhancedNotificationSettingsPage extends ConsumerStatefulWidget {
  const EnhancedNotificationSettingsPage({super.key});

  @override
  ConsumerState<EnhancedNotificationSettingsPage> createState() => _EnhancedNotificationSettingsPageState();
}

class _EnhancedNotificationSettingsPageState extends ConsumerState<EnhancedNotificationSettingsPage> {
  NotificationPreferences? _preferences;
  bool _isLoading = true;

  final notificationTypeLabels = {
    'payment_due': {'title': 'Payment Due Reminders', 'icon': Iconsax.card, 'color': AppColors.primary},
    'payment_overdue': {'title': 'Overdue Payment Alerts', 'icon': Iconsax.danger, 'color': Colors.red},
    'receipt_uploaded': {'title': 'Receipt Uploaded', 'icon': Iconsax.document_upload, 'color': Colors.blue},
    'receipt_approved': {'title': 'Receipt Approved', 'icon': Iconsax.tick_circle, 'color': AppColors.success},
    'receipt_rejected': {'title': 'Receipt Rejected', 'icon': Iconsax.close_circle, 'color': Colors.orange},
    'lease_expiring': {'title': 'Lease Expiring', 'icon': Iconsax.calendar, 'color': Colors.purple},
    'lease_update': {'title': 'Lease Updates', 'icon': Iconsax.document_text, 'color': Colors.indigo},
    'maintenance_scheduled': {'title': 'Maintenance Scheduled', 'icon': Iconsax.setting_2, 'color': Colors.teal},
    'owner_message': {'title': 'Messages from Owner', 'icon': Iconsax.message, 'color': Colors.pink},
    'building_announcement': {'title': 'Building Announcements', 'icon': Iconsax.notification, 'color': Colors.amber},
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await NotificationApi.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load preferences');
      }
    }
  }

  Future<void> _updateGlobalSetting(String type, bool value) async {
    try {
      if (type == 'in_app') {
        await NotificationApi.updateGlobalPreferences(inAppEnabled: value);
      } else if (type == 'push') {
        await NotificationApi.updateGlobalPreferences(pushEnabled: value);
      } else if (type == 'email') {
        await NotificationApi.updateGlobalPreferences(emailEnabled: value);
      }
      _loadPreferences();
    } catch (e) {
      AppToast.error(context, 'Failed to update setting');
    }
  }

  Future<void> _updateTypeSetting(String notifType, String channel, bool value) async {
    try {
      await NotificationApi.updateTypePreference(notifType, channel, value);
      _loadPreferences();
    } catch (e) {
      AppToast.error(context, 'Failed to update setting');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 200,
            showBackButton: true,
            title: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildGlobalSettings(),
                      const SizedBox(height: 24),
                      if (_preferences!.emailEnabled) ...[
                        _buildEmailSettingsButton(),
                        const SizedBox(height: 24),
                      ],
                      _buildNotificationTypes(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGlobalToggle('In-App Notifications', Iconsax.mobile, _preferences!.inAppEnabled, 'in_app'),
            const Divider(height: 24),
            _buildGlobalToggle('Push Notifications', Iconsax.notification, _preferences!.pushEnabled, 'push'),
            const Divider(height: 24),
            _buildGlobalToggle('Email Notifications', Iconsax.sms, _preferences!.emailEnabled, 'email'),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalToggle(String label, IconData icon, bool value, String type) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        Switch(
          value: value,
          onChanged: (newValue) => _updateGlobalSetting(type, newValue),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildEmailSettingsButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmailNotificationSettingsPage()),
      ),
      icon: const Icon(Iconsax.sms),
      label: const Text('Email Settings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Types',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...notificationTypeLabels.entries.map((entry) {
          final pref = _preferences!.notificationTypes[entry.key];
          if (pref == null) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNotificationTypeCard(entry.key, entry.value, pref),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNotificationTypeCard(String type, Map<String, dynamic> info, NotificationTypePreference pref) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (info['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 20),
        ),
        title: Text(info['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildChannelToggle('In-App', pref.inApp, () => _updateTypeSetting(type, 'in_app', !pref.inApp)),
                const SizedBox(height: 8),
                _buildChannelToggle('Push', pref.push, () => _updateTypeSetting(type, 'push', !pref.push)),
                const SizedBox(height: 8),
                _buildChannelToggle('Email', pref.email, () => _updateTypeSetting(type, 'email', !pref.email)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelToggle(String label, bool value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              value ? Iconsax.tick_circle : Iconsax.close_circle,
              color: value ? AppColors.primary : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.primary : Colors.grey[600],
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
