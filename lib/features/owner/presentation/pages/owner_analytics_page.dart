import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'owner_generate_reports_page.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/utils/logger.dart';
import 'notifications_page.dart';
import '../../../../shared/widgets/modern_dropdown.dart';

class OwnerAnalyticsPage extends ConsumerStatefulWidget {
  const OwnerAnalyticsPage({super.key});

  @override
  ConsumerState<OwnerAnalyticsPage> createState() => _OwnerAnalyticsPageState();
}

class _OwnerAnalyticsPageState extends ConsumerState<OwnerAnalyticsPage> {
  bool isLoading = true;
  Map<String, dynamic>? analyticsData;
  String? selectedPropertyType;
  int? currentMonthIndex; // 0 for All, 1 for Jan, etc.

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics({int? month, String? propertyType}) async {
    setState(() => isLoading = true);
    try {
      final response = await OwnerApi.getAnalytics(
        month: month,
        year: DateTime.now().year,
        propertyType: propertyType,
      );
      if (response.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            analyticsData = response.data;
            isLoading = false;
          });
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch analytics', e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    if (isLoading && analyticsData == null) {
      return const Scaffold(body: Center(child: LinearProgressIndicator()));
    }

    final summary = analyticsData?['summary'] ?? {};
    final monthlyData = analyticsData?['monthlyData'] as List? ?? [];
    final performance = analyticsData?['performance'] ?? {};
    final categories = analyticsData?['categories'] as List? ?? [];

    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 250,
            showBackButton: true,
            title: l10n.analytics,
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerNotificationsPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Badge(
                    isLabelVisible: false,
                    child: Icon(Iconsax.notification, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalMonthlyIncome,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'ETB ${(summary['totalReceived'] ?? 0).toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildMonthDropdown(l10n),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Chart
                  if (monthlyData.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (monthlyData.fold(
                                        0.0,
                                        (max, e) => (e['expected'] > max)
                                            ? e['expected'].toDouble()
                                            : max,
                                      ) *
                                      1.2)
                                  .clamp(100.0, double.infinity),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) =>
                                    _getTitles(val, meta, monthlyData, l10n),
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(monthlyData.length, (index) {
                            final data = monthlyData[index];
                            return _makeGroup(
                              index,
                              (data['received'] as num).toDouble(),
                              (data['expected'] as num).toDouble(),
                            );
                          }),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          context,
                          l10n.paid,
                          'ETB ${summary['totalReceived'] ?? 0}',
                          Iconsax.export_1,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryBox(
                          context,
                          l10n.due,
                          'ETB ${summary['totalDue'] ?? 0}',
                          Iconsax.import_1,
                          const Color(0xFFFFD541),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories', // Use l10n if available
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedPropertyType != null)
                        TextButton(
                          onPressed: () {
                            setState(() => selectedPropertyType = null);
                            _fetchAnalytics(
                              month:
                                  currentMonthIndex != null &&
                                      currentMonthIndex! > 0
                                  ? currentMonthIndex! - 1
                                  : null,
                            );
                          },
                          child: Text(l10n.all),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final label = cat['label'] as String;
                        final isSelected = selectedPropertyType == label;
                        return _buildCategoryChip(label, isSelected, () {
                          setState(
                            () => selectedPropertyType = isSelected
                                ? null
                                : label,
                          );
                          _fetchAnalytics(
                            month:
                                currentMonthIndex != null &&
                                    currentMonthIndex! > 0
                                ? currentMonthIndex! - 1
                                : null,
                            propertyType: selectedPropertyType,
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.overallPerformance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Occupancy Rate',
                          '${performance['occupancyRate']}%',
                          Iconsax.user_octagon,
                          AppColors.success,
                        ),
                        const Divider(height: 32),
                        _buildStatRow(
                          'Annual Growth',
                          '+${performance['annualGrowth']}%',
                          Iconsax.trend_up,
                          AppColors.primary,
                        ),
                        const Divider(height: 32),
                        _buildStatRow(
                          'Avg. Rent/Unit',
                          'ETB ${performance['avgRentPerUnit']}',
                          Iconsax.wallet,
                          AppColors.warning,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildReportButton(context, l10n),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown(L10n l10n) {
    final List<String> monthNames = [
      l10n.all,
      l10n.monthJan,
      l10n.monthFeb,
      l10n.monthMar,
      l10n.monthApr,
      l10n.monthMay,
      l10n.monthJun,
      l10n.monthJul,
      l10n.monthAug,
      l10n.monthSep,
      l10n.monthOct,
      l10n.monthNov,
      l10n.monthDec,
    ];

    return ModernDropdown<int>(
      value: currentMonthIndex ?? 0,
      items: List.generate(monthNames.length, (index) {
        return DropdownMenuItem<int>(
          value: index,
          child: Text(monthNames[index]),
        );
      }),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() => currentMonthIndex = newValue);
          _fetchAnalytics(
            month: newValue == 0 ? null : newValue - 1,
            propertyType: selectedPropertyType,
          );
        }
      },
    );
  }

  Widget _buildSummaryBox(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              amount,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, L10n l10n) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OwnerGenerateReportsPage(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.document_text,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                l10n.generateReport,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.primary,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: const Color(0xFFFFD541),
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _getTitles(
    double value,
    TitleMeta meta,
    List monthlyData,
    L10n l10n,
  ) {
    if (value.toInt() < 0 || value.toInt() >= monthlyData.length)
      return const SizedBox();
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(
        monthlyData[value.toInt()]['month'],
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
