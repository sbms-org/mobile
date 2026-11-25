import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../shared/widgets/app_toast.dart';

class UpdateUnitBottomSheet extends StatefulWidget {
  final String unitId;
  final String unitNumber;
  final int? floor;
  final double? rentAmount;
  final String? size;
  final String? description;
  final int paymentCycleMonths;

  const UpdateUnitBottomSheet({
    super.key,
    required this.unitId,
    required this.unitNumber,
    this.floor,
    this.rentAmount,
    this.size,
    this.description,
    required this.paymentCycleMonths,
  });

  @override
  State<UpdateUnitBottomSheet> createState() => _UpdateUnitBottomSheetState();
}

class _UpdateUnitBottomSheetState extends State<UpdateUnitBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _paymentCycle = 1;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _numberController.text = widget.unitNumber;
    if (widget.floor != null) _floorController.text = widget.floor.toString();
    if (widget.rentAmount != null) _rentController.text = widget.rentAmount.toString();
    if (widget.size != null) _sizeController.text = widget.size!;
    if (widget.description != null) _descriptionController.text = widget.description!;
    _paymentCycle = widget.paymentCycleMonths;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateUnit() async {
    setState(() => _isLoading = true);
    try {
      final data = <String, dynamic>{};
      data['unit_number'] = _numberController.text.trim();
      data['floor'] = int.tryParse(_floorController.text);
      data['rent_amount'] = double.tryParse(_rentController.text);
      data['size'] = _sizeController.text.trim();
      data['description'] = _descriptionController.text.trim();
      data['payment_cycle_months'] = _paymentCycle;

      final resp = await OwnerApi.updateUnit(widget.unitId, data);
      
      if (resp.success) {
        if (mounted) AppToast.success(context, 'Unit updated successfully');
        Navigator.pop(context, true);
      } else {
        if (mounted) AppToast.error(context, resp.message);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildInfoStep(),
                  _buildPaymentStep(),
                  _buildOtherStep(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.edit, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Text('Edit Unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepIndicator(0, 'Info'),
              Expanded(child: Divider(color: _currentStep > 0 ? AppColors.primary : Colors.grey.shade300)),
              _buildStepIndicator(1, 'Payment'),
              Expanded(child: Divider(color: _currentStep > 1 ? AppColors.primary : Colors.grey.shade300)),
              _buildStepIndicator(2, 'Other'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.grey.shade300, shape: BoxShape.circle),
          child: Center(child: Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primary : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildInfoStep() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _numberController,
              decoration: InputDecoration(labelText: 'Unit Number', prefixIcon: const Icon(Iconsax.home), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _floorController,
              decoration: InputDecoration(labelText: 'Floor', prefixIcon: const Icon(Iconsax.grid_1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { if (_formKey.currentState!.validate()) setState(() => _currentStep = 1); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _rentController,
            decoration: InputDecoration(labelText: 'Rent Amount', prefixIcon: const Icon(Iconsax.money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _paymentCycle,
            decoration: InputDecoration(labelText: 'Payment Cycle (Months)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: [1, 3, 6, 12].map((m) => DropdownMenuItem(value: m, child: Text('$m Month(s)'))).toList(),
            onChanged: (val) => setState(() => _paymentCycle = val!),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep = 0), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)), child: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => setState(() => _currentStep = 2), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 56)), child: const Text('Next', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Other Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _sizeController,
            decoration: InputDecoration(labelText: 'Size', prefixIcon: const Icon(Iconsax.maximize), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep = 1), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)), child: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateUnit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 56)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Unit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
