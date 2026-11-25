import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';

import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/api/owner_api.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class OwnerTenantDetailsPage extends StatefulWidget {
  final TenantSummary tenant;

  const OwnerTenantDetailsPage({
    super.key,
    required this.tenant,
  });

  @override
  OwnerTenantDetailsPageState createState() => OwnerTenantDetailsPageState();
}

class OwnerTenantDetailsPageState extends State<OwnerTenantDetailsPage> {
  late TenantSummary tenant;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    tenant = widget.tenant;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final resp = await OwnerApi.getTenantDetails(tenant.id);
      if (resp.success && resp.data != null) {
        setState(() {
          tenant = resp.data!;
        });
      }
    } catch (e) {
      // ignore - we'll just keep initial data
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _cycleText(int months) {
  if (months == -1) return 'Varies';
  if (months <= 1) return 'Monthly';
  return 'Every $months Month${months > 1 ? 's' : ''}';
}

  double _dueRateSuccess() {
    final units = tenant.units ?? [];
    if (units.isEmpty) return 100.0;
    final now = DateTime.now();
    final overdue = units.where((u) {
      if (u.nextRentDueDate == null) return false;
      return u.nextRentDueDate!.isBefore(now);
    }).length;
    return ((units.length - overdue) / units.length) * 100;
  }

  double _totalCycleRent() {
    return tenant.totalUnitsRent;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            CurvedSection(
              height: 350,
              showBackButton: true,
              title: tenant.fullname ?? '',
              subtitle: 'View tenant details and rented units',
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
                      'Total rented units',
                      '${tenant.unitCount}',
                      Iconsax.building_3,
                    ),
                    const SizedBox(height: 8),
                    _buildHeaderInfoRow(
                      'Payment Cycle',
                      _cycleText(tenant.paymentCycle),
                      Iconsax.calendar,
                    ),
                    const SizedBox(height: 8),
                    _buildHeaderInfoRow(
                      'Total cycle for all units',
                      currencyFormat.format(_totalCycleRent()),
                      Iconsax.wallet_2,
                    ),
                    const SizedBox(height: 8),
                    _buildHeaderInfoRow(
                      'Due rate success',
                      '${_dueRateSuccess().toStringAsFixed(0)}%',
                      Iconsax.trend_up,
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
                    'Tenant Contact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            Iconsax.user,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.fullname ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tenant.mobile ?? '',
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
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(String label, String value, IconData icon) {
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
        Icon(icon, color: Colors.black45, size: 14),
      ],
    );
  }
}
