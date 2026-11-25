import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pm/shared/widgets/app_toast.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/owner_api.dart';

class OwnerAddBuildingPage extends StatefulWidget {
  const OwnerAddBuildingPage({super.key});

  @override
  State<OwnerAddBuildingPage> createState() => _OwnerAddBuildingPageState();
}

class _OwnerAddBuildingPageState extends State<OwnerAddBuildingPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 0 controllers
  final TextEditingController _nameController = TextEditingController();
  String? _propertyType;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  String? _paymentCycle;
  final TextEditingController _notesController = TextEditingController();

  // Step 1 documents
  File? _propertyDeed;
  File? _certificateOfTitle;
  File? _businessTin;

  // Step 2 distribution
  String? _distributionType = 'EVEN';
  final TextEditingController _customDistributionController = TextEditingController();
  final TextEditingController _defaultRentController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _pickDocument(String type) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        final file = File(image.path);
        switch (type) {
          case 'deed':
            _propertyDeed = file;
            break;
          case 'title':
            _certificateOfTitle = file;
            break;
          case 'tin':
            _businessTin = file;
            break;
        }
      });
    }
  }

  Future<void> _submitBuilding() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propertyDeed == null || _certificateOfTitle == null || _businessTin == null) {
      AppToast.error(context, 'Please upload all required documents');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare data for API
      final Map<String, String> data = {
        'name': _nameController.text,
        'propertyType': _propertyType!,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'floors': _floorsController.text,
        'units': _unitsController.text,
        'paymentCycle': _paymentCycle!,
        'notes': _notesController.text,
        'distributionType': _distributionType!,
        'customDistribution': _customDistributionController.text,
        'defaultRent': _defaultRentController.text,
        // In a real app you'd upload the files as multipart
      };

      // final response = await OwnerApi.createBuilding(data); // Assume this exists
      final response = await OwnerApi.createBuilding(
                        data,
                       _propertyDeed!,
                       _certificateOfTitle!,
                       _businessTin!,
                    );
                    
      if (!mounted) return;

      if (response.success) {
        AppToast.success(context, 'Building submitted for review');
        Navigator.pop(context, true);
      } else {
        AppToast.error(context, 'Failed to submit building: ${response.message}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error submitting building: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CurvedSection(
              height: 250,
              showBackButton: true,
              title: 'Add New Building',
              subtitle: 'Submit building for admin review',
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: List.generate(3, (i) {
                        final labels = ['Info', 'Documents', 'Distribution'];
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: i <= _currentStep ? AppColors.primary : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: i <= _currentStep ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Step content
                    if (_currentStep == 0) ...[
                      const Text(
                        'Building Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Building Name *',
                          prefixIcon: const Icon(Iconsax.building),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _propertyType,
                        decoration: InputDecoration(
                          labelText: 'Property Type *',
                          prefixIcon: const Icon(Iconsax.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Commercial', 'Residential', 'Mixed']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _propertyType = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Street Address *',
                          prefixIcon: const Icon(Iconsax.location),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: 'State/Province *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _floorsController,
                              decoration: InputDecoration(
                                labelText: 'Total Floors',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitsController,
                              decoration: InputDecoration(
                                labelText: 'Total Units *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _paymentCycle,
                        decoration: InputDecoration(
                          labelText: 'Payment Cycle *',
                          prefixIcon: const Icon(Iconsax.calendar),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Monthly', 'Quarterly', 'Yearly']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _paymentCycle = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Additional Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 3,
                      ),
                    ] else if (_currentStep == 1) ...[
                      const Text(
                        'Required Documents',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      _buildDocumentUpload(
                        'Property Deed',
                        'Upload property deed document',
                        _propertyDeed,
                        () => _pickDocument('deed'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentUpload(
                        'Certificate of Title',
                        'Upload certificate of title',
                        _certificateOfTitle,
                        () => _pickDocument('title'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentUpload(
                        'Business TIN Number',
                        'Upload business TIN document',
                        _businessTin,
                        () => _pickDocument('tin'),
                      ),
                    ] else ...[
                      const Text(
                        'Distribution & Review',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _distributionType,
                        decoration: InputDecoration(
                          labelText: 'Unit Distribution *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['EVEN', 'CUSTOM']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _distributionType = v!),
                      ),
                      const SizedBox(height: 12),
                      if (_distributionType == 'CUSTOM') ...[
                        TextFormField(
                          controller: _customDistributionController,
                          decoration: InputDecoration(
                            labelText: 'Custom distribution (CSV per floor)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _defaultRentController,
                        decoration: InputDecoration(
                          labelText: 'Default Rent Amount (per unit)',
                          prefixIcon: const Icon(Icons.money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitBuilding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit for Review',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        if (_currentStep < 2)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentStep == 0) {
                                  if (!_formKey.currentState!.validate()) return;
                                  setState(() => _currentStep = 1);
                                } else if (_currentStep == 1) {
                                  if (_propertyDeed == null ||
                                      _certificateOfTitle == null ||
                                      _businessTin == null) {
                                    AppToast.error(context, 'Please upload all required documents');
                                    return;
                                  }
                                  setState(() => _currentStep = 2);
                                }
                              },
                              child: const Text('Next'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String subtitle, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: file != null ? AppColors.success.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.success : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: file != null ? AppColors.success : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                file != null ? Iconsax.document_upload : Iconsax.document,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null ? 'Document uploaded ✓' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null ? AppColors.success : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? AppColors.success : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _floorsController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    _customDistributionController.dispose();
    _defaultRentController.dispose();
    super.dispose();
  }
}