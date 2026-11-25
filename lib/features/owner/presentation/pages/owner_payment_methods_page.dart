import 'package:flutter/material.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/api/payment_method_api.dart';
import '../../domain/models/owner_payment_method.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/modern_dropdown.dart';

class OwnerPaymentMethodsPage extends StatefulWidget {
  const OwnerPaymentMethodsPage({super.key});

  @override
  State<OwnerPaymentMethodsPage> createState() =>
      _OwnerPaymentMethodsPageState();
}

class _OwnerPaymentMethodsPageState extends State<OwnerPaymentMethodsPage> {
  List<OwnerPaymentMethod> _methods = [];
  List<AvailablePaymentMethod> _availableMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PaymentMethodApi.getOwnerPaymentMethods(),
        PaymentMethodApi.getAvailablePaymentMethods(),
      ]);

      setState(() {
        _methods = results[0].data as List<OwnerPaymentMethod>;
        _availableMethods = results[1].data as List<AvailablePaymentMethod>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to load payment methods');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteMethod(OwnerPaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete ${method.paymentMethodName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PaymentMethodApi.deletePaymentMethod(method.id);
        if (mounted) {
          AppToast.success(context, 'Payment method deleted');
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Failed to delete payment method');
        }
      }
    }
  }

  void _showAddEditDialog([OwnerPaymentMethod? method]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditMethodSheet(
        availableMethods: _availableMethods,
        existingMethod: method,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CurvedSection(
            height: 250,
            showBackButton: true,
            title: 'Payments Methods',
            subtitle: 'Tell tenants how to receive rent stipends and payments',
          ),

          Expanded(
            child: _loading
                ? const Center(child: LinearProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_methods.isEmpty)
                        Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const SizedBox(height: 50),
                            Icon(
                              Iconsax.wallet,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No payment methods configured',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                        else
                          ..._methods.map((method) => _buildMethodCard(method)),

                        const SizedBox(height: 100),

                        ElevatedButton(
                          onPressed: () => _showAddEditDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Add Method',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(OwnerPaymentMethod method) {
    String details = '';
    if (method.paymentMethodType == 'BANK') {
      details = '${method.bankName ?? ''} | ${method.accountNumber ?? ''}';
    } else if (method.paymentMethodType == 'MOBILE_MONEY') {
      details = 'Mobile | ${method.mobileNumber ?? ''}';
    } else {
      details = method.additionalInfo ?? 'Cash payment';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.paymentMethodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (method.accountName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    method.accountName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            method.paymentMethodType == 'BANK' ? Iconsax.bank : Iconsax.card,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteMethod(method),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditMethodSheet extends StatefulWidget {
  final List<AvailablePaymentMethod> availableMethods;
  final OwnerPaymentMethod? existingMethod;
  final VoidCallback onSaved;

  const _AddEditMethodSheet({
    required this.availableMethods,
    this.existingMethod,
    required this.onSaved,
  });

  @override
  State<_AddEditMethodSheet> createState() => _AddEditMethodSheetState();
}

class _AddEditMethodSheetState extends State<_AddEditMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMethodId;
  AvailablePaymentMethod? _selectedMethod;
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMethod != null) {
      _selectedMethodId = widget.existingMethod!.paymentMethodId;
      _selectedMethod = widget.availableMethods
          .where((m) => m.id == _selectedMethodId)
          .firstOrNull;
      _accountNumberController.text =
          widget.existingMethod!.accountNumber ?? '';
      _accountNameController.text = widget.existingMethod!.accountName ?? '';
      _mobileNumberController.text = widget.existingMethod!.mobileNumber ?? '';
      _additionalInfoController.text =
          widget.existingMethod!.additionalInfo ?? '';
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _mobileNumberController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethodId == null && widget.existingMethod == null) {
      AppToast.error(context, 'Please select a payment method');
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.existingMethod != null) {
        await PaymentMethodApi.updatePaymentMethod(
          id: widget.existingMethod!.id,
          accountNumber: _accountNumberController.text.isNotEmpty
              ? _accountNumberController.text
              : null,
          accountName: _accountNameController.text.isNotEmpty
              ? _accountNameController.text
              : null,
          mobileNumber: _mobileNumberController.text.isNotEmpty
              ? _mobileNumberController.text
              : null,
          additionalInfo: _additionalInfoController.text.isNotEmpty
              ? _additionalInfoController.text
              : null,
        );
        if (mounted) AppToast.success(context, 'Payment method updated');
      } else {
        await PaymentMethodApi.addPaymentMethod(
          paymentMethodId: _selectedMethodId!,
          accountNumber: _accountNumberController.text.isNotEmpty
              ? _accountNumberController.text
              : null,
          accountName: _accountNameController.text.isNotEmpty
              ? _accountNameController.text
              : null,
          mobileNumber: _mobileNumberController.text.isNotEmpty
              ? _mobileNumberController.text
              : null,
          additionalInfo: _additionalInfoController.text.isNotEmpty
              ? _additionalInfoController.text
              : null,
        );
        if (mounted) AppToast.success(context, 'Payment method added');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save payment method');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.existingMethod != null
                                ? Iconsax.edit_2
                                : Iconsax.add_square,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.existingMethod != null
                              ? 'Edit Method'
                              : 'Add New Method',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (widget.existingMethod == null) ...[
                      const Text(
                        'Choose Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ModernDropdown<String>(
                        isExpanded: true,
                        value: _selectedMethodId,
                        hint: Text(L10n.of(context).selectPaymentMethod),
                        items: widget.availableMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method.id,
                            child: Row(
                              children: [
                                Icon(
                                  method.type == 'BANK'
                                      ? Iconsax.bank
                                      : Iconsax.mobile,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    method.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMethodId = value;
                            _selectedMethod = widget.availableMethods
                                .firstWhere((m) => m.id == value);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedMethod?.type == 'BANK') ...[
                      _buildLabel('Account Number'),
                      _buildTextField(
                        controller: _accountNumberController,
                        hint:
                            _selectedMethod?.accountNumberHint ??
                            'Enter account number',
                        icon: Iconsax.card_pos,
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Account number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Account Name'),
                      _buildTextField(
                        controller: _accountNameController,
                        hint:
                            _selectedMethod?.accountNameHint ??
                            'Full name of account holder',
                        icon: Iconsax.user,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Account name is required'
                            : null,
                      ),
                    ] else if (_selectedMethod?.type == 'MOBILE_MONEY') ...[
                      _buildLabel('Mobile Number'),
                      _buildTextField(
                        controller: _mobileNumberController,
                        hint: _selectedMethod?.mobileNumberHint ?? '09XXXXXXXX',
                        icon: Iconsax.mobile,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Mobile number is required'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 16),
                    _buildLabel('Additional Info (Optional)'),
                    _buildTextField(
                      controller: _additionalInfoController,
                      hint: 'Eg. Office hours, specific instructions...',
                      icon: Iconsax.info_circle,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Payment Method',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }
}
