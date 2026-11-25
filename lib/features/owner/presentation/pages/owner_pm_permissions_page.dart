import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/services/secure_storage_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class OwnerPmPermissionsPage extends ConsumerStatefulWidget {
  final PropertyManager pm;

  const OwnerPmPermissionsPage({super.key, required this.pm});

  @override
  ConsumerState<OwnerPmPermissionsPage> createState() =>
      _OwnerPmPermissionsPageState();
}

class _OwnerPmPermissionsPageState
    extends ConsumerState<OwnerPmPermissionsPage> {
  List<Building> _allBuildings = [];
  Map<String, Map<String, bool>> _assignments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) return;

      final buildingsResponse = await OwnerApi.getBuildings(userId);
      _allBuildings = buildingsResponse.data ?? [];

      // Pre-fill assignments
      if (widget.pm.assignments != null) {
        for (var a in widget.pm.assignments!) {
          _assignments[a.buildingId] = Map<String, bool>.from(a.permissions);
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load buildings');
      }
    }
  }

  void _toggleBuilding(String buildingId, bool selected) {
    setState(() {
      if (selected) {
        _assignments[buildingId] = {
          'can_view_dashboard': true,
          'can_manage_units': true,
          'can_manage_tenants': true,
          'can_manage_receipts': true,
          'can_export_reports': true,
        };
      } else {
        _assignments.remove(buildingId);
      }
    });
  }

  void _updatePermission(String buildingId, String key, bool value) {
    setState(() {
      if (_assignments.containsKey(buildingId)) {
        _assignments[buildingId]![key] = value;
      }
    });
  }

  Future<void> _saveAssignments() async {
    setState(() => _isLoading = true);
    try {
      final payload = _assignments.entries
          .map((e) => {'buildingId': e.key, 'permissions': e.value})
          .toList();

      final response = await OwnerApi.updatePMAssignments(
        widget.pm.id,
        payload,
      );
      if (mounted) {
        if (response.success) {
          AppToast.success(context, 'Permissions updated successfully');
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
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: 'Permissions',
            subtitle: widget.pm.fullname,
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: _allBuildings.length,
                    itemBuilder: (context, index) {
                      final building = _allBuildings[index];
                      final isSelected = _assignments.containsKey(building.id);

                      return _buildBuildingPermissionCard(building, isSelected);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveAssignments,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Save Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBuildingPermissionCard(Building building, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              building.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              building.propertyType,
              style: const TextStyle(fontSize: 12),
            ),
            leading: Icon(
              Iconsax.building,
              color: isSelected ? AppColors.success : Colors.grey,
            ),
            trailing: Switch(
              value: isSelected,
              activeColor: AppColors.success,
              onChanged: (val) => _toggleBuilding(building.id, val),
            ),
          ),
          if (isSelected) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPermissionToggle(
                    building.id,
                    'can_view_dashboard',
                    'Dashboard',
                    'Access to property analytics',
                  ),
                  _buildPermissionToggle(
                    building.id,
                    'can_manage_units',
                    'Units',
                    'Manage rooms and pricing',
                  ),
                  _buildPermissionToggle(
                    building.id,
                    'can_manage_tenants',
                    'Tenants',
                    'Manage tenant information',
                  ),
                  _buildPermissionToggle(
                    building.id,
                    'can_manage_receipts',
                    'Receipts',
                    'Approve/Reject payments',
                  ),
                  _buildPermissionToggle(
                    building.id,
                    'can_export_reports',
                    'Reports',
                    'Generate and export reports',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionToggle(
    String buildingId,
    String key,
    String title,
    String subtitle,
  ) {
    final val = _assignments[buildingId]?[key] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: val,
              activeColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (v) => _updatePermission(buildingId, key, v ?? false),
            ),
          ),
        ],
      ),
    );
  }
}
