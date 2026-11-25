import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../shared/widgets/modern_dropdown.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/tenant_api.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../owner/domain/models/owner_payment_method.dart';

class TenantPaymentUploadPage extends StatefulWidget {
  final String assignmentId;
  final String unitId;
  final String unitNumber;
  final double rentAmount;
  final int paymentCycleMonths;

  const TenantPaymentUploadPage({
    super.key,
    required this.assignmentId,
    required this.unitId,
    required this.unitNumber,
    required this.rentAmount,
    required this.paymentCycleMonths,
  });

  @override
  State<TenantPaymentUploadPage> createState() =>
      _TenantPaymentUploadPageState();
}

class _TenantPaymentUploadPageState extends State<TenantPaymentUploadPage> {
  File? _receiptImage;
  final _notesController = TextEditingController();
  bool _isUploading = false;
  List<AvailablePaymentMethod> _ownerMethods = [];
  AvailablePaymentMethod? _selectedMethod;
  bool _isLoadingMethods = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerMethods();
  }

  Future<void> _fetchOwnerMethods() async {
    try {
      final response = await TenantApi.getPaymentMethods(widget.unitId);
      if (response.success && response.data != null) {
        setState(() {
          _ownerMethods = response.data!;
          if (_ownerMethods.isNotEmpty) {
            _selectedMethod = _ownerMethods.first;
          }
          _isLoadingMethods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMethods = false);
        AppToast.error(context, 'Failed to load payment methods');
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    final l10n = L10n.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera, color: AppColors.primary),
                title: Text(l10n.camera),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: AppColors.primary),
                title: Text(l10n.gallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadReceipt() async {
    final l10n = L10n.of(context);

    if (_receiptImage == null) {
      AppToast.warning(context, l10n.pleaseSelectReceipt);
      return;
    }

    if (_selectedMethod == null) {
      AppToast.warning(context, 'Please select a payment method');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final response = await TenantApi.uploadReceipt(
        assignmentId: widget.assignmentId,
        paymentMethodId: _selectedMethod!.id,
        receipt: _receiptImage!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (response.success) {
          AppToast.success(context, l10n.receiptUploadedSuccessfully);
          Navigator.pop(context, true);
        } else {
          AppToast.error(context, response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        AppToast.error(context, '${l10n.error}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );
    final totalAmount = widget.rentAmount;

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 240,
            showBackButton: true,
            title: '${l10n.payRent} - ${widget.unitNumber}',
            subtitle: l10n.uploadPaymentReceipt,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentSummaryCard(l10n, currencyFormat, totalAmount),
                  const SizedBox(height: 24),
                  _buildBankDetailsCard(l10n),
                  const SizedBox(height: 24),
                  _buildReceiptUploadSection(l10n),
                  const SizedBox(height: 24),
                  _buildNotesField(l10n),
                  const SizedBox(height: 24),
                  _buildSubmitButton(l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(
    L10n l10n,
    NumberFormat currencyFormat,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF5B8DEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rentAmount,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(widget.rentAmount/widget.paymentCycleMonths),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.paymentCycleMonths} ${l10n.months}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currencyFormat.format(totalAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard(L10n l10n) {
  if (_isLoadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ownerMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.info_circle, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Owner has not configured any payment methods for this building.',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectPaymentAccount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildMethodDropdown(),
          if (_selectedMethod != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (_selectedMethod?.type == 'BANK') ...[
              _buildModernDetailRow(
                l10n.bankName,
                _selectedMethod!.bankName ?? 'N/A',
                Iconsax.bank,
              ),
              _buildModernDetailRow(
                l10n.accountNumber,
                _selectedMethod!.accountNumber ?? 'N/A',
                Iconsax.card_pos,
              ),
              _buildModernDetailRow(
                l10n.accountName,
                _selectedMethod!.accountName ?? 'N/A',
                Iconsax.user_tag,
              ),
            ] else if (_selectedMethod?.type == 'MOBILE_MONEY') ...[
              _buildModernDetailRow(
                'Provider',
                _selectedMethod!.provider ?? 'N/A',
                Iconsax.mobile,
              ),
              _buildModernDetailRow(
                'Mobile Number',
                _selectedMethod!.mobileNumber ?? 'N/A',
                Iconsax.call,
              ),
              _buildModernDetailRow(
                'Account Name',
                _selectedMethod!.accountName ?? 'N/A',
                Iconsax.user_tag,
              ),
            ],
            if (_selectedMethod?.instructions != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedMethod!.instructions!,
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMethodDropdown() {
    final l10n = L10n.of(context);
    return ModernDropdown<AvailablePaymentMethod>(
      isExpanded: true,
      value: _selectedMethod,
      hint: Text(l10n.selectPaymentMethod),
      items: _ownerMethods.map((method) {
        return DropdownMenuItem<AvailablePaymentMethod>(
          value: method,
          child: Row(
            children: [
              Icon(
                method.type == 'BANK' ? Iconsax.bank : Iconsax.mobile,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedMethod = value),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.copy, size: 18, color: Colors.grey),
            onPressed: () {
              // Copy to clipboard
              AppToast.success(context, '$label copied to clipboard');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploadSection(L10n l10n) {
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.uploadReceipt,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: _receiptImage == null
                  ? Colors.grey[100]
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _receiptImage == null
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.success,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _receiptImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.camera,
                        size: 48,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.tapToUploadReceipt,
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.supportedFormats,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _receiptImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _receiptImage = null),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(L10n l10n) {
  return TextField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: l10n.notesOptional,
        hintText: l10n.addNotesAboutPayment,
        prefixIcon: const Icon(Iconsax.note_text),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      maxLines: 3,
      maxLength: 200,
    );
  }

  Widget _buildSubmitButton(L10n l10n) {
  return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _uploadReceipt,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          disabledBackgroundColor: Colors.grey[300],
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isUploading ? 0 : 3,
        ),
        child: _isUploading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    l10n.submitPaymentReceipt,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
