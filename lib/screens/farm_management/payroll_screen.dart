// lib/screens/farm_management/payroll_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../models/farm_management_model.dart';
import '../../models/payroll_fieldreport_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/payroll_fieldreport_provider.dart';
import 'farm_management_shared_widgets.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fmProvider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    if (fmProvider.selectedFarm == null) {
      await fmProvider.loadFarms(user.userId);
    }
    final farm = fmProvider.selectedFarm;
    if (farm != null) {
      await fmProvider.loadWorkers(farm.id);
      await context
          .read<PayrollFieldReportProvider>()
          .loadPayroll(farm.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payroll & EcoCash Payout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Run Payroll'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer2<FarmManagementProvider,
          PayrollFieldReportProvider>(
        builder: (ctx, fmProvider, prProvider, _) {
          final farm = fmProvider.selectedFarm;
          if (farm == null) return const _NoFarmWidget();
          return TabBarView(
            controller: _tabController,
            children: [
              _RunPayrollTab(
                  farm: farm, workers: fmProvider.workers),
              _PayrollHistoryTab(
                  records: prProvider.payrollRecords,
                  farm: farm),
            ],
          );
        },
      ),
    );
  }
}

// ── RUN PAYROLL TAB ───────────────────────────────────────
class _RunPayrollTab extends StatefulWidget {
  final FarmEntity farm;
  final List<WorkerModel> workers;
  const _RunPayrollTab(
      {required this.farm, required this.workers});

  @override
  State<_RunPayrollTab> createState() => _RunPayrollTabState();
}

class _RunPayrollTabState extends State<_RunPayrollTab> {
  final _rateCtrl = TextEditingController(text: '2.00');
  DateTime _from = DateTime.now()
      .subtract(const Duration(days: 7))
      .copyWith(hour: 0, minute: 0, second: 0);
  DateTime _to =
      DateTime.now().copyWith(hour: 23, minute: 59, second: 59);

  List<PayrollRecord> _preview = [];
  bool _isPreviewing = false;
  bool _isPaying = false;
  int _payingIndex = -1;

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  List<WorkerModel> get _approvedWorkers =>
      widget.workers
          .where((w) => w.status == WorkerStatus.approved)
          .toList();

  Future<void> _buildPreview() async {
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (rate == null || rate <= 0) {
      _showSnack('Enter a valid hourly rate', isError: true);
      return;
    }
    setState(() => _isPreviewing = true);
    final user = context.read<AuthProvider>().user!;
    final preview = await context
        .read<PayrollFieldReportProvider>()
        .previewPayroll(
          farmId: widget.farm.id,
          ownerId: user.userId,
          workers: _approvedWorkers,
          hourlyRateUsd: rate,
          from: _from,
          to: _to,
        );
    setState(() {
      _preview = preview;
      _isPreviewing = false;
    });
    if (preview.isEmpty) {
      _showSnack('No clock records found for this period.');
    }
  }

  Future<void> _payWorker(int index) async {
    setState(() {
      _isPaying = true;
      _payingIndex = index;
    });
    final record = _preview[index];
    final success = await context
        .read<PayrollFieldReportProvider>()
        .payWorker(
          record: record,
          paynowIntegrationId: AppConfig.paynowIntegrationId,
          paynowIntegrationKey: AppConfig.paynowIntegrationKey,
          returnUrl: 'https://agricassist.zw/payroll/return',
          resultUrl: 'https://agricassist.zw/payroll/result',
        );
    setState(() {
      _isPaying = false;
      _payingIndex = -1;
      if (success) _preview.removeAt(index);
    });
    _showSnack(
      success
          ? '✅ EcoCash payment sent to ${record.workerName}'
          : '❌ Payment failed — check history for details',
      isError: !success,
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked.copyWith(hour: 0, minute: 0, second: 0);
        } else {
          _to = picked.copyWith(hour: 23, minute: 59, second: 59);
        }
        _preview = [];
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollFieldReportProvider>();
    return RefreshIndicator(
      onRefresh: _buildPreview,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Farm banner ─────────────────────────
            FarmSectionHeader(
              icon: Icons.payments_outlined,
              color: AppColors.primary,
              title: 'Run Payroll',
              subtitle:
                  'Calculate & pay workers via EcoCash based on clock records',
            ),
            const SizedBox(height: 20),

            // ── Summary chips ────────────────────────
            Row(
              children: [
                _SummaryChip(
                  label: 'Approved Workers',
                  value: '${_approvedWorkers.length}',
                  color: AppColors.primary,
                  icon: Icons.people_outline,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Total Paid',
                  value:
                      '\$${provider.totalPaidThisPeriod.toStringAsFixed(2)}',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Pending',
                  value:
                      '\$${provider.totalPendingPayout.toStringAsFixed(2)}',
                  color: AppColors.warning,
                  icon: Icons.pending_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Period selector ──────────────────────
            Text('Pay Period', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    date: _from,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    date: _to,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Hourly rate ──────────────────────────
            Text('Hourly Rate (USD)',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            TextField(
              controller: _rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money,
                    color: AppColors.primary),
                hintText: 'e.g. 2.00',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
                suffixText: 'USD/hr',
              ),
              onChanged: (_) => setState(() => _preview = []),
            ),
            const SizedBox(height: 20),

            // ── Build preview button ─────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isPreviewing ? null : _buildPreview,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isPreviewing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                    : const Icon(Icons.calculate_outlined,
                        color: AppColors.primary),
                label: Text(
                  _isPreviewing
                      ? 'Calculating...'
                      : 'Calculate Payroll',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // ── Preview list ─────────────────────────
            if (_preview.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Payroll Preview (${_preview.length} worker${_preview.length > 1 ? 's' : ''})',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 2),
              Text(
                'Tap "Pay" to send EcoCash payment to each worker.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._preview.asMap().entries.map((e) {
                final i = e.key;
                final r = e.value;
                return _PayrollPreviewCard(
                  record: r,
                  isPaying: _isPaying && _payingIndex == i,
                  onPay: _isPaying ? null : () => _payWorker(i),
                );
              }),
            ],

            if (provider.state == PayrollFRState.error) ...[
              const SizedBox(height: 12),
              FarmErrorBanner(message: provider.errorMessage),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── PAYROLL HISTORY TAB ───────────────────────────────────
class _PayrollHistoryTab extends StatefulWidget {
  final List<PayrollRecord> records;
  final FarmEntity farm;
  const _PayrollHistoryTab(
      {required this.records, required this.farm});

  @override
  State<_PayrollHistoryTab> createState() =>
      _PayrollHistoryTabState();
}

class _PayrollHistoryTabState extends State<_PayrollHistoryTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💸', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text('No payroll records yet',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Run payroll to see history here.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = widget.records[i];
        return _PayrollHistoryCard(
          record: r,
          onPoll: r.status == PayrollStatus.pending &&
                  r.paynowPollUrl != null
              ? () => _pollPayment(r)
              : null,
        );
      },
    );
  }

  Future<void> _pollPayment(PayrollRecord r) async {
    final confirmed = await context
        .read<PayrollFieldReportProvider>()
        .pollPayment(r.id, r.paynowPollUrl!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(confirmed
            ? '✅ Payment confirmed for ${r.workerName}'
            : '⏳ Payment still pending'),
        backgroundColor:
            confirmed ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── PAYROLL PREVIEW CARD ──────────────────────────────────
class _PayrollPreviewCard extends StatelessWidget {
  final PayrollRecord record;
  final bool isPaying;
  final VoidCallback? onPay;
  const _PayrollPreviewCard(
      {required this.record,
      required this.isPaying,
      this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                record.workerName[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.workerName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  '${record.hoursWorked.toStringAsFixed(1)} hrs × \$${record.hourlyRateUsd.toStringAsFixed(2)}/hr',
                  style: AppTextStyles.caption,
                ),
                Text(
                  record.workerPhone,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${record.totalAmountUsd.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Pay',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── PAYROLL HISTORY CARD ──────────────────────────────────
class _PayrollHistoryCard extends StatelessWidget {
  final PayrollRecord record;
  final VoidCallback? onPoll;
  const _PayrollHistoryCard({required this.record, this.onPoll});

  Color get _statusColor {
    switch (record.status) {
      case PayrollStatus.paid:    return AppColors.success;
      case PayrollStatus.pending: return AppColors.warning;
      case PayrollStatus.failed:  return AppColors.error;
    }
  }

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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(record.workerName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${record.status.emoji} ${record.status.label}',
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${record.hoursWorked.toStringAsFixed(1)} hrs  ·  \$${record.totalAmountUsd.toStringAsFixed(2)} USD',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              Text(
                '${record.periodStart.day}/${record.periodStart.month} – ${record.periodEnd.day}/${record.periodEnd.month}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (record.failureReason != null) ...[
            const SizedBox(height: 6),
            Text(record.failureReason!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 11)),
          ],
          if (onPoll != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton.icon(
                onPressed: onPoll,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.warning, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh,
                    color: AppColors.warning, size: 16),
                label: const Text('Check Payment Status',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label,
      required this.date,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption
                          .copyWith(
                              color: AppColors.textSecondary)),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600),
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

class _NoFarmWidget extends StatelessWidget {
  const _NoFarmWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌾',
              style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('No Farm Registered',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Register a farm first.',
              style:
                  TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(
                context, '/farm-registration'),
            child: const Text('Register Farm'),
          ),
        ],
      ),
    );
  }
}