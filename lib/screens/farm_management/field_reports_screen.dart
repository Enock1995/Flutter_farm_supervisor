// lib/screens/farm_management/field_reports_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/farm_management_model.dart';
import '../../models/payroll_fieldreport_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/payroll_fieldreport_provider.dart';
import 'farm_management_shared_widgets.dart';

class FieldReportsScreen extends StatefulWidget {
  const FieldReportsScreen({super.key});

  @override
  State<FieldReportsScreen> createState() =>
      _FieldReportsScreenState();
}

class _FieldReportsScreenState extends State<FieldReportsScreen> {
  // Owner sees all reports; worker submits + sees own reports.
  // We detect view mode from whether user has a farm as owner.
  bool get _isOwnerView =>
      context.read<FarmManagementProvider>().selectedFarm != null &&
      context.read<FarmManagementProvider>().selectedFarm!.ownerId ==
          context.read<AuthProvider>().user?.userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final fmProvider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    if (fmProvider.selectedFarm == null) {
      await fmProvider.loadFarms(user.userId);
    }
    final farm = fmProvider.selectedFarm;
    if (farm != null) {
      await context
          .read<PayrollFieldReportProvider>()
          .loadFieldReports(farm.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Field Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Submit Report',
            onPressed: () => _showSubmitSheet(context),
          ),
        ],
      ),
      body: Consumer2<FarmManagementProvider,
          PayrollFieldReportProvider>(
        builder: (ctx, fmProvider, prProvider, _) {
          final farm = fmProvider.selectedFarm;
          if (farm == null) return const _NoFarmWidget();

          final reports = prProvider.fieldReports;

          return RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _FieldReportsHeader(
                      farm: farm,
                      unreadCount: prProvider.unreadCount),
                ),

                // List
                reports.isEmpty
                    ? const SliverFillRemaining(
                        child: _EmptyReportsWidget())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final showHeader = i == 0 ||
                                  !_isSameDay(
                                      reports[i - 1].createdAt,
                                      reports[i].createdAt);
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    _DateSectionHeader(
                                        date: reports[i].createdAt),
                                  _FieldReportCard(
                                    report: reports[i],
                                    onTap: () => _openReport(
                                        reports[i], prProvider),
                                  ),
                                ],
                              );
                            },
                            childCount: reports.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_outlined,
            color: Colors.white),
        label: const Text('Submit Report',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openReport(
      FieldReport report, PayrollFieldReportProvider provider) {
    if (!report.ownerViewed) {
      provider.markReportViewed(report.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportDetailSheet(report: report),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SubmitReportSheet(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── HEADER ────────────────────────────────────────────────
class _FieldReportsHeader extends StatelessWidget {
  final FarmEntity farm;
  final int unreadCount;
  const _FieldReportsHeader(
      {required this.farm, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('${farm.farmName} · ${farm.farmCode}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$unreadCount unread report${unreadCount > 1 ? 's' : ''} requiring attention',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── DATE SECTION HEADER ───────────────────────────────────
class _DateSectionHeader extends StatelessWidget {
  final DateTime date;
  const _DateSectionHeader({required this.date});

  String _label() {
    final now = DateTime.now();
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) return 'Today';
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) return 'Yesterday';
    const months = [
      '',  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_label(),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Container(height: 1, color: AppColors.divider)),
        ],
      ),
    );
  }
}

// ── REPORT CARD ───────────────────────────────────────────
class _FieldReportCard extends StatelessWidget {
  final FieldReport report;
  final VoidCallback onTap;
  const _FieldReportCard(
      {required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: report.requiresOwnerAttention &&
                    !report.ownerViewed
                ? AppColors.warning.withOpacity(0.5)
                : AppColors.divider,
            width: report.requiresOwnerAttention &&
                    !report.ownerViewed
                ? 1.5
                : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(report.category.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!report.ownerViewed)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(report.body,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 11,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(report.reportedByName,
                          style: AppTextStyles.caption),
                      if (report.fieldOrPlot != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.landscape_outlined,
                            size: 11,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(report.fieldOrPlot!,
                            style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (report.requiresOwnerAttention)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ── REPORT DETAIL SHEET ───────────────────────────────────
class _ReportDetailSheet extends StatelessWidget {
  final FieldReport report;
  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(report.category.emoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: AppTextStyles.heading3),
                    Text(report.category.label,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(report.body,
                style: AppTextStyles.body),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Reported by',
            value: report.reportedByName,
          ),
          if (report.fieldOrPlot != null)
            _DetailRow(
              icon: Icons.landscape_outlined,
              label: 'Field / Plot',
              value: report.fieldOrPlot!,
            ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Time',
            value:
                '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} '
                '${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          if (report.requiresOwnerAttention)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Text('Requires your attention',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── SUBMIT REPORT SHEET ───────────────────────────────────
class _SubmitReportSheet extends StatefulWidget {
  const _SubmitReportSheet();

  @override
  State<_SubmitReportSheet> createState() =>
      _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<_SubmitReportSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  FieldReportCategory _category = FieldReportCategory.generalUpdate;
  bool _requiresAttention = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in title and description.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);
    final fmProvider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    final farm = fmProvider.selectedFarm!;
    // If worker is logged in use currentWorker, else owner submits as self
    final worker = fmProvider.currentWorker;
    final workerId = worker?.id ?? user.userId;
    final workerName = worker?.fullName ?? user.fullName;

    final success = await context
        .read<PayrollFieldReportProvider>()
        .submitFieldReport(
          farmId: farm.id,
          ownerId: farm.ownerId,
          workerId: workerId,
          workerName: workerName,
          category: _category,
          title: _titleCtrl.text,
          body: _bodyCtrl.text,
          fieldOrPlot: _fieldCtrl.text.trim().isEmpty
              ? null
              : _fieldCtrl.text.trim(),
          requiresAttention: _requiresAttention,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report submitted ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Submit Field Report',
                style: AppTextStyles.heading3),
            const SizedBox(height: 20),

            // Category
            Text('Category', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _CategorySelector(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(
                  'Report Title *', Icons.title_outlined),
            ),
            const SizedBox(height: 12),

            // Body
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(
                  'Describe what you observed *',
                  Icons.description_outlined),
            ),
            const SizedBox(height: 12),

            // Field/Plot
            TextField(
              controller: _fieldCtrl,
              decoration: _inputDeco(
                  'Field / Plot (optional)',
                  Icons.landscape_outlined),
            ),
            const SizedBox(height: 12),

            // Requires attention toggle
            GestureDetector(
              onTap: () => setState(
                  () => _requiresAttention = !_requiresAttention),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _requiresAttention
                      ? AppColors.warning.withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _requiresAttention
                        ? AppColors.warning
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _requiresAttention
                          ? Icons.warning_amber_rounded
                          : Icons.warning_amber_outlined,
                      color: _requiresAttention
                          ? AppColors.warning
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                          'This requires owner attention'),
                    ),
                    Switch(
                      value: _requiresAttention,
                      onChanged: (v) =>
                          setState(() => _requiresAttention = v),
                      activeColor: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(_isLoading
                    ? 'Submitting...'
                    : 'Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      );
}

// ── CATEGORY SELECTOR ─────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final FieldReportCategory selected;
  final Function(FieldReportCategory) onChanged;
  const _CategorySelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FieldReportCategory.values.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.emoji,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  c.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── PLACEHOLDERS ──────────────────────────────────────────
class _EmptyReportsWidget extends StatelessWidget {
  const _EmptyReportsWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📋', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('No field reports yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Workers can submit daily reports here.',
              style:
                  TextStyle(color: AppColors.textSecondary)),
        ],
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
          const Text('🌾', style: TextStyle(fontSize: 52)),
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