import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:abushakir/abushakir.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import '../../../../shared/widgets/app_toast.dart';

final pendingReceiptsProvider = FutureProvider<List<Receipt>>((ref) async {
  final response = await OwnerApi.getPendingReceipts();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});

class OwnerPendingReceiptsPage extends ConsumerWidget {
  const OwnerPendingReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(pendingReceiptsProvider);
    final l10n = L10n.of(context);

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 240,
            showBackButton: true,
            title: l10n.pendingReceipts,
            subtitle: l10n.reviewTenantPayments,
          ),
          Expanded(
            child: receiptsAsync.when(
              data: (receipts) {
                if (receipts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.tick_circle, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPendingReceipts,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.allReceiptsReviewed,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(pendingReceiptsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: receipts.length,
                    itemBuilder: (context, index) {
                      return _ReceiptCard(
                        receipt: receipts[index],
                        onAction: () => ref.refresh(pendingReceiptsProvider),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.info_circle, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadingReceipts,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(pendingReceiptsProvider),
                      icon: const Icon(Iconsax.refresh),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
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
}

class _ReceiptCard extends ConsumerWidget {
  final Receipt receipt;
  final VoidCallback onAction;

  const _ReceiptCard({required this.receipt, required this.onAction});

  String _formatDate(DateTime date, bool isAmharic) {
    if (isAmharic) {
      final ethDate = EtDatetime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
      final months = [
        'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
        'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
      ];
      return '${ethDate.day} ${months[ethDate.month - 1]} ${ethDate.year}';
    }
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _getTimeAgo(DateTime date, L10n l10n) {
  final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inMinutes < 60) return '${difference.inMinutes}${l10n.minutesAgo}';
    if (difference.inHours < 24) return '${difference.inHours}${l10n.hoursAgo}';
    if (difference.inDays < 7) return '${difference.inDays}${l10n.daysAgo}';
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final isAmharic = locale.languageCode == 'am';
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Iconsax.receipt_2, color: Colors.orange, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.unit?.unitNumber ?? 'Unit',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Iconsax.building, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  receipt.unit?.building?.name ?? 'Building',
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.clock, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            isAmharic ? 'በመጠባበቅ' : 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Metadata Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.user,
                        label: l10n.tenant,
                        value: receipt.tenant?.fullname ?? 'N/A',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.wallet,
                        label: l10n.amount,
                        value: currencyFormat.format(receipt.unit?.rentAmount ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.calendar,
                        label: l10n.uploaded,
                        value: _getTimeAgo(receipt.createdAt, l10n),
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildMetadataItem(
                        icon: Iconsax.calendar_tick,
                        label: l10n.uploadDate,
                        value: _formatDate(receipt.createdAt, isAmharic),
                      ),
                    ),
                  ],
                ),
                if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Iconsax.message_text, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tenantNote,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                receipt.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Receipt Image
          GestureDetector(
            onTap: () => _showFullImage(context),
            child: ClipRRect(
              child: CachedNetworkImage(
                imageUrl: receipt.receiptUrl,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 280,
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 280,
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.gallery_slash, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        l10n.imageLoadError,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectBottomSheet(context, l10n),
                    icon: const Icon(Iconsax.close_circle),
                    label: Text(l10n.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptReceipt(context, l10n),
                    icon: const Icon(Iconsax.tick_circle),
                    label: Text(l10n.accept),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
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

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: receipt.receiptUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptReceipt(BuildContext context, L10n l10n) async{
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.tick_circle, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Text(l10n.acceptReceipt),
          ],
        ),
        content: Text(l10n.acceptReceiptConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.accept),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await OwnerApi.acceptReceipt(receipt.id, null);
      if (context.mounted) {
        if (response.success) {
          AppToast.success(context, l10n.receiptAcceptedSuccess);
          onAction();
        } else {
          AppToast.error(context, response.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Error: $e');
      }
    }
  }

  void _showRejectBottomSheet(BuildContext context, L10n l10n) {
  final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.close_circle, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rejectReceipt,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.provideRejectionReason,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: reasonController,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.rejectionReason,
                    hintText: l10n.enterRejectionReason,
                    prefixIcon: const Icon(Iconsax.message_text),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.reasonRequired;
                    }
                    if (value.trim().length < 10) {
                      return l10n.reasonTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          Navigator.pop(context);
                          try {
                            final response = await OwnerApi.rejectReceipt(
                              receipt.id,
                              reasonController.text.trim(),
                            );
                            if (context.mounted) {
                              if (response.success) {
                                AppToast.success(context, l10n.receiptRejectedSuccess);
                                onAction();
                              } else {
                                AppToast.error(context, response.message);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(context, 'Error: $e');
                            }
                          }
                        },
                        icon: const Icon(Iconsax.close_circle),
                        label: Text(l10n.rejectReceipt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 54),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
