import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pm/core/services/secure_storage_service.dart';
import 'package:pm/features/tenant/presentation/pages/tenant_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/tenant_api.dart';
import '../../../../core/models/api_models.dart';
import 'tenant_units_page.dart';
import 'tenant_unit_details_page.dart';
import 'tenant_payments_page.dart';

class TenantHomePage extends ConsumerStatefulWidget {
  const TenantHomePage({super.key});

  @override
  ConsumerState<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends ConsumerState<TenantHomePage> {
  String _name = '';
  List<Unit> _units = [];
  List<dynamic> _duePayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await SecureStorageService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _name = userData['name'] ?? 'Tenant';
      });
    }
      final results = await Future.wait([
        TenantApi.getMyUnits(),
        TenantApi.getDuePayments(),
      ]);

      final unitsResponse = results[0] as ApiResponse<List<Unit>>;
      final paymentsResponse = results[1];

      if (mounted) {
        setState(() {
          _units = unitsResponse.data ?? [];
          _duePayments = paymentsResponse.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalDueAmount {
    return _duePayments.fold(0.0, (sum, p) {
      final amount = p['amount'];
      if (amount is String) {
        return sum + (double.tryParse(amount) ?? 0.0);
      }
      return sum + (amount ?? 0.0);
    });
  }

  DateTime? get _earliestDueDate {
    if (_duePayments.isEmpty) return null;
    return DateTime.parse(_duePayments.first['dueDate']);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CurvedSection(
                      height: 280,
                      title: _name.isEmpty ? 'Tenant' : _name,
                      subtitle: l10n.goodMorning,
                      actions: [
                        GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TenantNotificationsPage(),
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

                    // Quick Actions Card
                    Transform.translate(
                      offset: const Offset(0, -60),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.home,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildQuickAction(
                                  context,
                                  Iconsax.home,
                                  l10n.myUnits,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TenantUnitsPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  Iconsax.card,
                                  l10n.payNow,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TenantPaymentsPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildQuickAction(
                                  context,
                                  Iconsax.card_edit,
                                  l10n.payments,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TenantPaymentsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Due Rent Card
                    if (_duePayments.isNotEmpty)
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD94444),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'ETB ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          l10n.currentDueRent,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text(
                                          'ETB ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        Text(
                                          currencyFormat.format(_totalDueAmount).replaceAll('ETB ', ''),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_earliestDueDate != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Iconsax.calendar,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Due: ${DateFormat('dd MMM yyyy').format(_earliestDueDate!)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const TenantPaymentsPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFFD94444),
                                        minimumSize: const Size(double.infinity, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Iconsax.card),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.payNow,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Outstanding Balance
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDEDE),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD94444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Iconsax.info_circle,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.totalOutstandingBalance,
                                            style: const TextStyle(
                                              color: Color(0xFFD94444),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                'ETB ',
                                                style: TextStyle(
                                                  color: Color(0xFFD94444),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(_totalDueAmount).replaceAll('ETB ', ''),
                                                style: const TextStyle(
                                                  color: Color(0xFFD94444),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            l10n.settlePayments,
                                            style: const TextStyle(
                                              color: Color(0xFFD94444),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // My Units Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.myUnits,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TenantUnitsPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.viewAll,
                                  style: const TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          if (_units.isEmpty)
                            Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            Icon(
                              Iconsax.home,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Units Assigned',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                          else
                            ..._units.take(2).map((unit) => _buildUnitCard(
                                  context,
                                  unit.unitNumber,
                                  unit.building?.name ?? 'Building',
                                  'Floor ${unit.floor ?? 0}',
                                  unit.rentAmount,
                                  unit.paymentCycleMonths,
                                  _getDueStatus(unit),
                                  unit.id,
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getDueStatus(Unit unit) {
    if (unit.nextRentDueDate == null) return '';
    final daysUntilDue = unit.nextRentDueDate!.difference(DateTime.now()).inDays;
    if (daysUntilDue <= 0) return 'Rent is Due';
    if (daysUntilDue <= 5) return 'Due Soon';
    return '';
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    String title,
    String building,
    String details,
    double rent,
    int paymentCycle,
    String status,
    String unitId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantUnitDetailsPage(
              unitId: unitId,
              unitTitle: title,
              building: building,
              rentAmount: rent,
              paymentCycle: paymentCycle,
              status: status,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                title.contains('MBT') ? Iconsax.computing : Iconsax.home,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD94444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        building,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Subcity Bole, Addis Ababa',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'ETB ',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '$rent/$paymentCycle Months',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
