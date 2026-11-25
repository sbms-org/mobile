import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/app_toast.dart'; // used for notifications
import 'owner_unit_details_page.dart';

class OwnerBuildingUnitsPage extends ConsumerStatefulWidget {
  final String buildingId;
  const OwnerBuildingUnitsPage({super.key, required this.buildingId,});

  @override
  ConsumerState<OwnerBuildingUnitsPage> createState() => _OwnerBuildingUnitsPageState();
}

class _OwnerBuildingUnitsPageState extends ConsumerState<OwnerBuildingUnitsPage> {
  List<Unit> _units = [];
  Building? _building;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final buildingResponse = await OwnerApi.getBuilding(widget.buildingId);
      final unitsResponse = await OwnerApi.getBuildingUnits(widget.buildingId);
      if (mounted) {
        setState(() {
          _building = buildingResponse.data;
          _units = unitsResponse.data ?? [];
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
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 280,
            showBackButton: true,
            title: _building?.name ?? 'Building units',
            subtitle: _building != null ? '${_building!.name} units details' : 'Loading...',
          ),
          
          Transform.translate(
            offset: const Offset(0, -35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search MBTXXX',
                    prefixIcon: Icon(Icons.search),
                    filled: false,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _units.isEmpty
                    ? const Center(child: Text('No units found'))
                    : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _units.length,
              itemBuilder: (context, index) {
                final unit = _units[index];
                return _buildUnitCard(context, unit);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, Unit unit) {
    final l10n = L10n.of(context);
    final isOccupied = unit.status == 'occupied';
    final isVacant = unit.status == 'vacant';
    final isRentDue = unit.isRentDue;

    // color strip on left to indicate status
    final statusColor = isVacant
        ? AppColors.success
        : isOccupied
            ? AppColors.error
            : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OwnerUnitDetailsPage(unitId: unit.id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // status indicator bar
            Container(
              width: 6,
              height: double.infinity,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header row: unit number + rent due marker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          unit.unitNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary),
                        ),
                        if (isRentDue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.rentDueLabel,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // metadata chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (unit.rentAmount != null)
                          _infoChip(
                              Iconsax.wallet,
                              'ETB ${unit.rentAmount!.toStringAsFixed(0)}'),
                        if (unit.floor != null)
                          _infoChip(Iconsax.layer, 'Floor ${unit.floor}'),
                        if (unit.size != null)
                          _infoChip(Icons.square, unit.size!),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // due date indicator
                    if (unit.nextRentDueDate != null) ...[
                      Builder(builder: (context) {
                        final now = DateTime.now();
                        final diff = unit.nextRentDueDate!.difference(now).inDays;
                        Color chipColor;
                        String label;
                        if (diff < 0) {
                          chipColor = AppColors.error;
                          label = l10n.overdueShort(-diff);
                        } else if (diff <= 7) {
                          chipColor = Colors.orange;
                          label = l10n.dueInShort(diff);
                        } else {
                          chipColor = Colors.grey;
                          label = l10n.nextDueDate(unit.nextRentDueDate!.day, unit.nextRentDueDate!.month);
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: chipColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.calendar_tick, size: 14, color: chipColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: chipColor),
                                  ),
                                ],
                              ),
                            ),
                            if (diff <= 7) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await OwnerApi.notifyTenantDue(unit.id);
                                    AppToast.success(context, l10n.notify);
                                  } catch (e) {
                                    AppToast.error(context, l10n.genericError);
                                  }
                                },
                                child: Icon(Iconsax.notification, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                    const Spacer(),
                    // footer description & status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unit.description ??
                                unit.status.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
