import 'package:flutter/material.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_unit_details_page.dart';

class OwnerTenantUnitsPage extends StatelessWidget {
  final String tenantName;

  const OwnerTenantUnitsPage({super.key, required this.tenantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: 'Units - $tenantName',
            subtitle: 'Units rented across your properties',
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildUnitItem(
                  context,
                  '12371dbd-d9e2-4287-95e3-37495506a698',
                  'B-402',
                  'Lideta Mercato',
                  'Office',
                  'ETB 45,000',
                ),
                _buildUnitItem(
                  context,
                  '12371dbd-d9e2-4287-95e3-37495506a698',
                  'A-105',
                  'Bole Atlas',
                  'Shop',
                  'ETB 38,000',
                ),
                _buildUnitItem(
                  context,
                  '12371dbd-d9e2-4287-95e3-37495506a698',
                  'C-201',
                  'Lideta Mercato',
                  'Office',
                  'ETB 25,000',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitItem(
    BuildContext context,
    String unitId,
    String unitNo,
    String building,
    String type,
    String rent,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigation to unit details with mock data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerUnitDetailsPage(
              unitId: unitId,
            ),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.building_3, color: AppColors.primary),
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
                        'Unit $unitNo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        rent,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    building,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
