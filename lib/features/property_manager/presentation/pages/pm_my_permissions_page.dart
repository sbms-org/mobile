import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/api/property_manager_api.dart';
import '../../../../shared/widgets/app_toast.dart';

class PmMyPermissionsPage extends ConsumerStatefulWidget {
  const PmMyPermissionsPage({super.key});

  @override
  ConsumerState<PmMyPermissionsPage> createState() =>
      _PmMyPermissionsPageState();
}

class _PmMyPermissionsPageState extends ConsumerState<PmMyPermissionsPage> {
  List<PmBuildingPermission> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final response = await PropertyManagerApi.getMyPermissions();
      if (mounted) {
        setState(() {
          _permissions = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load permissions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 240,
            showBackButton: true,
            title: 'My Permissions',
            subtitle: 'Permissions assigned by your owner',
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _permissions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadPermissions,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      itemCount: _permissions.length,
                      itemBuilder: (context, index) {
                        return _buildPermissionCard(_permissions[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.shield_slash,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Permissions Assigned',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your owner has not assigned\nany buildings to you yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(PmBuildingPermission perm) {
    final permItems = [
      _PermItem(
        'Dashboard Access',
        'View property analytics & data',
        Iconsax.chart_2,
        perm.canViewDashboard,
      ),
      _PermItem(
        'Manage Units',
        'Edit unit info and pricing',
        Iconsax.house,
        perm.canManageUnits,
      ),
      _PermItem(
        'Manage Tenants',
        'Add and manage tenant information',
        Iconsax.people,
        perm.canManageTenants,
      ),
      _PermItem(
        'Manage Receipts',
        'Approve or reject payment receipts',
        Iconsax.receipt,
        perm.canManageReceipts,
      ),
      _PermItem(
        'Export Reports',
        'Generate and download reports',
        Iconsax.document_text,
        perm.canExportReports,
      ),
    ];

    final grantedCount = permItems.where((p) => p.granted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Building header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.building,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perm.buildingName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        perm.buildingType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$grantedCount/${permItems.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Permission rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: permItems.map((p) => _buildPermissionRow(p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(_PermItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.granted
                  ? AppColors.success.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 16,
              color: item.granted ? AppColors.success : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: item.granted ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.granted ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: item.granted
                  ? AppColors.success
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.granted ? Icons.check : Icons.close,
              size: 12,
              color: item.granted ? Colors.white : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool granted;

  const _PermItem(this.title, this.subtitle, this.icon, this.granted);
}
