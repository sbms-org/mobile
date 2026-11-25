import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'owner_pm_details_page.dart';
import 'owner_add_pm_page.dart';

class OwnerPropertyManagersPage extends ConsumerStatefulWidget {
  const OwnerPropertyManagersPage({super.key});

  @override
  ConsumerState<OwnerPropertyManagersPage> createState() =>
      _OwnerPropertyManagersPageState();
}

class _OwnerPropertyManagersPageState
    extends ConsumerState<OwnerPropertyManagersPage> {
  List<PropertyManager> _managers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    try {
      final response = await OwnerApi.getPropertyManagers();
      if (mounted) {
        setState(() {
          _managers = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

    Future<void> _showAddPmDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerAddPmPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           CurvedSection(
            height: 280,
            showBackButton: true,
            title: 'Property Managers',
            subtitle:
                'Add Managers to look out for your properties when you are gone',
            actions: [
                  GestureDetector(
                    onTap: _showAddPmDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Iconsax.user_add,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add PM',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),

          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _managers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.user_tag,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Property Managers found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: _managers.length,
                        itemBuilder: (context, index) {
                          final pm = _managers[index];
                          return _buildPmCard(context, pm);
                        },
                      ),

                // Positioned(
                //   right: 20,
                //   // top: -10,
                //   child: FloatingActionButton(
                //     onPressed: () async {
                //       final result = await Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const OwnerAddPmPage(),
                //         ),
                //       );
                //       if (result == true) _loadManagers();
                //     },
                //     backgroundColor: Colors.white,
                //     elevation: 10,
                //     child: const Icon(
                //       Icons.add,
                //       color: AppColors.success,
                //       size: 40,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPmCard(BuildContext context, PropertyManager pm) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerPmDetailsPage(pmId: pm.id),
          ),
        );
        if (result == true) _loadManagers();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.user, color: AppColors.success),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pm.fullname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        pm.mobile,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (pm.status == 'ACTIVE'
                                  ? AppColors.success
                                  : Colors.orange)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pm.status,
                      style: TextStyle(
                        color: pm.status == 'ACTIVE'
                            ? AppColors.success
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
