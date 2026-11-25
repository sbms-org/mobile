import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_receipt_view_page.dart';
import '../providers/payment_history_provider.dart';

class OwnerPaymentHistoryPage extends ConsumerWidget {
  final String? unitId;
  final String? unitNumber;

  const OwnerPaymentHistoryPage({
    super.key,
    this.unitId,
    this.unitNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (unitId == null) {
      return Scaffold(
        body: Column(
          children: [
            CurvedSection(
              height: 250,
              showBackButton: true,
              title: unitNumber ?? 'Payment History',
            ),
            const Expanded(
              child: Center(
                child: Text('Unit information not available'),
              ),
            ),
          ],
        ),
      );
    }

    final paymentHistoryAsync = ref.watch(paymentHistoryProvider(unitId!));

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: '${unitNumber ?? "Unit"} Payments History',
          ),
          
          Expanded(
            child: paymentHistoryAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Text('No payment history available'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildHistoryItem(context, payment);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(paymentHistoryProvider(unitId!)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, payment) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateString = payment.paidDate != null 
      ? dateFormat.format(payment.paidDate!) 
      : 'Pending';
    final title = '${payment.unit.unitNumber} - $dateString';
    final details = '${payment.unit.paymentCycleMonths} Months | ${currencyFormat.format(payment.amount)}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerReceiptViewPage(payment: payment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.dollar_square, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
