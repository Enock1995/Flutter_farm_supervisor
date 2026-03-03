// lib/screens/labour/labour_tracker_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/labour_provider.dart';
import '../../services/labour_service.dart';

class LabourTrackerScreen extends StatefulWidget {
  const LabourTrackerScreen({super.key});

  @override
  State<LabourTrackerScreen> createState() =>
      _LabourTrackerScreenState();
}

class _LabourTrackerScreenState
    extends State<LabourTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<LabourProvider>().load(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Labour Tracker'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: 'Attendance'),
            Tab(text: 'Pay'),
          ],
        ),
      ),
      floatingActionButton: _AddWorkerFab(tabs: _tabs),
      body: Consumer<LabourProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight));
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _WorkersTab(provider: provider),
              _AttendanceTab(provider: provider),
              _PayTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

// FAB that changes label based on active tab
class _AddWorkerFab extends StatefulWidget {
  final TabController tabs;
  const _AddWorkerFab({required this.tabs});

  @override
  State<_AddWorkerFab> createState() =>
      _AddWorkerFabState();
}

class _AddWorkerFabState extends State<_AddWorkerFab> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.tabs.addListener(() {
      if (mounted) {
        setState(() => _tabIndex = widget.tabs.index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show FAB on Workers tab
    if (_tabIndex != 0) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () =>
          _showAddWorkerSheet(context),
      backgroundColor: AppColors.primaryLight,
      icon: const Icon(Icons.person_add,
          color: Colors.white),
      label: Text('Add Worker',
          style: AppTextStyles.button),
    );
  }

  void _showAddWorkerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWorkerSheet(),
    );
  }
}

// =============================================================================
// TAB 1 — WORKERS
// =============================================================================

class _WorkersTab extends StatelessWidget {
  final LabourProvider provider;
  const _WorkersTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final workers = provider.activeWorkers;

    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primaryLight
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _HeaderStat(
                  emoji: '👷',
                  value: '${workers.length}',
                  label: 'Active'),
              _HeaderStat(
                  emoji: '🤝',
                  value:
                      '${workers.where((w) => w.workerType == 'casual').length}',
                  label: 'Casual'),
              _HeaderStat(
                  emoji: '🌾',
                  value:
                      '${workers.where((w) => w.workerType == 'seasonal').length}',
                  label: 'Seasonal'),
              _HeaderStat(
                  emoji: '⭐',
                  value:
                      '${workers.where((w) => w.workerType == 'permanent').length}',
                  label: 'Permanent'),
            ],
          ),
        ),

        // Workers list
        Expanded(
          child: workers.isEmpty
              ? _EmptyWorkers()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 80),
                  itemCount: workers.length,
                  itemBuilder: (_, i) => _WorkerCard(
                    worker: workers[i],
                    todayStatus: provider
                        .todayAttendance[workers[i].id],
                  ),
                ),
        ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final FarmWorker worker;
  final String? todayStatus;
  const _WorkerCard(
      {required this.worker, this.todayStatus});

  Color get _statusColor {
    switch (todayStatus) {
      case 'present': return AppColors.success;
      case 'half':    return AppColors.warning;
      case 'absent':  return AppColors.error;
      default:        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (todayStatus) {
      case 'present': return '✅ Present';
      case 'half':    return '🌗 Half Day';
      case 'absent':  return '❌ Absent';
      default:        return '⬜ Not marked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(worker.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Remove Worker?'),
          content: Text(
              'Mark ${worker.fullName} as inactive? '
              'Attendance records will be kept.'),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('Remove',
                    style: TextStyle(
                        color: AppColors.error))),
          ],
        ),
      ),
      onDismissed: (_) => context
          .read<LabourProvider>()
          .deactivateWorker(worker.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.person_remove,
            color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryLight
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  worker.fullName.isNotEmpty
                      ? worker.fullName[0]
                          .toUpperCase()
                      : '?',
                  style: AppTextStyles.heading3
                      .copyWith(
                          color:
                              AppColors.primaryLight),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(worker.fullName,
                      style: AppTextStyles.body
                          .copyWith(
                              fontWeight:
                                  FontWeight.w700)),
                  Row(
                    children: [
                      Text(
                        '${worker.typeEmoji} ${worker.typeLabel}',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .textSecondary),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              color:
                                  AppColors.textHint)),
                      Text(
                        'USD ${worker.dailyRateUsd.toStringAsFixed(0)}/day',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .primaryLight,
                                fontWeight:
                                    FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Today status
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text('Today',
                    style: AppTextStyles.caption
                        .copyWith(
                            color:
                                AppColors.textHint)),
                const SizedBox(height: 2),
                Text(_statusLabel,
                    style: AppTextStyles.caption
                        .copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 2 — ATTENDANCE
// =============================================================================

class _AttendanceTab extends StatefulWidget {
  final LabourProvider provider;
  const _AttendanceTab({required this.provider});

  @override
  State<_AttendanceTab> createState() =>
      _AttendanceTabState();
}

class _AttendanceTabState
    extends State<_AttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _pendingStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentStatuses();
  }

  void _loadCurrentStatuses() {
    for (final w in widget.provider.activeWorkers) {
      final rec = widget.provider
          .getAttendance(w.id, _selectedDate);
      _pendingStatus[w.id] =
          rec?.status ?? 'not_marked';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now()
          .subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadCurrentStatuses();
      });
    }
  }

  Future<void> _saveAttendance() async {
    final user =
        context.read<AuthProvider>().user;
    if (user == null) return;

    final statusMap = Map<String, String>.from(
        _pendingStatus)
      ..removeWhere((_, v) => v == 'not_marked');

    await context
        .read<LabourProvider>()
        .markBulkAttendance(
          userId: user.userId,
          date: _selectedDate,
          statusMap: statusMap,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = widget.provider.activeWorkers;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      children: [
        // Date selector
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primaryLight),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day} ${months[_selectedDate.month]} ${_selectedDate.year}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('Change date',
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors
                                .primaryLight)),
                const Icon(Icons.chevron_right,
                    color: AppColors.primaryLight,
                    size: 18),
              ],
            ),
          ),
        ),

        if (workers.isEmpty)
          Expanded(child: _EmptyWorkers())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 100),
              itemCount: workers.length,
              itemBuilder: (_, i) {
                final w = workers[i];
                return _AttendanceRow(
                  worker: w,
                  currentStatus:
                      _pendingStatus[w.id] ??
                          'not_marked',
                  onStatusChanged: (s) =>
                      setState(() =>
                          _pendingStatus[w.id] = s),
                );
              },
            ),
          ),

        // Save button
        if (workers.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                      'Save Attendance',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final FarmWorker worker;
  final String currentStatus;
  final ValueChanged<String> onStatusChanged;
  const _AttendanceRow({
    required this.worker,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(worker.fullName,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          Text(
              'USD ${worker.dailyRateUsd.toStringAsFixed(0)}/day',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _AttBtn(
                label: '✅ Present',
                selected: currentStatus == 'present',
                color: AppColors.success,
                onTap: () => onStatusChanged('present'),
              ),
              const SizedBox(width: 8),
              _AttBtn(
                label: '🌗 Half',
                selected: currentStatus == 'half',
                color: AppColors.warning,
                onTap: () => onStatusChanged('half'),
              ),
              const SizedBox(width: 8),
              _AttBtn(
                label: '❌ Absent',
                selected: currentStatus == 'absent',
                color: AppColors.error,
                onTap: () => onStatusChanged('absent'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _AttBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: selected
                  ? color
                  : AppColors.textSecondary,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3 — PAY
// =============================================================================

class _PayTab extends StatefulWidget {
  final LabourProvider provider;
  const _PayTab({required this.provider});

  @override
  State<_PayTab> createState() => _PayTabState();
}

class _PayTabState extends State<_PayTab> {
  String _period = 'week'; // 'week' | 'month'

  @override
  Widget build(BuildContext context) {
    final (start, end) = _period == 'week'
        ? LabourService.currentWeek()
        : LabourService.currentMonth();

    final summaries = widget.provider
        .getSummaries(periodStart: start, periodEnd: end);
    final total = widget.provider.totalWagesDue(
        periodStart: start, periodEnd: end);

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                _PeriodBtn(
                  label: 'This Week',
                  selected: _period == 'week',
                  onTap: () =>
                      setState(() => _period = 'week'),
                ),
                _PeriodBtn(
                  label: 'This Month',
                  selected: _period == 'month',
                  onTap: () =>
                      setState(() => _period = 'month'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Period label
          Text(
            '${start.day} ${months[start.month]} — ${end.day} ${months[end.month]} ${end.year}',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Total wages card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryLight
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('Total Wages Due',
                    style: AppTextStyles.bodySmall
                        .copyWith(
                            color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  'USD ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${summaries.length} worker${summaries.length == 1 ? '' : 's'}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (summaries.isEmpty)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    const Text('👷',
                        style:
                            TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No workers yet',
                        style: AppTextStyles.heading3
                            .copyWith(
                                color: AppColors
                                    .textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      'Add workers in the Workers tab\nand mark attendance to calculate pay.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...summaries.map(
                (s) => _PayCard(summary: s)),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  final WorkerPaySummary summary;
  const _PayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final w = summary.worker;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(w.fullName,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                'USD ${summary.totalPayUsd.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _DayStat(
                  label: 'Present',
                  value: '${summary.daysPresent}',
                  color: AppColors.success),
              const SizedBox(width: 8),
              _DayStat(
                  label: 'Half',
                  value: '${summary.daysHalf}',
                  color: AppColors.warning),
              const SizedBox(width: 8),
              _DayStat(
                  label: 'Absent',
                  value: '${summary.daysAbsent}',
                  color: AppColors.error),
              const Spacer(),
              Text(
                '${summary.totalDaysEquivalent.toStringAsFixed(1)} days × USD ${w.dailyRateUsd.toStringAsFixed(0)}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DayStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$value $label',
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
              )),
        ),
      ),
    );
  }
}

// =============================================================================
// ADD WORKER SHEET
// =============================================================================

class _AddWorkerSheet extends StatefulWidget {
  const _AddWorkerSheet();

  @override
  State<_AddWorkerSheet> createState() =>
      _AddWorkerSheetState();
}

class _AddWorkerSheetState
    extends State<_AddWorkerSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _workerType = 'casual';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _rateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter name and daily rate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rate =
        double.tryParse(_rateCtrl.text.trim()) ?? 0;
    if (rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid daily rate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<LabourProvider>().addWorker(
          userId: user.userId,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          workerType: _workerType,
          dailyRateUsd: rate,
          nationalId: _idCtrl.text.trim().isEmpty
              ? null
              : _idCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Worker added!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
                20,
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
            Text('Add Farm Worker',
                style: AppTextStyles.heading3),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name *',
                prefixIcon: const Icon(Icons.person,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: const Icon(Icons.phone,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),

            // National ID
            TextField(
              controller: _idCtrl,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'National ID (optional)',
                prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),

            // Daily rate
            TextField(
              controller: _rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Daily rate (USD) *',
                hintText: 'e.g. 5.00',
                prefixIcon: const Icon(
                    Icons.attach_money,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),

            // Suggested rates hint
            Padding(
              padding:
                  const EdgeInsets.only(top: 6, left: 4),
              child: Wrap(
                spacing: 6,
                children: LabourService
                    .suggestedRates.entries
                    .map((e) => GestureDetector(
                          onTap: () => _rateCtrl.text =
                              e.value.toStringAsFixed(0),
                          child: Chip(
                            label: Text(
                                '${e.key}: USD ${e.value.toStringAsFixed(0)}',
                                style: AppTextStyles
                                    .caption),
                            backgroundColor:
                                AppColors.background,
                            padding: EdgeInsets.zero,
                            visualDensity:
                                VisualDensity.compact,
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Worker type
            Text('Worker Type',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                    label: '🤝 Casual',
                    value: 'casual',
                    selected: _workerType == 'casual',
                    onTap: () => setState(
                        () => _workerType = 'casual')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: '🌾 Seasonal',
                    value: 'seasonal',
                    selected:
                        _workerType == 'seasonal',
                    onTap: () => setState(
                        () => _workerType = 'seasonal')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: '⭐ Permanent',
                    value: 'permanent',
                    selected:
                        _workerType == 'permanent',
                    onTap: () => setState(() =>
                        _workerType = 'permanent')),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                    : const Text('Add Worker',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.divider),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: selected
                    ? Colors.white
                    : AppColors.textPrimary,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
              )),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

class _HeaderStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _HeaderStat(
      {required this.emoji,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.heading2
                .copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _EmptyWorkers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👷',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No workers yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap + Add Worker to register\nyour farm team.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}