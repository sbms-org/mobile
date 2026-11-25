import 'package:flutter/material.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import 'owner_payment_history_page.dart';
import 'assign_tenant_page.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../widgets/update_unit_bottom_sheet.dart';

class OwnerUnitDetailsPage extends StatefulWidget {
  final String unitId;

  const OwnerUnitDetailsPage({super.key, required this.unitId});

  @override
  State<OwnerUnitDetailsPage> createState() => _OwnerUnitDetailsPageState();
}

class _OwnerUnitDetailsPageState extends State<OwnerUnitDetailsPage> {
  Unit? _unit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    setState(() => _isLoading = true);
    try {
      final response = await OwnerApi.getUnit(widget.unitId);
      if (response.success && response.data != null) {
        setState(() {
          _unit = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load unit: $e');
      }
    }
  }

  Future<void> _showAddTenantDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTenantPage(
          unitId: widget.unitId,
          unitNumber: _unit!.unitNumber,
        ),
      ),
    );

    if (result == true) {
      _loadUnit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LinearProgressIndicator()));
    }

    if (_unit == null) {
      final l10n = L10n.of(context);
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.noData),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }

    final isVacant = _unit!.status == 'vacant';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 350,
              showBackButton: true,
              title: _unit!.unitNumber,
              subtitle: 'View property and tenant details',
              actions: [
                if (isVacant)
                  GestureDetector(
                    onTap: _showAddTenantDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Iconsax.user_add,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add Tenant',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              child: Transform.translate(
                offset: const Offset(0, 40),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildHeaderInfoRow(
                        'Building',
                        _unit!.building?.name ?? 'N/A',
                        Iconsax.building,
                      ),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow(
                        'Property Type',
                        _unit!.building?.propertyType ?? 'N/A',
                        Iconsax.grammerly,
                      ),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow(
                        'Payment Cycle',
                        'Every ${_unit!.paymentCycleMonths} Month${_unit!.paymentCycleMonths > 1 ? 's' : ''}',
                        Iconsax.calendar,
                      ),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow(
                        'Per Cycle Payment',
                        _unit!.rentAmount.toStringAsFixed(2),
                        Iconsax.card,
                      ),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow(
                        'Occupancy status',
                        isVacant ? 'Vacant' : 'Occupied',
                        Iconsax.user,
                        iconColor: isVacant
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      // const SizedBox(height: 8),
                      // if (_unit!.nextRentDueDate != null) ...[
                      //   Builder(builder: (ctx) {
                      //     final now = DateTime.now();
                      //     final diff = _unit!.nextRentDueDate!.difference(now).inDays;
                      //     String dueText;
                      //     Color color = Colors.grey;
                      //     if (diff < 0) {
                      //       dueText = 'Overdue ${-diff}d';
                      //       color = AppColors.error;
                      //     } else if (diff <= 7) {
                      //       dueText = 'Due in ${diff}d';
                      //       color = Colors.orange;
                      //     } else {
                      //       dueText = 'Next: ${_unit!.nextRentDueDate!.day}/${_unit!.nextRentDueDate!.month}';
                      //     }
                      //     return Row(
                      //       children: [
                      //         Expanded(
                      //           child: Text(
                      //             dueText,
                      //             style: TextStyle(
                      //                 fontSize: 13,
                      //                 fontWeight: FontWeight.w600,
                      //                 color: color),
                      //           ),
                      //         ),
                      //         if (diff <= 7)
                      //           IconButton(
                      //             icon: const Icon(Iconsax.notification),
                      //             color: AppColors.primary,
                      //             onPressed: () async {
                      //               try {
                      //                 await OwnerApi.notifyTenantDue(widget.unitId);
                      //                 AppToast.success(ctx, 'Tenant notified');
                      //               } catch (e) {
                      //                 AppToast.error(ctx, 'Notification failed');
                      //               }
                      //             },
                      //           ),
                      //       ],
                      //     );
                      //   }),
                      //   const SizedBox(height: 8),
                      // ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 8),
                      if (_unit!.nextRentDueDate != null) ...[
                        Builder(builder: (ctx) {
                          final l10n = L10n.of(ctx);
                          final now = DateTime.now();
                          final diff = _unit!.nextRentDueDate!.difference(now).inDays;
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
                            label = l10n.nextDueDate(_unit!.nextRentDueDate!.day, _unit!.nextRentDueDate!.month);
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: chipColor.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.calendar_tick, size: 14, color: chipColor),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: chipColor),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

            // warning banner when rent is due soon/overdue
            if (!isVacant && _unit!.nextRentDueDate != null) ...[
              Builder(builder: (ctx) {
                final l10n = L10n.of(ctx);
                final now = DateTime.now();
                final diff = _unit!.nextRentDueDate!.difference(now).inDays;
                if (diff <= 7) {
                  final bool overdue = diff < 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: overdue
                            ? AppColors.error.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (overdue ? AppColors.error : Colors.orange).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.notification,
                            color: overdue ? AppColors.error : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              overdue
                                  ? l10n.rentOverdueBanner(-diff)
                                  : l10n.rentDueBanner(diff),
                              style: TextStyle(
                                color: overdue ? AppColors.error : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await OwnerApi.notifyTenantDue(widget.unitId);
                                  AppToast.success(ctx, l10n.notify);
                                } catch (e) {
                                  AppToast.error(ctx, l10n.genericError);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: overdue ? AppColors.error : AppColors.primary,
                              ),
                              child: Text(l10n.notify),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              ],
                  if (!isVacant && _unit!.tenant != null) ...[
                    const Text(
                      'Tenant Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.profile_circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _unit!.tenant!.fullname,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _unit!.tenant!.mobile,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  const Text(
                    'Account Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // allow owner to edit unit metadata
                  _buildDetailActionCard(
                    context,
                    Iconsax.edit,
                    'Edit Unit Details',
                    'Modify unit information',
                    onTap: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => UpdateUnitBottomSheet(
                          unitId: widget.unitId,
                          unitNumber: _unit!.unitNumber,
                          floor: _unit!.floor,
                          rentAmount: _unit!.rentAmount,
                          size: _unit!.size,
                          description: _unit!.description,
                          paymentCycleMonths: _unit!.paymentCycleMonths,
                        ),
                      );
                      if (result == true) {
                        _loadUnit();
                      }
                    },
                  ),
                  if (!isVacant)
                    _buildDetailActionCard(
                      context,
                      Iconsax.dollar_square,
                      'Tenant Payment History',
                      'View past transactions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerPaymentHistoryPage(
                              unitId: widget.unitId,
                              unitNumber: _unit!.unitNumber,
                            ),
                          ),
                        );
                      },
                    ),
                  if (!isVacant) const SizedBox(height: 12),
                  // _buildDetailActionCard(
                  //   context,
                  //   Iconsax.card,
                  //   'Update Payment Cycle',
                  //   'Set custom payment cycle',
                  //   onTap: _updatePaymentCycle,
                  // ),
                  const SizedBox(height: 12),
                  // _buildDetailActionCard(
                  //   context,
                  //   Icons.payment,
                  //   'Property History',
                  //   'View all tenants history',
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(
    String label,
    String value,
    IconData icon, {
    Color iconColor = Colors.black45,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: iconColor, size: 14),
      ],
    );
  }

  Widget _buildDetailActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.success, size: 24),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
