import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart' as models;
import '../../../../core/utils/logger.dart';
import 'package:file_picker/file_picker.dart';

class OwnerGenerateReportsPage extends StatefulWidget {
  const OwnerGenerateReportsPage({super.key});

  @override
  State<OwnerGenerateReportsPage> createState() =>
      _OwnerGenerateReportsPageState();
}

class _OwnerGenerateReportsPageState extends State<OwnerGenerateReportsPage> {
  Set<String> selectedReportTypes = {'Income'};
  String selectedFormat = 'Pdf';

  List<models.Building> buildings = [];
  models.Building? selectedBuilding;
  List<models.Unit> units = [];
  models.Unit? selectedUnit;
  int? selectedFloorNum;

  bool isLoadingBuildings = false;
  bool isGenerating = false;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  final List<String> availableReportTypes = [
    'Income',
    'Overdue',
    'Occupancy',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() => isLoadingBuildings = true);
    try {
      final response = await OwnerApi.getBuildings("");
      if (response.success) {
        setState(() {
          buildings = response.data ?? [];
          isLoadingBuildings = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load buildings', e);
      setState(() => isLoadingBuildings = false);
    }
  }

  Future<void> _loadUnits(String buildingId) async {
    try {
      final response = await OwnerApi.getBuildingUnits(buildingId);
      if (response.success) {
        setState(() {
          units = response.data ?? [];
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load units', e);
    }
  }

  Future<void> _generateReport() async {
    if (selectedReportTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one report type')),
      );
      return;
    }

    setState(() => isGenerating = true);
    try {
      final extraParams = <String, dynamic>{};
      if (selectedBuilding != null)
        extraParams['buildingId'] = selectedBuilding!.id;
      if (selectedUnit != null) extraParams['unitId'] = selectedUnit!.id;
      if (selectedFloorNum != null) extraParams['floor'] = selectedFloorNum;

      extraParams['startDate'] = startDate.toIso8601String();
      extraParams['endDate'] = endDate.toIso8601String();

      final bytes = await OwnerApi.exportReportBytes(
        type: selectedReportTypes.join(',').toLowerCase(),
        format: selectedFormat.toLowerCase(),
        extraParams: extraParams,
      );

      final extension = selectedFormat.toLowerCase() == 'pdf' ? 'pdf' : 'xlsx';
      final fileName =
          'report_${DateTime.now().millisecondsSinceEpoch}.$extension';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Select Save Location',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputFile != null && !Platform.isIOS && !Platform.isAndroid) {
        // On desktop/web, we might still need to write manually if bytes wasn't handled by the dialog
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to $outputFile'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to generate report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelMapper,
    required Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(labelMapper(items[index])),
                      onTap: () {
                        onSelected(items[index]);
                        Navigator.pop(context);
                      },
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CurvedSection(
              height: 250,
              showBackButton: true,
              title: 'Custom Reports',
              subtitle: 'Multi-select types to combine them into one file',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Report Types Multi-Select
                  _buildSectionCard(
                    'Select Report Types',
                    Wrap(
                      spacing: 8,
                      children: availableReportTypes.map((type) {
                        final isSelected = selectedReportTypes.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                selectedReportTypes.add(type);
                              } else {
                                if (selectedReportTypes.length > 1) {
                                  selectedReportTypes.remove(type);
                                }
                              }
                            });
                          },
                          selectedColor: AppColors.success.withOpacity(0.2),
                          checkmarkColor: AppColors.success,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.success
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.success
                                  : Colors.grey[300]!,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Target Filtering
                  _buildSectionCard(
                    'Property Selection',
                    Column(
                      children: [
                        _buildPickerButton(
                          label: 'Building',
                          value:
                              selectedBuilding?.name ??
                              'Select Building (Optional)',
                          icon: Iconsax.building,
                          onTap: () => _showPicker(
                            title: 'Select Building',
                            items: buildings,
                            labelMapper: (b) => b.name,
                            onSelected: (b) {
                              setState(() {
                                selectedBuilding = b;
                                selectedFloorNum = null;
                                selectedUnit = null;
                                units = [];
                              });
                              _loadUnits(b.id);
                            },
                          ),
                        ),
                        if (selectedBuilding != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPickerButton(
                                  label: 'Floor',
                                  value: selectedFloorNum == null
                                      ? 'Floor'
                                      : 'Floor $selectedFloorNum',
                                  icon: Iconsax.layer,
                                  onTap: () => _showPicker(
                                    title: 'Select Floor',
                                    items: List.generate(
                                      selectedBuilding!.totalFloors ?? 0,
                                      (i) => i,
                                    ),
                                    labelMapper: (f) => 'Floor $f',
                                    onSelected: (f) =>
                                        setState(() => selectedFloorNum = f),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPickerButton(
                                  label: 'Unit',
                                  value: selectedUnit?.unitNumber ?? 'Unit',
                                  icon: Iconsax.house,
                                  onTap: () => _showPicker(
                                    title: 'Select Unit',
                                    items: units,
                                    labelMapper: (u) => 'Unit ${u.unitNumber}',
                                    onSelected: (u) =>
                                        setState(() => selectedUnit = u),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Time Period',
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            'Start Date',
                            startDate,
                            (d) => setState(() => startDate = d),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateButton(
                            'End Date',
                            endDate,
                            (d) => setState(() => endDate = d),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Export Options',
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormatChoice(
                            'Pdf',
                            Iconsax.document_text_1,
                            selectedFormat == 'Pdf',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormatChoice(
                            'Excel',
                            Iconsax.document_cloud,
                            selectedFormat == 'Excel',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: isGenerating ? null : _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 64),
                      elevation: 4,
                      shadowColor: AppColors.success.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isGenerating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Iconsax.import, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Export Combined Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChoice(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedFormat = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withOpacity(0.05)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.success : Colors.grey[200]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.success : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.success : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime date,
    Function(DateTime) onSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.success,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Iconsax.calendar_1,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
