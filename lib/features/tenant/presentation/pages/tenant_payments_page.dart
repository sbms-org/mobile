import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:abushakir/abushakir.dart';
import 'package:pm/l10n/generated/L10n.dart';
import 'package:pm/shared/widgets/app_toast.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/tenant_api.dart';
import 'tenant_payment_upload_page.dart';

class TenantPaymentsPage extends ConsumerStatefulWidget {
  const TenantPaymentsPage({super.key});

  @override
  ConsumerState<TenantPaymentsPage> createState() => _TenantPaymentsPageState();
}

class _TenantPaymentsPageState extends ConsumerState<TenantPaymentsPage> {
  List<dynamic> _duePayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDuePayments();
  }

  Future<void> _loadDuePayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await TenantApi.getDuePayments();
      if (response.success && mounted) {
        setState(() {
          _duePayments = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Error loading payments: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final isAmharic = locale.languageCode == 'am';
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: false,
            title: l10n.duePayments,
            subtitle: l10n.pendingRentPayments,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _duePayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.tick_circle, size: 80, color: AppColors.success),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noDuePayments,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.allPaymentsUpToDate,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDuePayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _duePayments.length,
                          itemBuilder: (context, index) {
                            final payment = _duePayments[index];
                            final daysUntilDue = payment['daysUntilDue'] ?? 0;
                            final isDue = payment['isDue'] ?? false;
                            final hasReceipt = payment['hasReceipt'] ?? false;
                            final receiptStatus = payment['receiptStatus'];

                            return _buildPaymentCard(
                              context,
                              l10n,
                              payment['unitId'] ?? '',
                              payment['assignmentId'] ?? '',
                              payment['unitNumber'] ?? 'N/A',
                              payment['buildingName'] ?? 'N/A',
                              double.tryParse(payment['amount']?.toString() ?? '0') ?? 0,
                              DateTime.parse(payment['dueDate']),
                              payment['cycleMonths'] ?? 3,
                              daysUntilDue,
                              isDue,
                              hasReceipt,
                              receiptStatus,
                              currencyFormat,
                              isAmharic,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, bool isAmharic) {
    if (isAmharic) {
      final ethDate = EtDatetime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
      return '${ethDate.day} ${_getEthiopianMonth(ethDate.month)} ${ethDate.year}';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getEthiopianMonth(int month) {
    const months = [
      'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
      'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
    ];
    return months[month - 1];
  }

  Widget _buildPaymentCard(
    BuildContext context,
    L10n l10n,
    String unitId,
    String assignmentId,
    String unitNumber,
    String buildingName,
    double amount,
    DateTime dueDate,
    int cycleMonths,
    int daysUntilDue,
    bool isDue,
    bool hasReceipt,
    String? receiptStatus,
    NumberFormat currencyFormat,
    bool isAmharic,
  ) {
    Color statusColor = AppColors.primary;
    String statusText = isAmharic ? '$daysUntilDue ቀናት ይቀራል' : '$daysUntilDue days left';

    // Override status if receipt is pending
    if (hasReceipt && receiptStatus == 'PENDING') {
      statusColor = Colors.orange;
      statusText = isAmharic ? 'በግምገማ ላይ' : 'Under Review';
    } else if (isDue) {
      statusColor = const Color(0xFFD94444);
      statusText = isAmharic ? 'ዛሬ መክፈል አለብዎት' : 'Due Today';
    } else if (daysUntilDue < 0) {
      statusColor = const Color(0xFFD94444);
      statusText = isAmharic 
          ? '${daysUntilDue.abs()} ቀናት ዘግይቷል' 
          : '${daysUntilDue.abs()} days overdue';
    } else if (daysUntilDue <= 2) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            buildingName,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.amountDue,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.dueDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(dueDate, isAmharic),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasReceipt && receiptStatus == 'PENDING')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.clock, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAmharic
                          ? 'ደረሰኙ ተስቀሏል። ባለቤቱ በመገምገም ላይ ነው።'
                          : 'Receipt uploaded. Waiting for owner review.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isDue || daysUntilDue <= 5)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: statusColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDue
                          ? (isAmharic 
                              ? 'ክፍያው ዛሬ መክፈል አለበት። እባክዎ ደረሰኝ ይስቀሉ።'
                              : 'Payment is due today. Please upload receipt.')
                          : (isAmharic
                              ? 'ክፍያው በ$daysUntilDue ቀናት ውስጥ መክፈል አለበት። ክፍያዎን ያዘጋጁ።'
                              : 'Payment due in $daysUntilDue days. Prepare your payment.'),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasReceipt && receiptStatus == 'PENDING' 
                  ? null 
                  : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TenantPaymentUploadPage(
                            unitId: unitId,
                            assignmentId: assignmentId,
                            unitNumber: unitNumber,
                            rentAmount: amount,
                            paymentCycleMonths: cycleMonths,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadDuePayments();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasReceipt && receiptStatus == 'PENDING' 
                    ? Colors.grey 
                    : AppColors.success,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(hasReceipt && receiptStatus == 'PENDING' 
                      ? Iconsax.clock 
                      : Iconsax.card),
                  const SizedBox(width: 8),
                  Text(
                    hasReceipt && receiptStatus == 'PENDING'
                        ? (isAmharic ? 'በመጠባበቅ ላይ' : 'Pending Review')
                        : l10n.uploadReceipt,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
