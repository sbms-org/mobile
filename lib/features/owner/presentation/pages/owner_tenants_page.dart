import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import 'package:pm/shared/widgets/app_toast.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import 'owner_tenant_details_page.dart';

class OwnerTenantsPage extends StatefulWidget {
  const OwnerTenantsPage({super.key});

  @override
  State<OwnerTenantsPage> createState() => _OwnerTenantsPageState();
}

class _OwnerTenantsPageState extends State<OwnerTenantsPage> {
  List<TenantSummary> _tenants = [];
  List<TenantSummary> _filteredTenants = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final response = await OwnerApi.getTenants();
      if (response.success && response.data != null) {
        setState(() {
          _tenants = response.data!;
          _filteredTenants = _tenants;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to load tenants: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterTenants(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTenants = _tenants;
      } else {
        _filteredTenants = _tenants.where((tenant) {
          return tenant.fullname!.toLowerCase().contains(query.toLowerCase()) ||
              tenant.mobile!.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: l10n.tenants,
            subtitle: l10n.searchTenants,
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

          // Search Bar
          Transform.translate(
            offset: const Offset(0, -35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: _filterTenants,
                  decoration: InputDecoration(
                    hintText: l10n.searchByMobileOrName,
                    prefixIcon: const Icon(Icons.search),
                    filled: false,
                  ),
                ),
              ),
            ),
          ),

          // Tenants List
          Expanded(
            child: _isLoading
                ? const Center(child: LinearProgressIndicator())
                : _filteredTenants.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? l10n.noResults : l10n.noResults,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 0,
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        itemCount: _filteredTenants.length,
                        itemBuilder: (context, index) {
                          return _buildTenantCard(context, _filteredTenants[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, TenantSummary tenant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerTenantDetailsPage(
              tenant: tenant,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Iconsax.user, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.fullname!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.call,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tenant.mobile!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.home, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${tenant.unitCount} unit${tenant.unitCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ETB ${tenant.totalRent.toStringAsFixed(0)}/${tenant.paymentCycle}mo',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tenant.hasDueRent) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Has overdue rent',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Center(
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
