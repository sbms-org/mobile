import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/tenant_api.dart';
import '../../../../core/models/api_models.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'tenant_unit_details_page.dart';
import 'tenant_payment_upload_page.dart';

class TenantUnitsPage extends ConsumerStatefulWidget {
  const TenantUnitsPage({super.key});

  @override
  ConsumerState<TenantUnitsPage> createState() => _TenantUnitsPageState();
}

class _TenantUnitsPageState extends ConsumerState<TenantUnitsPage> {
  List<Unit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
        final response = await TenantApi.getMyUnits();
        if (mounted) {
          setState(() {
            _units = response.data ?? [];
            _isLoading = false;
          });
        }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load units');
      }
    }
  }


  int _getDaysUntilDue(DateTime? dueDate) {
    if (dueDate == null) return 999;
    return dueDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 200,
            showBackButton: false,
            title: l10n.myUnits,
            subtitle: l10n.activeRentals,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LinearProgressIndicator())
                : _units.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.home_1, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noUnitsAssigned,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.contactOwnerToAssign,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUnits,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _units.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _units.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Iconsax.home, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_units.length} ${l10n.units.toLowerCase()}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildUnitCard(_units[index], l10n);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Unit unit, L10n l10n) {
    // currency formatter
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final daysUntilDue = _getDaysUntilDue(unit.nextRentDueDate);
    final isDue = daysUntilDue <= 0;
    final isUpcoming = daysUntilDue > 0 && daysUntilDue <= 7;

    Color statusColor = AppColors.success;
    String statusText;
    IconData statusIcon = Iconsax.tick_circle;

    if (isDue) {
      statusColor = const Color(0xFFD94444);
      statusText = l10n.paymentDue;
      statusIcon = Iconsax.warning_2;
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = l10n.paymentDueInDays(daysUntilDue);
      statusIcon = Iconsax.clock;
    } else {
      // fallback while L10n generation catches up
      statusText = 'Active';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDue ? statusColor.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          width: isDue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDue ? statusColor : Colors.black).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.08),
                  statusColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Iconsax.home_2, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.unitNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Iconsax.building, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  unit.building?.name ?? 'N/A',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (unit.nextRentDueDate != null && (isDue || isUpcoming)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.calendar_tick, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 6),
                              Text(
                                l10n.nextDueDate(unit.nextRentDueDate!.day, unit.nextRentDueDate!.month),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Metadata Grid (3 columns now)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.wallet,
                        label: l10n.amountDue,
                        value: currencyFormat.format(unit.rentAmount),
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.calendar_1,
                        label: l10n.paymentCycle,
                        value: '${unit.paymentCycleMonths} ${l10n.months.toLowerCase()}',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.layer,
                        label: l10n.floor,
                        value: '${unit.floor ?? 0}',
                      ),
                    ),
                  ],
                ),
                if (isDue || isUpcoming) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.info_circle, color: statusColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isDue ? l10n.paymentDueToday : l10n.paymentDueInDays(daysUntilDue),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TenantUnitDetailsPage(
                            unitId: unit.id,
                            assignment: unit.assignmentId,
                            unitTitle: unit.unitNumber,
                            building: unit.building?.name ?? 'N/A',
                            rentAmount: unit.rentAmount,
                            paymentCycle: unit.paymentCycleMonths,
                            status: statusText,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.eye),
                    label: Text(l10n.viewDetails),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (isDue || isUpcoming) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantPaymentUploadPage(
                              unitId: unit.id,
                              assignmentId: unit.assignmentId!,
                              unitNumber: unit.unitNumber,
                              rentAmount: unit.rentAmount,
                              paymentCycleMonths: unit.paymentCycleMonths,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadUnits();
                          AppToast.success(context, l10n.receiptUploadedSuccess);
                        }
                      },
                      icon: const Icon(Iconsax.card),
                      label: Text(l10n.payNow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
