// lib/screens/analytics/advanced_analytics_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/payroll_fieldreport_provider.dart';
import '../../models/farm_management_model.dart';
import '../../models/task_activity_model.dart';
import '../../models/payroll_fieldreport_model.dart';
import '../../services/farm_management_database_service.dart';
import '../farm_management/farm_management_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class _AnalyticsData {
  final double totalLaborHours;
  final double totalPayrollPaid;
  final double totalPayrollPending;
  final int totalWorkers;
  final Map<String, double> workerHoursMap;
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int totalReports;
  final int urgentReports;
  final List<_MonthStat> monthlyStats;

  const _AnalyticsData({
    required this.totalLaborHours,
    required this.totalPayrollPaid,
    required this.totalPayrollPending,
    required this.totalWorkers,
    required this.workerHoursMap,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.totalReports,
    required this.urgentReports,
    required this.monthlyStats,
  });
}

class _MonthStat {
  final String label;
  final double hours;
  final double payroll;
  const _MonthStat(this.label, this.hours, this.payroll);
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState
    extends State<AdvancedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  _AnalyticsData? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fmProvider = context.read<FarmManagementProvider>();
    final prProvider = context.read<PayrollFieldReportProvider>();
    final farm = fmProvider.selectedFarm ??
        (fmProvider.farms.isNotEmpty ? fmProvider.farms.first : null);
    if (farm == null) return;

    setState(() => _loading = true);

    await fmProvider.loadWorkers(farm.id);
    await fmProvider.loadTasks(farm.id);
    await prProvider.loadPayroll(farm.id);
    await prProvider.loadFieldReports(farm.id);

    final workers = fmProvider.workers
        .where((w) => w.status == WorkerStatus.approved)
        .toList();
    final tasks = fmProvider.tasks;
    final payroll = prProvider.payrollRecords;
    final reports = prProvider.fieldReports;

    // Worker hours map
    final workerHoursMap = <String, double>{};
    double totalHours = 0;
    for (final w in workers) {
      final hist =
          await FarmManagementDatabaseService.getClockHistory(w.id);
      final h =
          hist.fold<double>(0, (s, r) => s + (r.hoursWorked ?? 0));
      workerHoursMap[w.fullName] = h;
      totalHours += h;
    }

    final paid = payroll
        .where((p) => p.status == PayrollStatus.paid)
        .fold<double>(0, (s, p) => s + p.totalAmountUsd);
    final pending = payroll
        .where((p) => p.status == PayrollStatus.pending)
        .fold<double>(0, (s, p) => s + p.totalAmountUsd);

    // Monthly stats — last 6 months
    final now = DateTime.now();
    final monthly = <_MonthStat>[];
    for (int m = 5; m >= 0; m--) {
      final mStart = DateTime(now.year, now.month - m, 1);
      final mEnd = DateTime(mStart.year, mStart.month + 1, 0);
      double mHours = 0;
      for (final w in workers) {
        final hist =
            await FarmManagementDatabaseService.getClockHistory(w.id);
        mHours += hist
            .where((r) =>
                r.clockInTime.isAfter(mStart) &&
                r.clockInTime.isBefore(mEnd))
            .fold<double>(0, (s, r) => s + (r.hoursWorked ?? 0));
      }
      final mPayroll = payroll
          .where((p) =>
              p.periodStart.isAfter(mStart) &&
              p.periodStart.isBefore(mEnd))
          .fold<double>(0, (s, p) => s + p.totalAmountUsd);
      monthly.add(
          _MonthStat(DateFormat('MMM').format(mStart), mHours, mPayroll));
    }

    setState(() {
      _data = _AnalyticsData(
        totalLaborHours: totalHours,
        totalPayrollPaid: paid,
        totalPayrollPending: pending,
        totalWorkers: workers.length,
        workerHoursMap: workerHoursMap,
        totalTasks: tasks.length,
        completedTasks:
            tasks.where((t) => t.status == TaskStatus.completed).length,
        overdueTasks: tasks.where((t) => t.isOverdue).length,
        pendingTasks:
            tasks.where((t) => t.status == TaskStatus.pending).length,
        inProgressTasks:
            tasks.where((t) => t.status == TaskStatus.inProgress).length,
        totalReports: reports.length,
        urgentReports:
            reports.where((r) => r.requiresOwnerAttention).length,
        monthlyStats: monthly,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmProvider = context.watch<FarmManagementProvider>();
    final farm = fmProvider.selectedFarm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Labour'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Farm selector if multiple
          if (fmProvider.farms.length > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<FarmEntity>(
                value: farm,
                decoration: const InputDecoration(
                  labelText: 'Select Farm',
                  prefixIcon: Icon(Icons.home_outlined,
                      color: AppColors.primary),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                items: fmProvider.farms
                    .map((f) => DropdownMenuItem(
                        value: f, child: Text(f.farmName)))
                    .toList(),
                onChanged: (f) {
                  if (f != null) {
                    fmProvider.selectFarm(f);
                    _load();
                  }
                },
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _data == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.analytics_outlined,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('No data yet.',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _OverviewTab(
                              data: _data!, farm: farm),
                          _LabourTab(data: _data!),
                          _TasksTab(data: _data!),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final _AnalyticsData data;
  final FarmEntity? farm;
  const _OverviewTab({required this.data, this.farm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (farm != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farm!.farmName,
                            style: AppTextStyles.heading3
                                .copyWith(color: Colors.white)),
                        Text(
                          '${farm!.sizeHectares} ha  •  ${farm!.district}  •  ${farm!.farmCode}',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          Text('Summary', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _OverviewTile(
                label: 'Workers',
                value: '${data.totalWorkers}',
                sub: 'approved',
                icon: Icons.group_outlined,
                color: AppColors.primary,
              ),
              _OverviewTile(
                label: 'Labour Hours',
                value: data.totalLaborHours.toStringAsFixed(0),
                sub: 'all-time',
                icon: Icons.access_time_outlined,
                color: AppColors.info,
              ),
              _OverviewTile(
                label: 'Tasks Done',
                value: '${data.completedTasks}',
                sub: 'of ${data.totalTasks} total',
                icon: Icons.task_alt_outlined,
                color: AppColors.success,
              ),
              _OverviewTile(
                label: 'Payroll Paid',
                value:
                    '\$${data.totalPayrollPaid.toStringAsFixed(0)}',
                sub: 'USD all-time',
                icon: Icons.payments_outlined,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Activity Flags', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _ActivityFlagsCard(data: data),
          const SizedBox(height: 20),

          Text('Labour Trend — Last 6 Months',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _BarChart(
            bars: data.monthlyStats
                .map((s) =>
                    _BarData(label: s.label, value: s.hours))
                .toList(),
            color: AppColors.primary,
            unit: 'h',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Labour Tab
// ─────────────────────────────────────────────────────────────
class _LabourTab extends StatelessWidget {
  final _AnalyticsData data;
  const _LabourTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = data.workerHoursMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxH = sorted.isNotEmpty ? sorted.first.value : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Total Hours',
                  value: data.totalLaborHours.toStringAsFixed(1),
                  icon: Icons.access_time_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Pending Payout',
                  value:
                      '\$${data.totalPayrollPending.toStringAsFixed(0)}',
                  icon: Icons.pending_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Paid Out',
                  value:
                      '\$${data.totalPayrollPaid.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Workers',
                  value: '${data.totalWorkers}',
                  icon: Icons.group_outlined,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Hours by Worker', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: sorted.take(10).map((e) {
                final pct = e.value / maxH;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(e.key,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.08),
                            valueColor:
                                const AlwaysStoppedAnimation(
                                    AppColors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          '${e.value.toStringAsFixed(1)}h',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          Text('Monthly Payroll — Last 6 Months',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _BarChart(
            bars: data.monthlyStats
                .map((s) =>
                    _BarData(label: s.label, value: s.payroll))
                .toList(),
            color: AppColors.accent,
            unit: '\$',
            prefix: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tasks Tab
// ─────────────────────────────────────────────────────────────
class _TasksTab extends StatelessWidget {
  final _AnalyticsData data;
  const _TasksTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final completionPct = data.totalTasks == 0
        ? 0.0
        : (data.completedTasks / data.totalTasks).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion gauge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Completion',
                    style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${(completionPct * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.heading1.copyWith(
                                color: completionPct >= 0.7
                                    ? AppColors.success
                                    : AppColors.warning),
                          ),
                          Text(
                              '${data.completedTasks} of ${data.totalTasks}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _HorizBar(
                              label: 'Done',
                              count: data.completedTasks,
                              total: data.totalTasks,
                              color: AppColors.success),
                          const SizedBox(height: 8),
                          _HorizBar(
                              label: 'Pending',
                              count: data.pendingTasks,
                              total: data.totalTasks,
                              color: AppColors.info),
                          const SizedBox(height: 8),
                          _HorizBar(
                              label: 'Active',
                              count: data.inProgressTasks,
                              total: data.totalTasks,
                              color: AppColors.primary),
                          const SizedBox(height: 8),
                          _HorizBar(
                              label: 'Overdue',
                              count: data.overdueTasks,
                              total: data.totalTasks,
                              color: AppColors.error),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Field Reports', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                      label: 'Total Reports',
                      value: '${data.totalReports}',
                      color: AppColors.info),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.divider),
                Expanded(
                  child: _MiniStat(
                      label: 'Urgent',
                      value: '${data.urgentReports}',
                      color: data.urgentReports > 0
                          ? AppColors.error
                          : AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────
class _OverviewTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  const _OverviewTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style:
                      AppTextStyles.heading2.copyWith(color: color)),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(sub, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityFlagsCard extends StatelessWidget {
  final _AnalyticsData data;
  const _ActivityFlagsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _FlagRow(
              icon: Icons.report_outlined,
              label: 'Field Reports',
              value: data.totalReports,
              badge: data.urgentReports > 0
                  ? '${data.urgentReports} urgent'
                  : null,
              color: AppColors.warning),
          const Divider(height: 16),
          _FlagRow(
              icon: Icons.warning_amber_outlined,
              label: 'Overdue Tasks',
              value: data.overdueTasks,
              badge: data.overdueTasks > 0 ? 'Needs attention' : null,
              color: AppColors.error),
          const Divider(height: 16),
          _FlagRow(
              icon: Icons.pending_outlined,
              label: 'Payroll Pending',
              value: 0,
              badge: data.totalPayrollPending > 0
                  ? '\$${data.totalPayrollPending.toStringAsFixed(0)}'
                  : null,
              color: AppColors.info),
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String? badge;
  final Color color;
  const _FlagRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, style: AppTextStyles.bodySmall)),
        if (badge != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge!,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
        Text('$value',
            style: AppTextStyles.body.copyWith(
                color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BarData {
  final String label;
  final double value;
  const _BarData({required this.label, required this.value});
}

class _BarChart extends StatelessWidget {
  final List<_BarData> bars;
  final Color color;
  final String unit;
  final bool prefix;
  const _BarChart({
    required this.bars,
    required this.color,
    required this.unit,
    this.prefix = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = bars.fold(0.0, (m, b) => b.value > m ? b.value : m);
    final chartMax = maxV < 1 ? 1.0 : (maxV * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((b) {
            final barH = (b.value / chartMax) * 110;
            final isLast = bars.last == b;
            final labelStr = prefix
                ? '$unit${b.value.toStringAsFixed(0)}'
                : '${b.value.toStringAsFixed(0)}$unit';
            return Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (b.value > 0)
                      Text(labelStr,
                          style: AppTextStyles.caption.copyWith(
                              color: isLast
                                  ? color
                                  : AppColors.textSecondary,
                              fontSize: 9)),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: barH,
                      decoration: BoxDecoration(
                        color: isLast
                            ? color
                            : color.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(b.label,
                        style: AppTextStyles.caption
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style:
                      AppTextStyles.heading2.copyWith(color: color)),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.heading2.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _HorizBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _HorizBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$count',
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}