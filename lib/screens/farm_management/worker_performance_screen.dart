// lib/screens/farm_management/worker_performance_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/farm_management_provider.dart';
import '../../models/farm_management_model.dart';
import '../../models/task_activity_model.dart';
import '../../services/farm_management_database_service.dart';
import '../../services/task_activity_database_service.dart';

class WorkerPerformanceScreen extends StatefulWidget {
  const WorkerPerformanceScreen({super.key});

  @override
  State<WorkerPerformanceScreen> createState() =>
      _WorkerPerformanceScreenState();
}

class _WorkerPerformanceScreenState
    extends State<WorkerPerformanceScreen> {
  WorkerModel? _selectedWorker;
  _PerformanceData? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fmProvider = context.read<FarmManagementProvider>();
      final farm = fmProvider.selectedFarm;
      if (farm != null && fmProvider.workers.isEmpty) {
        fmProvider.loadWorkers(farm.id);
      }
      final worker = fmProvider.currentWorker ??
          fmProvider.workers
              .where((w) => w.status == WorkerStatus.approved)
              .firstOrNull;
      if (worker != null) {
        setState(() => _selectedWorker = worker);
        _loadData(worker.id);
      }
    });
  }

  Future<void> _loadData(String workerId) async {
    setState(() => _loading = true);
    final data = await _PerformanceData.load(workerId);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmProvider = context.watch<FarmManagementProvider>();
    final approvedWorkers = fmProvider.workers
        .where((w) => w.status == WorkerStatus.approved)
        .toList();
    final isWorkerView = fmProvider.currentWorker != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Performance')),
      body: Column(
        children: [
          if (!isWorkerView && approvedWorkers.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<WorkerModel>(
                value: _selectedWorker,
                decoration: const InputDecoration(
                  labelText: 'Select Worker',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.primary),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                items: approvedWorkers
                    .map((w) => DropdownMenuItem(
                        value: w, child: Text(w.fullName)))
                    .toList(),
                onChanged: (w) {
                  if (w != null) {
                    setState(() => _selectedWorker = w);
                    _loadData(w.id);
                  }
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _data == null || _selectedWorker == null
                    ? _EmptyState(
                        hasWorkers: approvedWorkers.isNotEmpty)
                    : _PerformanceDashboard(
                        worker: _selectedWorker!,
                        data: _data!,
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Performance data loader ───────────────────────────────
class _PerformanceData {
  final double totalHoursThisMonth;
  final double totalHoursAllTime;
  final int daysWorked;
  final int lateClockIns;
  final int tasksAssigned;
  final int tasksCompleted;
  final int tasksPending;
  final int tasksOverdue;
  final double attendanceRate;
  final double completionRate;
  final List<_WeeklyHours> weeklyTrend;

  const _PerformanceData({
    required this.totalHoursThisMonth,
    required this.totalHoursAllTime,
    required this.daysWorked,
    required this.lateClockIns,
    required this.tasksAssigned,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.tasksOverdue,
    required this.attendanceRate,
    required this.completionRate,
    required this.weeklyTrend,
  });

  static Future<_PerformanceData> load(String workerId) async {
    final allRecords =
        await FarmManagementDatabaseService.getClockHistory(workerId);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double totalHoursMonth = 0;
    double totalHoursAll = 0;
    int lateClockIns = 0;
    final Set<String> daysSet = {};

    for (final r in allRecords) {
      if (r.hoursWorked != null) totalHoursAll += r.hoursWorked!;
      daysSet.add(
          '${r.clockInTime.year}-${r.clockInTime.month}-${r.clockInTime.day}');
      if (r.clockInTime.hour > 8 ||
          (r.clockInTime.hour == 8 && r.clockInTime.minute > 30)) {
        lateClockIns++;
      }
      if (r.clockInTime.isAfter(monthStart) &&
          r.hoursWorked != null) {
        totalHoursMonth += r.hoursWorked!;
      }
    }

    int workingDays = 0;
    for (int d = 1; d <= now.day; d++) {
      if (DateTime(now.year, now.month, d).weekday !=
          DateTime.sunday) workingDays++;
    }
    final monthRecordDays = allRecords
        .where((r) => r.clockInTime.isAfter(monthStart))
        .map((r) =>
            '${r.clockInTime.year}-${r.clockInTime.month}-${r.clockInTime.day}')
        .toSet()
        .length;
    final attendanceRate = workingDays == 0
        ? 0.0
        : (monthRecordDays / workingDays).clamp(0.0, 1.0);

    final tasks =
        await TaskActivityDatabaseService.getTasksByWorker(workerId);
    final assigned = tasks.length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending =
        tasks.where((t) => t.status == TaskStatus.pending).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final completionRate = assigned == 0
        ? 0.0
        : (completed / assigned).clamp(0.0, 1.0);

    final weeklyTrend = <_WeeklyHours>[];
    for (int w = 5; w >= 0; w--) {
      final weekStart =
          now.subtract(Duration(days: now.weekday - 1 + (w * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      double hours = 0;
      for (final r in allRecords) {
        if (r.clockInTime.isAfter(
                weekStart.subtract(const Duration(seconds: 1))) &&
            r.clockInTime
                .isBefore(weekEnd.add(const Duration(days: 1))) &&
            r.hoursWorked != null) {
          hours += r.hoursWorked!;
        }
      }
      weeklyTrend
          .add(_WeeklyHours(label: 'W${6 - w}', hours: hours));
    }

    return _PerformanceData(
      totalHoursThisMonth: totalHoursMonth,
      totalHoursAllTime: totalHoursAll,
      daysWorked: daysSet.length,
      lateClockIns: lateClockIns,
      tasksAssigned: assigned,
      tasksCompleted: completed,
      tasksPending: pending,
      tasksOverdue: overdue,
      attendanceRate: attendanceRate,
      completionRate: completionRate,
      weeklyTrend: weeklyTrend,
    );
  }
}

class _WeeklyHours {
  final String label;
  final double hours;
  const _WeeklyHours({required this.label, required this.hours});
}

// ── Dashboard ─────────────────────────────────────────────
class _PerformanceDashboard extends StatelessWidget {
  final WorkerModel worker;
  final _PerformanceData data;
  const _PerformanceDashboard(
      {required this.worker, required this.data});

  @override
  Widget build(BuildContext context) {
    final attPct = (data.attendanceRate * 100).toStringAsFixed(0);
    final cmpPct = (data.completionRate * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkerHeaderCard(worker: worker),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  label: 'Attendance',
                  value: '$attPct%',
                  icon: Icons.event_available_outlined,
                  color: data.attendanceRate >= 0.8
                      ? AppColors.success
                      : data.attendanceRate >= 0.6
                          ? AppColors.warning
                          : AppColors.error,
                  progress: data.attendanceRate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreCard(
                  label: 'Task Completion',
                  value: '$cmpPct%',
                  icon: Icons.task_alt_outlined,
                  color: data.completionRate >= 0.8
                      ? AppColors.success
                      : data.completionRate >= 0.5
                          ? AppColors.warning
                          : AppColors.error,
                  progress: data.completionRate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('This Month', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _StatTile(
                label: 'Hours Worked',
                value: data.totalHoursThisMonth.toStringAsFixed(1),
                unit: 'hrs',
                icon: Icons.access_time_outlined,
                color: AppColors.primary,
              ),
              _StatTile(
                label: 'Days Present',
                value: '${data.daysWorked}',
                unit: 'days',
                icon: Icons.calendar_today_outlined,
                color: AppColors.info,
              ),
              _StatTile(
                label: 'Tasks Done',
                value: '${data.tasksCompleted}',
                unit: 'of ${data.tasksAssigned}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              _StatTile(
                label: 'Late Clock-Ins',
                value: '${data.lateClockIns}',
                unit: 'times',
                icon: Icons.alarm_outlined,
                color: data.lateClockIns == 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Task Summary', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _TaskBreakdownCard(data: data),
          const SizedBox(height: 20),

          Text('Weekly Hours (Last 6 Weeks)',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _WeeklyBarChart(trend: data.weeklyTrend),
          const SizedBox(height: 20),

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
                const Icon(Icons.star_outline,
                    color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All-Time Total',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70)),
                    Text(
                      '${data.totalHoursAllTime.toStringAsFixed(1)} hours worked',
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      '${data.tasksCompleted} tasks completed',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerHeaderCard extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerHeaderCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                worker.fullName.isNotEmpty
                    ? worker.fullName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.fullName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  '${worker.role == WorkerRole.supervisor ? '🎯 Supervisor' : '👷 Field Worker'}  •  ${worker.phone}',
                  style: AppTextStyles.caption,
                ),
                Text(worker.farmCode,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.heading2.copyWith(color: color)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value,
                      style: AppTextStyles.heading2
                          .copyWith(color: color)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(unit,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskBreakdownCard extends StatelessWidget {
  final _PerformanceData data;
  const _TaskBreakdownCard({required this.data});

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
          _TaskRow(
              label: 'Completed',
              count: data.tasksCompleted,
              total: data.tasksAssigned,
              color: AppColors.success),
          const Divider(height: 16),
          _TaskRow(
              label: 'Pending',
              count: data.tasksPending,
              total: data.tasksAssigned,
              color: AppColors.info),
          const Divider(height: 16),
          _TaskRow(
              label: 'Overdue',
              count: data.tasksOverdue,
              total: data.tasksAssigned,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _TaskRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, style: AppTextStyles.bodySmall)),
        Text('$count',
            style: AppTextStyles.body.copyWith(
                color: color, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<_WeeklyHours> trend;
  const _WeeklyBarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxH =
        trend.fold(0.0, (m, w) => w.hours > m ? w.hours : m);
    final chartMax =
        maxH < 8 ? 8.0 : (maxH * 1.2).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((w) {
                final barH = chartMax == 0
                    ? 0.0
                    : (w.hours / chartMax) * 110;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (w.hours > 0)
                          Text(
                            w.hours.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 10),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 500),
                          height: barH,
                          decoration: BoxDecoration(
                            color: barH > 0
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius:
                                const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(w.label,
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Text('Target: 48 hrs / week (Mon–Sat)',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasWorkers;
  const _EmptyState({required this.hasWorkers});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              hasWorkers
                  ? 'Select a worker to view performance'
                  : 'No approved workers yet',
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!hasWorkers) ...[
              const SizedBox(height: 8),
              Text(
                'Approve workers in Worker Onboarding first.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}