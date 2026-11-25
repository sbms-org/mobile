import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pm/core/services/secure_storage_service.dart';
import 'package:pm/features/owner/presentation/pages/owner_notifications_page.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/modern_dropdown.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/api/owner_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'owner_analytics_page.dart';
import 'owner_buildings_page.dart';
import 'owner_generate_reports_page.dart';
import 'owner_pending_receipts_page.dart';

class OwnerHomePage extends ConsumerStatefulWidget {
  const OwnerHomePage({super.key});

  @override
  ConsumerState<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends ConsumerState<OwnerHomePage> {
  String _name = 'Loading...';
  String? _userId;
  DashboardStats? _stats;
  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  int? _selectedMonthIndex; // interactive month selector in income section

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userData = await SecureStorageService.getUserData();
    if (!mounted) return;
    if (userData != null) {
      setState(() {
        _name = userData['name'] ?? 'Owner';
        _userId = userData['id'];
      });
    }
    await Future.wait([
      _loadDashboard(),
      _loadAnalytics(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadDashboard() async {
    try {
      if (_userId == null) return;
      final response = await OwnerApi.getDashboard(_userId!);
      if (mounted && response.success && response.data != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _stats = response.data;
            _isLoading = false;
          });
        });
      } else {
        if (mounted)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final response = await OwnerApi.getAnalytics();
      if (mounted && response.success && response.data != null) {
        final raw = response.data!['monthlyData'] as List<dynamic>? ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _monthlyData = raw.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await OwnerApi.getNotifications();
      if (mounted && response.success && response.data != null) {
        final unread = (response.data as List)
            .where((n) => n['is_read'] == false)
            .length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _unreadCount = unread);
        });
      }
    } catch (_) {}
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'ETB ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'ETB ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'ETB ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final stats = _stats;
    final hasOverdue = (stats?.overduePayments ?? 0) > 0;
    final occupancyPct = stats != null && stats.totalUnits > 0
        ? stats.occupancyRate / 100
        : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              CurvedSection(
                height: 280,
                title: _name,
                subtitle: l10n.goodMorning,
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
                      child: Badge(
                        label: Text(_unreadCount > 0 ? '$_unreadCount' : ''),
                        isLabelVisible: _unreadCount > 0,
                        child: const Icon(
                          Iconsax.notification,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Overlapping Quick Actions Card
              Transform.translate(
                offset: const Offset(0, -60),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.home,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAction(
                            context,
                            Iconsax.building,
                            l10n.buildings,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OwnerBuildingsPage(),
                                ),
                              );
                            },
                          ),
                          _buildQuickAction(
                            context,
                            Iconsax.receipt,
                            l10n.pendingReceipts,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OwnerPendingReceiptsPage(),
                                ),
                              );
                            },
                          ),
                          _buildQuickAction(
                            context,
                            Iconsax.document_text,
                            l10n.reports,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OwnerGenerateReportsPage(),
                                ),
                              );
                            },
                          ),
                          _buildQuickAction(
                            context,
                            Iconsax.chart_2,
                            l10n.analytics,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OwnerAnalyticsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Grid
              Transform.translate(
                offset: const Offset(0, -40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: LinearProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    '${stats?.totalBuildings ?? 0}',
                                    l10n.totalBuildings,
                                    Iconsax.building_3,
                                    const Color(0xFFF0F4FF),
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    '${stats?.totalUnits ?? 0}',
                                    l10n.totalUnits,
                                    Iconsax.house,
                                    const Color(0xFFF0F4FF),
                                    AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    '${stats?.occupiedUnits ?? 0}',
                                    l10n.occupied,
                                    Iconsax.tick_circle,
                                    const Color(0xFFE3F2FD),
                                    AppColors.success,
                                    percentage:
                                        stats != null && stats.totalUnits > 0
                                        ? '${stats.occupancyRate.toStringAsFixed(1)}%'
                                        : '0%',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    '${stats?.vacantUnits ?? 0}',
                                    l10n.vacantUnits,
                                    Iconsax.close_circle,
                                    const Color(0xFFFFF0F0),
                                    AppColors.error,
                                    percentage:
                                        stats != null && stats.totalUnits > 0
                                        ? '${(100 - stats.occupancyRate).toStringAsFixed(1)}%'
                                        : '0%',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),

              // Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        // fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.completedDueRents,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: occupancyPct.clamp(0.0, 1.0),
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            Text(
                              '${(occupancyPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Income Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalMonthlyIncome,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatCurrency(stats?.totalRevenue ?? 0),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        ModernDropdown<int>(
                          value: _selectedMonthIndex ?? 0,
                          hint: Text(l10n.thisMonth),
                          items: List.generate(13, (i) {
                            final months = [
                              l10n.thisMonth,
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
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(months[i]),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedMonthIndex = v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _computeMaxY(),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: _getTitlesWidget,
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
                          barGroups: _buildBarGroups(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overdue Alert — only shown when there are overdue payments
              if (hasOverdue)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFCDCD)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.danger,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${l10n.overduePayments}: ${stats?.overduePayments ?? 0}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(text: '${l10n.outstanding} '),
                              TextSpan(
                                text: _formatCurrency(
                                  stats?.overdueAmount ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(text: '\n${l10n.notifiedTenants}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  double _computeMaxY() {
    if (_monthlyData.isEmpty) return 200;
    double max = 0;
    for (final m in _monthlyData) {
      final received = (m['received'] as num?)?.toDouble() ?? 0;
      final expected = (m['expected'] as num?)?.toDouble() ?? 0;
      if (received > max) max = received;
      if (expected > max) max = expected;
    }
    return max > 0 ? max * 1.2 : 200;
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_monthlyData.isEmpty) {
      return List.generate(6, (i) => _makeGroup(i, 0, 0));
    }
    return List.generate(_monthlyData.length, (i) {
      final m = _monthlyData[i];
      final received = (m['received'] as num?)?.toDouble() ?? 0;
      final expected = (m['expected'] as num?)?.toDouble() ?? 0;
      return _makeGroup(i, received, expected);
    });
  }

  Widget _getTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text = '';
    if (_monthlyData.isNotEmpty) {
      final idx = value.toInt();
      if (idx >= 0 && idx < _monthlyData.length) {
        text = _monthlyData[idx]['month']?.toString() ?? '';
      }
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      final idx = value.toInt();
      if (idx >= 0 && idx < months.length) text = months[idx];
    }
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    String? percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (percentage != null)
                Text(
                  percentage,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
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
}
