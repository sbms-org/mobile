import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/services/secure_storage_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_building_units_page.dart';

class OwnerBuildingsPage extends ConsumerStatefulWidget {
  const OwnerBuildingsPage({super.key});

  @override
  ConsumerState<OwnerBuildingsPage> createState() => _OwnerBuildingsPageState();
}

class _OwnerBuildingsPageState extends ConsumerState<OwnerBuildingsPage> {
  List<Building> _buildings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) return;
      
      final response = await OwnerApi.getBuildings(userId);
      if (mounted) {
        setState(() {
          _buildings = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final totalBuildings = _buildings.length;
    final totalUnits = _buildings.fold<int>(0, (sum, b) => sum + b.totalUnits);
    final avgFloors = totalBuildings > 0
        ? (_buildings.fold<int>(0, (sum, b) => sum + (b.totalFloors ?? 0)) / totalBuildings).round()
        : 0;

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 240,
            title: l10n.buildings,
            subtitle: l10n.viewAll,
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
          
          Expanded(
            child: _isLoading
                ? const Center(child: LinearProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // show grid when there are more than two buildings, otherwise keep the
                  // horizontal scroll for a more compact layout on small lists.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (_buildings.isEmpty) {
                        return Center(child: Text(l10n.noData));
                      }

                      if (_buildings.length > 2) {
                        // wrap will flow cards into multiple rows automatically
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _buildings.map((building) {
                            // use roughly half width minus spacing
                            final cardWidth = (constraints.maxWidth - 16) / 2;
                            return SizedBox(
                              width: cardWidth,
                              child: _buildBuildingCard(
                                context,
                                building.name,
                                building.propertyType,
                                '${building.totalFloors ?? 0} Floors',
                                '${building.totalUnits} Units',
                                building.id,
                              ),
                            );
                          }).toList(),
                        );
                      }

                      // one or two buildings: keep horizontal scroll
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _buildings.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final building = _buildings[index];
                            return _buildBuildingCard(
                              context,
                              building.name,
                              building.propertyType,
                              '${building.totalFloors ?? 0} Floors',
                              '${building.totalUnits} Units',
                              building.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Number of Buildings', '$totalBuildings'),
                        const Divider(height: 32),
                        _buildSummaryRow('Average floors per buildings', '$avgFloors'),
                        const Divider(height: 32),
                        _buildSummaryRow('Total rental units', '$totalUnits'),
                        const Divider(height: 32),
                        _buildSummaryRow('Rented out', '0%', isValueBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(BuildContext context, String name, String type, String floors, String rented, String buildingId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OwnerBuildingUnitsPage(buildingId: buildingId,)),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Add this line
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Iconsax.building_3, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Iconsax.layer, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  floors,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            // const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.tick_circle, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    rented,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isValueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 15),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 15,
            fontWeight: isValueBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
