import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../shared/widgets/app_toast.dart';

class OwnerNotificationSettingsPage extends ConsumerStatefulWidget {
  const OwnerNotificationSettingsPage({super.key});

  @override
  ConsumerState<OwnerNotificationSettingsPage> createState() => _OwnerNotificationSettingsPageState();
}

class _OwnerNotificationSettingsPageState extends ConsumerState<OwnerNotificationSettingsPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmail() async {
    setState(() => _isLoading = true);
    try {
      final response = await OwnerApi.getProfile();
      if (response.success && mounted) {
        final email = response.data?['notification_email'];
        setState(() {
          _currentEmail = email;
          if (email != null) _emailController.text = email;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      final response = await OwnerApi.updateNotificationEmail(email);

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success) {
          setState(() => _currentEmail = email);
          AppToast.success(context, response.message);
        } else {
          AppToast.error(context, response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, 'Failed to update email');
      }
    }
  }

  Future<void> _removeEmail() async {
    final l10n = L10n.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.removeEmail),
        content: Text(l10n.removeEmailConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final response = await OwnerApi.updateNotificationEmail(null);
        if (mounted) {
          setState(() {
            _isSaving = false;
            _currentEmail = null;
            _emailController.clear();
          });
          if (response.success) {
            AppToast.success(context, 'Email removed successfully');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.error(context, 'Failed to remove email');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: l10n.notificationSettings,
            subtitle: l10n.manageNotificationPreferences,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(l10n),
                          const SizedBox(height: 24),
                          _buildEmailSection(l10n),
                          const SizedBox(height: 24),
                          _buildNotificationTypesSection(l10n),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.info_circle, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.notificationEmailInfo,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.emailAddress,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: l10n.enterEmailAddress,
            prefixIcon: const Icon(Iconsax.sms),
            suffixIcon: _currentEmail != null
                ? IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: _removeEmail,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                return l10n.invalidEmailFormat;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        if (_currentEmail != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.currentEmail}: $_currentEmail',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.tick_circle),
                      const SizedBox(width: 8),
                      Text(
                        l10n.saveEmail,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypesSection(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notificationTypes,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.notificationTypesInfo,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildNotificationTypeCard(
          icon: Iconsax.card,
          color: AppColors.primary,
          title: l10n.paymentNotifications,
          description: l10n.paymentNotificationsDesc,
        ),
        const SizedBox(height: 12),
        _buildNotificationTypeCard(
          icon: Iconsax.document_text,
          color: AppColors.success,
          title: l10n.receiptNotifications,
          description: l10n.receiptNotificationsDesc,
        ),
        const SizedBox(height: 12),
        _buildNotificationTypeCard(
          icon: Iconsax.building,
          color: Colors.blue,
          title: l10n.propertyNotifications,
          description: l10n.propertyNotificationsDesc,
        ),
        const SizedBox(height: 12),
        _buildNotificationTypeCard(
          icon: Iconsax.people,
          color: Colors.purple,
          title: l10n.tenantNotifications,
          description: l10n.tenantNotificationsDesc,
        ),
      ],
    );
  }

  Widget _buildNotificationTypeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
