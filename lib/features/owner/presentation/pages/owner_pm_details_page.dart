import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_pm_permissions_page.dart';

class OwnerPmDetailsPage extends ConsumerStatefulWidget {
  final String pmId;

  const OwnerPmDetailsPage({super.key, required this.pmId});

  @override
  ConsumerState<OwnerPmDetailsPage> createState() => _OwnerPmDetailsPageState();
}

class _OwnerPmDetailsPageState extends ConsumerState<OwnerPmDetailsPage> {
  PropertyManager? _pm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPmDetails();
  }

  Future<void> _loadPmDetails() async {
    try {
      final response = await OwnerApi.getPropertyManagerDetails(widget.pmId);
      if (mounted) {
        setState(() {
          _pm = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load details');
      }
    }
  }

  Future<void> _revokeAccess() async {
    setState(() => _isLoading = true);
    try {
      final response = await OwnerApi.revokePropertyManager(widget.pmId);
      if (mounted) {
        if (response.success) {
          AppToast.success(context, 'Access revoked successfully');
          Navigator.pop(context, true);
        } else {
          setState(() => _isLoading = false);
          AppToast.error(context, response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_pm == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Property Manager not found')),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 350,
              showBackButton: true,
              title: _pm!.fullname,
              subtitle: 'Property Manager Details',
              child: Transform.translate(
                offset: const Offset(0, 40),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildHeaderInfoRow('Mobile', _pm!.mobile, Iconsax.call),
                      const SizedBox(height: 12),
                      _buildHeaderInfoRow(
                        'Role',
                        'Property Manager',
                        Iconsax.user_tag,
                      ),
                      const SizedBox(height: 12),
                      _buildHeaderInfoRow(
                        'Status',
                        _pm!.status,
                        Iconsax.tick_circle,
                      ),
                      const SizedBox(height: 12),
                      _buildHeaderInfoRow(
                        'Assigned Buildings',
                        '${_pm!.assignments?.length ?? 0}',
                        Iconsax.building,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Management Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailActionCard(
                    context,
                    Iconsax.setting_2,
                    'Assign Buildings & Permissions',
                    'Control which properties and features this manager can access',
                    color: AppColors.primary,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OwnerPmPermissionsPage(pm: _pm!),
                        ),
                      );
                      if (result == true) _loadPmDetails();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildDetailActionCard(
                    context,
                    Iconsax.user_remove,
                    'Revoke Access',
                    'Immediately stop this manager from accessing your properties',
                    color: Colors.red,
                    onTap: () => _showRevokeBottomSheet(context),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Current Assignments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_pm!.assignments == null || _pm!.assignments!.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No specific buildings assigned.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Manager has access to ALL buildings by default.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._pm!.assignments!.map((a) => _buildAssignmentCard(a)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(PropertyManagerAssignment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.building, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                a.buildingName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: a.permissions.entries.where((e) => e.value).map((e) {
              return Chip(
                label: Text(
                  e.key.replaceAll('can_', '').replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: AppColors.success.withOpacity(0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showRevokeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              const Icon(Iconsax.danger, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Revoke Access',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to revoke ${_pm!.fullname}\'s access to manage your properties?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _revokeAccess();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Yes, Revoke Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
