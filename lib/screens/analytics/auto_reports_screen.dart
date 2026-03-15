// lib/screens/analytics/auto_reports_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/payroll_fieldreport_provider.dart';
import '../../models/farm_management_model.dart';
import '../../models/task_activity_model.dart';
import '../../models/payroll_fieldreport_model.dart';
import '../../services/farm_management_database_service.dart';

// ─────────────────────────────────────────────────────────────
// Report type
// ─────────────────────────────────────────────────────────────
enum ReportType { weekly, monthly, custom }

extension ReportTypeX on ReportType {
  String get label {
    switch (this) {
      case ReportType.weekly:  return 'Weekly';
      case ReportType.monthly: return 'Monthly';
      case ReportType.custom:  return 'Custom';
    }
  }
  String get emoji {
    switch (this) {
      case ReportType.weekly:  return '📅';
      case ReportType.monthly: return '🗓️';
      case ReportType.custom:  return '🔧';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Report data model
// ─────────────────────────────────────────────────────────────
class _ReportData {
  final String farmName;
  final String farmCode;
  final String ownerName;
  final DateTime from;
  final DateTime to;
  final int totalWorkers;
  final double totalHours;
  final int totalClockIns;
  final int lateClockIns;
  final Map<String, double> workerHours;
  final double totalPaid;
  final double totalPending;
  final int payrollCount;
  final int tasksTotal;
  final int tasksCompleted;
  final int tasksPending;
  final int tasksOverdue;
  final int reportsTotal;
  final int reportsUrgent;
  final List<String> urgentReportTitles;
  final int photoCount;

  const _ReportData({
    required this.farmName,
    required this.farmCode,
    required this.ownerName,
    required this.from,
    required this.to,
    required this.totalWorkers,
    required this.totalHours,
    required this.totalClockIns,
    required this.lateClockIns,
    required this.workerHours,
    required this.totalPaid,
    required this.totalPending,
    required this.payrollCount,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.tasksOverdue,
    required this.reportsTotal,
    required this.reportsUrgent,
    required this.urgentReportTitles,
    required this.photoCount,
  });

  static Future<_ReportData> load({
    required FarmEntity farm,
    required String ownerName,
    required DateTime from,
    required DateTime to,
    required List<dynamic> workers,
    required List<TaskModel> tasks,
    required List<PayrollRecord> payroll,
    required List<FieldReport> reports,
    required List<PhotoEntry> photos,
  }) async {
    double totalHours = 0;
    int totalClockIns = 0;
    int lateClockIns = 0;
    final workerHours = <String, double>{};

    for (final w in workers) {
      final hist =
          await FarmManagementDatabaseService.getClockHistory(w.id);
      final inRange = hist.where((r) =>
          r.clockInTime.isAfter(from.subtract(const Duration(seconds: 1))) &&
          r.clockInTime.isBefore(to.add(const Duration(days: 1)))).toList();
      final wH = inRange.fold<double>(0, (s, r) => s + (r.hoursWorked ?? 0));
      workerHours[w.fullName] = wH;
      totalHours += wH;
      totalClockIns += inRange.length;
      lateClockIns += inRange.where((r) =>
          r.clockInTime.hour > 8 ||
          (r.clockInTime.hour == 8 && r.clockInTime.minute > 30)).length;
    }

    bool inRange(DateTime dt) =>
        dt.isAfter(from.subtract(const Duration(seconds: 1))) &&
        dt.isBefore(to.add(const Duration(days: 1)));

    final periodPayroll = payroll.where((p) => inRange(p.createdAt)).toList();
    final paid = periodPayroll
        .where((p) => p.status == PayrollStatus.paid)
        .fold<double>(0, (s, p) => s + p.totalAmountUsd);
    final pending = periodPayroll
        .where((p) => p.status == PayrollStatus.pending)
        .fold<double>(0, (s, p) => s + p.totalAmountUsd);

    final periodTasks = tasks.where((t) => inRange(t.createdAt)).toList();
    final periodReports = reports.where((r) => inRange(r.createdAt)).toList();
    final urgent = periodReports.where((r) => r.requiresOwnerAttention).toList();
    final periodPhotos = photos.where((p) => inRange(p.takenAt)).toList();

    return _ReportData(
      farmName: farm.farmName,
      farmCode: farm.farmCode,
      ownerName: ownerName,
      from: from,
      to: to,
      totalWorkers: workers.length,
      totalHours: totalHours,
      totalClockIns: totalClockIns,
      lateClockIns: lateClockIns,
      workerHours: workerHours,
      totalPaid: paid,
      totalPending: pending,
      payrollCount: periodPayroll.length,
      tasksTotal: periodTasks.length,
      tasksCompleted:
          periodTasks.where((t) => t.status == TaskStatus.completed).length,
      tasksPending:
          periodTasks.where((t) => t.status == TaskStatus.pending).length,
      tasksOverdue: periodTasks.where((t) => t.isOverdue).length,
      reportsTotal: periodReports.length,
      reportsUrgent: urgent.length,
      urgentReportTitles: urgent.map((r) => r.title).take(5).toList(),
      photoCount: periodPhotos.length,
    );
  }

  String toPlainText() {
    final fmt = DateFormat('dd MMM yyyy');
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║     AGRICASSIST ZW — FARM REPORT     ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln();
    buf.writeln('Farm      : $farmName ($farmCode)');
    buf.writeln('Owner     : $ownerName');
    buf.writeln('Period    : ${fmt.format(from)} → ${fmt.format(to)}');
    buf.writeln('Generated : ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}');
    buf.writeln();
    buf.writeln('──────────────────────────────────────');
    buf.writeln('👷 LABOUR SUMMARY');
    buf.writeln('──────────────────────────────────────');
    buf.writeln('Total Workers    : $totalWorkers');
    buf.writeln('Total Hours      : ${totalHours.toStringAsFixed(1)} hrs');
    buf.writeln('Clock-In Records : $totalClockIns');
    buf.writeln('Late Clock-Ins   : $lateClockIns');
    if (workerHours.isNotEmpty) {
      buf.writeln();
      buf.writeln('Hours by Worker:');
      final sorted = workerHours.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buf.writeln('  • ${e.key.padRight(22)} ${e.value.toStringAsFixed(1)} hrs');
      }
    }
    buf.writeln();
    buf.writeln('──────────────────────────────────────');
    buf.writeln('💰 PAYROLL SUMMARY');
    buf.writeln('──────────────────────────────────────');
    buf.writeln('Records     : $payrollCount');
    buf.writeln('Paid Out    : \$${totalPaid.toStringAsFixed(2)} USD');
    buf.writeln('Pending     : \$${totalPending.toStringAsFixed(2)} USD');
    buf.writeln();
    buf.writeln('──────────────────────────────────────');
    buf.writeln('✅ TASK SUMMARY');
    buf.writeln('──────────────────────────────────────');
    buf.writeln('Assigned   : $tasksTotal');
    buf.writeln('Completed  : $tasksCompleted');
    buf.writeln('Pending    : $tasksPending');
    buf.writeln('Overdue    : $tasksOverdue');
    if (tasksTotal > 0) {
      buf.writeln('Completion : ${((tasksCompleted / tasksTotal) * 100).toStringAsFixed(0)}%');
    }
    buf.writeln();
    buf.writeln('──────────────────────────────────────');
    buf.writeln('📋 FIELD REPORTS');
    buf.writeln('──────────────────────────────────────');
    buf.writeln('Total   : $reportsTotal');
    buf.writeln('Urgent  : $reportsUrgent');
    if (urgentReportTitles.isNotEmpty) {
      buf.writeln();
      buf.writeln('Urgent items:');
      for (final t in urgentReportTitles) {
        buf.writeln('  ⚠️  $t');
      }
    }
    buf.writeln();
    buf.writeln('──────────────────────────────────────');
    buf.writeln('📸 PHOTOS : $photoCount captured');
    buf.writeln('──────────────────────────────────────');
    buf.writeln();
    buf.writeln('Powered by AgricAssist ZW');
    buf.writeln('Sir Enocks Cor Technologies');
    return buf.toString();
  }

  String toCsv() {
    final fmt = DateFormat('dd/MM/yyyy');
    final buf = StringBuffer();
    buf.writeln('Section,Metric,Value');
    buf.writeln('Info,Farm,$farmName');
    buf.writeln('Info,Farm Code,$farmCode');
    buf.writeln('Info,Owner,$ownerName');
    buf.writeln('Info,Period From,${fmt.format(from)}');
    buf.writeln('Info,Period To,${fmt.format(to)}');
    buf.writeln('Labour,Total Workers,$totalWorkers');
    buf.writeln('Labour,Total Hours,${totalHours.toStringAsFixed(1)}');
    buf.writeln('Labour,Clock-In Records,$totalClockIns');
    buf.writeln('Labour,Late Clock-Ins,$lateClockIns');
    for (final e in workerHours.entries) {
      buf.writeln('Labour Worker,${e.key},${e.value.toStringAsFixed(1)}');
    }
    buf.writeln('Payroll,Records,$payrollCount');
    buf.writeln('Payroll,Paid USD,${totalPaid.toStringAsFixed(2)}');
    buf.writeln('Payroll,Pending USD,${totalPending.toStringAsFixed(2)}');
    buf.writeln('Tasks,Total,$tasksTotal');
    buf.writeln('Tasks,Completed,$tasksCompleted');
    buf.writeln('Tasks,Pending,$tasksPending');
    buf.writeln('Tasks,Overdue,$tasksOverdue');
    buf.writeln('Reports,Total,$reportsTotal');
    buf.writeln('Reports,Urgent,$reportsUrgent');
    buf.writeln('Photos,Count,$photoCount');
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class AutoReportsScreen extends StatefulWidget {
  const AutoReportsScreen({super.key});
  @override
  State<AutoReportsScreen> createState() => _AutoReportsScreenState();
}

class _AutoReportsScreenState extends State<AutoReportsScreen> {
  ReportType _reportType = ReportType.monthly;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  _ReportData? _reportData;
  bool _loading = false;
  bool _generated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fmProvider = context.read<FarmManagementProvider>();
      final farm = fmProvider.selectedFarm ??
          (fmProvider.farms.isNotEmpty ? fmProvider.farms.first : null);
      if (farm != null && fmProvider.workers.isEmpty) {
        fmProvider.loadWorkers(farm.id);
      }
    });
  }

  void _applyPreset(ReportType type) {
    final now = DateTime.now();
    setState(() {
      _reportType = type;
      switch (type) {
        case ReportType.weekly:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          _from = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _to = now;
          break;
        case ReportType.monthly:
          _from = DateTime(now.year, now.month, 1);
          _to = now;
          break;
        case ReportType.custom:
          break;
      }
      _generated = false;
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) { _from = picked; } else { _to = picked; }
        _generated = false;
      });
    }
  }

  Future<void> _generateReport() async {
    final fmProvider = context.read<FarmManagementProvider>();
    final prProvider = context.read<PayrollFieldReportProvider>();
    final authProvider = context.read<AuthProvider>();
    final farm = fmProvider.selectedFarm ??
        (fmProvider.farms.isNotEmpty ? fmProvider.farms.first : null);
    if (farm == null) return;

    setState(() => _loading = true);

    await fmProvider.loadWorkers(farm.id);
    await fmProvider.loadTasks(farm.id);
    await prProvider.loadPayroll(farm.id);
    await prProvider.loadFieldReports(farm.id);
    await prProvider.loadPhotos(farm.id);

    final data = await _ReportData.load(
      farm: farm,
      ownerName: authProvider.user?.fullName ?? 'Farm Owner',
      from: DateTime(_from.year, _from.month, _from.day),
      to: DateTime(_to.year, _to.month, _to.day, 23, 59, 59),
      workers: fmProvider.workers
          .where((w) => w.status == WorkerStatus.approved)
          .toList(),
      tasks: fmProvider.tasks,
      payroll: prProvider.payrollRecords,
      reports: prProvider.fieldReports,
      photos: prProvider.photos,
    );

    if (mounted) {
      setState(() { _reportData = data; _loading = false; _generated = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Reports'),
        actions: [
          if (_generated && _reportData != null) ...[
            IconButton(
              icon: const Icon(Icons.table_chart_outlined),
              tooltip: 'Export CSV',
              onPressed: () => Share.share(_reportData!.toCsv(),
                  subject: 'Farm Report CSV — ${_reportData!.farmName}'),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share via WhatsApp / Email',
              onPressed: () => Share.share(_reportData!.toPlainText(),
                  subject:
                      'Farm Report — ${_reportData!.farmName} — ${DateFormat('MMM yyyy').format(_from)}'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _ConfigPanel(
            reportType: _reportType,
            from: _from,
            to: _to,
            onTypeChanged: _applyPreset,
            onPickFrom: () => _pickDate(true),
            onPickTo: () => _pickDate(false),
            onGenerate: _generateReport,
            loading: _loading,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Generating report…',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ))
                : !_generated
                    ? _Prompt()
                    : _ReportView(data: _reportData!),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Config panel
// ─────────────────────────────────────────────────────────────
class _ConfigPanel extends StatelessWidget {
  final ReportType reportType;
  final DateTime from;
  final DateTime to;
  final void Function(ReportType) onTypeChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onGenerate;
  final bool loading;

  const _ConfigPanel({
    required this.reportType,
    required this.from,
    required this.to,
    required this.onTypeChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onGenerate,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ReportType.values.map((t) {
              final sel = t == reportType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onTypeChanged(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(t.emoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(t.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textPrimary),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateBtn(
                  label: 'From',
                  date: fmt.format(from),
                  active: reportType == ReportType.custom,
                  onTap: onPickFrom,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.textSecondary, size: 18),
              ),
              Expanded(
                child: _DateBtn(
                  label: 'To',
                  date: fmt.format(to),
                  active: reportType == ReportType.custom,
                  onTap: onPickTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onGenerate,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(loading ? 'Generating…' : 'Generate Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final String date;
  final bool active;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label,
      required this.date,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(date,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.primary
                        : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Prompt (before generation)
// ─────────────────────────────────────────────────────────────
class _Prompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.summarize_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Select a period, then tap Generate',
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your report will cover labour, payroll, tasks, '
              'field reports and photos — all in one summary.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Report view
// ─────────────────────────────────────────────────────────────
class _ReportView extends StatelessWidget {
  final _ReportData data;
  const _ReportView({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final taskPct = data.tasksTotal == 0
        ? 0.0
        : (data.tasksCompleted / data.tasksTotal).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
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
                const Icon(Icons.summarize_outlined,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.farmName,
                          style: AppTextStyles.heading3
                              .copyWith(color: Colors.white)),
                      Text(
                        '${fmt.format(data.from)} → ${fmt.format(data.to)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(data.farmCode,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // share tip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.share_outlined,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap the share icon above to send via WhatsApp/Email, or export as CSV.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Labour ───────────────────────────────────────
          _SecHeader(emoji: '👷', title: 'Labour Summary'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _Tile(label: 'Workers', value: '${data.totalWorkers}',
                  icon: Icons.group_outlined, color: AppColors.primary),
              _Tile(
                  label: 'Total Hours',
                  value: '${data.totalHours.toStringAsFixed(1)} hrs',
                  icon: Icons.access_time_outlined,
                  color: AppColors.info),
              _Tile(
                  label: 'Clock-Ins',
                  value: '${data.totalClockIns}',
                  icon: Icons.login_outlined,
                  color: AppColors.success),
              _Tile(
                  label: 'Late Clock-Ins',
                  value: '${data.lateClockIns}',
                  icon: Icons.alarm_outlined,
                  color: data.lateClockIns > 0
                      ? AppColors.warning
                      : AppColors.success),
            ],
          ),
          if (data.workerHours.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WorkerTable(hoursMap: data.workerHours),
          ],
          const SizedBox(height: 20),

          // ── Payroll ──────────────────────────────────────
          _SecHeader(emoji: '💰', title: 'Payroll Summary'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _Tile(
                  label: 'Paid Out',
                  value: '\$${data.totalPaid.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                  color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                  label: 'Pending',
                  value: '\$${data.totalPending.toStringAsFixed(2)}',
                  icon: Icons.pending_outlined,
                  color: AppColors.warning),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Tasks ────────────────────────────────────────
          _SecHeader(emoji: '✅', title: 'Task Summary'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${data.tasksTotal} tasks assigned',
                        style: AppTextStyles.bodySmall),
                    Text(
                      '${(taskPct * 100).toStringAsFixed(0)}% done',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: taskPct >= 0.7
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: taskPct,
                    backgroundColor:
                        AppColors.success.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(taskPct >= 0.7
                        ? AppColors.success
                        : AppColors.warning),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _Chip('Done', data.tasksCompleted, AppColors.success),
                  const SizedBox(width: 8),
                  _Chip('Pending', data.tasksPending, AppColors.info),
                  const SizedBox(width: 8),
                  _Chip('Overdue', data.tasksOverdue, AppColors.error),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Field Reports ────────────────────────────────
          _SecHeader(emoji: '📋', title: 'Field Reports'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('${data.reportsTotal}',
                            style: AppTextStyles.heading2
                                .copyWith(color: AppColors.info)),
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.divider),
                  Expanded(
                    child: Column(
                      children: [
                        Text('${data.reportsUrgent}',
                            style: AppTextStyles.heading2.copyWith(
                                color: data.reportsUrgent > 0
                                    ? AppColors.error
                                    : AppColors.success)),
                        const Text('Urgent',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ]),
                if (data.urgentReportTitles.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('Flagged items:',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error)),
                  const SizedBox(height: 6),
                  ...data.urgentReportTitles.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(t,
                                  style: AppTextStyles.caption)),
                        ]),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Photos ───────────────────────────────────────
          _SecHeader(emoji: '📸', title: 'Farm Photos'),
          const SizedBox(height: 10),
          _Tile(
            label: 'Photos Captured',
            value: '${data.photoCount}',
            icon: Icons.photo_library_outlined,
            color: AppColors.earth,
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Generated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} • AgricAssist ZW',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────
class _SecHeader extends StatelessWidget {
  final String emoji;
  final String title;
  const _SecHeader({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Tile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

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
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.heading2
                      .copyWith(color: color, fontSize: 17)),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerTable extends StatelessWidget {
  final Map<String, double> hoursMap;
  const _WorkerTable({required this.hoursMap});

  @override
  Widget build(BuildContext context) {
    final sorted = hoursMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxH = sorted.isNotEmpty ? sorted.first.value : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hours by Worker',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...sorted.map((e) {
            final pct = maxH == 0 ? 0.0 : e.value / maxH;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(
                  width: 100,
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
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value.toStringAsFixed(1)}h',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Chip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count $label',
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}