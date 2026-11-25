import 'package:flutter/material.dart';
import 'package:pm/shared/widgets/app_toast.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../owner/presentation/pages/owner_payment_history_page.dart';
import 'tenant_payment_upload_page.dart';

class TenantUnitDetailsPage extends StatelessWidget {
  final String? unitId;
  final String? assignment;
  final String unitTitle;
  final String building;
  final double rentAmount;
  final int paymentCycle;
  final String status;

  const TenantUnitDetailsPage({
    super.key,
    this.unitId,
    this.assignment,
    required this.unitTitle,
    required this.building,
    required this.rentAmount,
    required this.paymentCycle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 350,
              showBackButton: true,
              title: 'Paying rent for $unitTitle',
              subtitle:
                  '$building $unitTitle Yekatit-\nMiyazia 2018 lease rent payment',
              child: Transform.translate(
                offset: const Offset(0, 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          building,
                          Iconsax.building,
                        ),
                        const SizedBox(height: 8),
                        _buildHeaderInfoRow(
                          'Property Type',
                          'Office',
                          Iconsax.grammerly,
                        ),
                        const SizedBox(height: 8),
                        _buildHeaderInfoRow(
                          'Payment Cycle',
                          'Every 3 Month',
                          Iconsax.calendar,
                        ),
                        const SizedBox(height: 8),
                        _buildHeaderInfoRow(
                          'Total Rent Amount',
                          'ETB $rentAmount',
                          Iconsax.card,
                        ),
                        const SizedBox(height: 8),
                        _buildHeaderInfoRow(
                          'Occupancy status',
                          status.isEmpty ? 'Occupied' : status,
                          Iconsax.user_octagon,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner Contact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          child: const Icon(
                            Iconsax.user,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              building,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '+251 91 135 1324',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Account Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailActionCard(
                    context,
                    Iconsax.wallet,
                    'Attach Payment Receipt',
                    'Upload payment receipt for this unit',
                      onTap: () {
                      if (unitId != null) {
                        // Parse rent amount from string (e.g., "45,000" -> 45000)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantPaymentUploadPage(
                              unitId: unitId!,
                              assignmentId: assignment!,
                              unitNumber: unitTitle,
                              rentAmount: rentAmount,
                              paymentCycleMonths: paymentCycle, // Default, should come from API
                            ),
                          ),
                        );
                      } else {
                        AppToast.error(context, 'Unit ID not available');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDetailActionCard(
                    context,
                    Iconsax.note_text,
                    'My Payment History',
                    'View paid stipends and uploaded receipts',
                      onTap: () {
                      if (unitId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerPaymentHistoryPage(
                              unitId: unitId,
                              unitNumber: unitTitle,
                            ),
                          ),
                        );
                      } else {
                        AppToast.error(context, 'Unit ID not available');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // _buildDetailActionCard(
                  //   context,
                  //   Iconsax.card,
                  //   'Request Payment Cycle Change',
                  //   'Request custom payment cycle',
                  //   onTap: () {},
                  // ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () {
                      if (unitId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantPaymentUploadPage(
                              unitId: unitId!,
                              assignmentId: assignment!,
                              unitNumber: unitTitle,
                              rentAmount: rentAmount,
                              paymentCycleMonths: 3, // Default, should come from API
                            ),
                          ),
                        );
                      } else {
                        AppToast.error(context, 'Unit ID not available');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Attach Payment Receipt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black45.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black45.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: color ?? Colors.black45, size: 14),
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
              child: Icon(icon, color: AppColors.primary, size: 24),
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
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
