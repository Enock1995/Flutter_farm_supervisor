// lib/screens/farm_management/multi_farm_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../models/farm_management_model.dart';
import '../../models/task_activity_model.dart';
import '../../services/database_service.dart';
import '../../services/farm_management_database_service.dart';
import 'farm_management_shared_widgets.dart';

class MultiFarmScreen extends StatefulWidget {
  const MultiFarmScreen({super.key});
  @override
  State<MultiFarmScreen> createState() => _MultiFarmScreenState();
}

class _MultiFarmScreenState extends State<MultiFarmScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, _FarmSnapshot> _snapshots = {};
  bool _loadingSnapshots = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fmProvider = context.read<FarmManagementProvider>();
      final authProvider = context.read<AuthProvider>();
      if (fmProvider.farms.isEmpty && authProvider.user != null) {
        await fmProvider.loadFarms(authProvider.user!.id);
      }
      _loadSnapshots();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshots() async {
    final fmProvider = context.read<FarmManagementProvider>();
    if (fmProvider.farms.isEmpty) return;
    setState(() => _loadingSnapshots = true);
    final map = <String, _FarmSnapshot>{};
    for (final farm in fmProvider.farms) {
      map[farm.id] = await _FarmSnapshot.load(farm.id);
    }
    if (mounted) {
      setState(() {
        _snapshots = map;
        _loadingSnapshots = false;
      });
    }
  }

  Future<void> _switchFarm(FarmEntity farm) async {
    final fmProvider = context.read<FarmManagementProvider>();
    fmProvider.selectFarm(farm);
    await fmProvider.loadWorkers(farm.id);
    await fmProvider.loadTasks(farm.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Switched to ${farm.farmName}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Farm Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadSnapshots,
            tooltip: 'Refresh all',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Farms'),
            Tab(text: 'Combined Overview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyFarmsTab(
            snapshots: _snapshots,
            loadingSnapshots: _loadingSnapshots,
            onSwitch: _switchFarm,
            onRefresh: _loadSnapshots,
          ),
          _CombinedOverviewTab(
            snapshots: _snapshots,
            loading: _loadingSnapshots,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/farm-registration'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Farm'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Farm snapshot — per-farm quick stats
// ─────────────────────────────────────────────────────────────
class _FarmSnapshot {
  final int workerCount;
  final int pendingTasks;
  final int overdueTasks;
  final double hoursThisMonth;

  const _FarmSnapshot({
    required this.workerCount,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.hoursThisMonth,
  });

  int get alertCount => overdueTasks;

  static Future<_FarmSnapshot> load(String farmId) async {
    try {
      final workers =
          await FarmManagementDatabaseService.getWorkersByFarm(farmId);
      final approved = workers
          .where((w) => w.status == WorkerStatus.approved)
          .toList();
      final db = await DatabaseService().database;
      final taskRows = await db.query('tasks',
          where: 'farm_id = ?', whereArgs: [farmId]);
      final tasks = taskRows.map(TaskModel.fromMap).toList();
      double monthHours = 0;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      for (final w in approved) {
        final hist =
            await FarmManagementDatabaseService.getClockHistory(w.id);
        monthHours += hist
            .where((r) => r.clockInTime.isAfter(monthStart))
            .fold<double>(0, (s, r) => s + (r.hoursWorked ?? 0));
      }
      return _FarmSnapshot(
        workerCount: approved.length,
        pendingTasks:
            tasks.where((t) => t.status == TaskStatus.pending).length,
        overdueTasks: tasks.where((t) => t.isOverdue).length,
        hoursThisMonth: monthHours,
      );
    } catch (_) {
      return const _FarmSnapshot(
          workerCount: 0,
          pendingTasks: 0,
          overdueTasks: 0,
          hoursThisMonth: 0);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// My Farms tab
// ─────────────────────────────────────────────────────────────
class _MyFarmsTab extends StatelessWidget {
  final Map<String, _FarmSnapshot> snapshots;
  final bool loadingSnapshots;
  final Future<void> Function(FarmEntity) onSwitch;
  final VoidCallback onRefresh;

  const _MyFarmsTab({
    required this.snapshots,
    required this.loadingSnapshots,
    required this.onSwitch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, fmProvider, _) {
        final farms = fmProvider.farms;
        final selected = fmProvider.selectedFarm;

        if (farms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No farms registered yet',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Tap "Add Farm" below to get started.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (selected != null) ...[
                _ActiveBanner(farm: selected),
                const SizedBox(height: 16),
              ],
              Text('All Farms (${farms.length})',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              ...farms.map((farm) {
                final snap = snapshots[farm.id];
                final isActive = selected?.id == farm.id;
                return _FarmCard(
                  farm: farm,
                  snapshot: snap,
                  isActive: isActive,
                  loadingSnapshot:
                      loadingSnapshots && snap == null,
                  onSwitch: () => onSwitch(farm),
                  onManage: () {
                    fmProvider.selectFarm(farm);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        );
      },
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final FarmEntity farm;
  const _ActiveBanner({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Farm',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
                Text(farm.farmName,
                    style: AppTextStyles.heading3
                        .copyWith(color: Colors.white)),
                Text(
                  '${farm.sizeHectares} ha  •  ${farm.district}  •  ${farm.farmCode}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmEntity farm;
  final _FarmSnapshot? snapshot;
  final bool isActive;
  final bool loadingSnapshot;
  final VoidCallback onSwitch;
  final VoidCallback onManage;

  const _FarmCard({
    required this.farm,
    required this.snapshot,
    required this.isActive,
    required this.loadingSnapshot,
    required this.onSwitch,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.divider,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.divider),
                  ),
                  child: Icon(Icons.home_outlined,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(farm.farmName,
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text('ACTIVE',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ]),
                      Text(
                        '${farm.sizeHectares} ha  •  ${farm.district}  •  ${farm.farmCode}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Snapshot stats row
            if (loadingSnapshot) ...[
              const SizedBox(height: 12),
              const Center(
                  child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary))),
            ] else if (snapshot != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                _SnapStat('${snapshot!.workerCount}', 'workers',
                    AppColors.primary),
                const SizedBox(width: 8),
                _SnapStat(
                    snapshot!.hoursThisMonth.toStringAsFixed(0),
                    'hrs/mo',
                    AppColors.info),
                const SizedBox(width: 8),
                _SnapStat('${snapshot!.pendingTasks}', 'pending',
                    AppColors.warning),
                const SizedBox(width: 8),
                _SnapStat(
                    '${snapshot!.overdueTasks}',
                    'overdue',
                    snapshot!.overdueTasks > 0
                        ? AppColors.error
                        : AppColors.success),
              ]),
            ],

            const SizedBox(height: 12),
            Row(children: [
              if (!isActive) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSwitch,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Switch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.dashboard_outlined,
                      size: 16),
                  label: Text(
                      isActive ? 'Manage' : 'Go to Dashboard'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SnapStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SnapStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Combined Overview tab
// ─────────────────────────────────────────────────────────────
class _CombinedOverviewTab extends StatelessWidget {
  final Map<String, _FarmSnapshot> snapshots;
  final bool loading;
  const _CombinedOverviewTab(
      {required this.snapshots, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, fmProvider, _) {
        final farms = fmProvider.farms;

        if (farms.isEmpty) {
          return const Center(
              child: Text('No farms registered yet.',
                  style:
                      TextStyle(color: AppColors.textSecondary)));
        }
        if (loading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary));
        }

        int totalWorkers = 0;
        double totalHours = 0;
        int totalPending = 0;
        int totalOverdue = 0;

        for (final snap in snapshots.values) {
          totalWorkers += snap.workerCount;
          totalHours += snap.hoursThisMonth;
          totalPending += snap.pendingTasks;
          totalOverdue += snap.overdueTasks;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.corporate_fare_outlined,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Portfolio Overview',
                              style: AppTextStyles.heading3
                                  .copyWith(color: Colors.white)),
                          Text(
                            '${farms.length} farm${farms.length > 1 ? 's' : ''} in your portfolio',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${farms.length} farms',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (totalOverdue > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$totalOverdue overdue task${totalOverdue > 1 ? 's' : ''} across your farms need attention.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ]),
                ),

              Text('Combined Totals',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _SummaryCard(
                      label: 'Total Workers',
                      value: '$totalWorkers',
                      sub: 'approved across all farms',
                      icon: Icons.group_outlined,
                      color: AppColors.primary),
                  _SummaryCard(
                      label: 'Hours This Month',
                      value: totalHours.toStringAsFixed(0),
                      sub: 'combined labour',
                      icon: Icons.access_time_outlined,
                      color: AppColors.info),
                  _SummaryCard(
                      label: 'Pending Tasks',
                      value: '$totalPending',
                      sub: 'awaiting completion',
                      icon: Icons.pending_outlined,
                      color: AppColors.warning),
                  _SummaryCard(
                      label: 'Overdue Tasks',
                      value: '$totalOverdue',
                      sub: 'need action now',
                      icon: Icons.warning_amber_outlined,
                      color: totalOverdue > 0
                          ? AppColors.error
                          : AppColors.success),
                ],
              ),
              const SizedBox(height: 20),

              Text('Per-Farm Breakdown',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              ...farms.map((farm) {
                final snap = snapshots[farm.id];
                final isActive =
                    fmProvider.selectedFarm?.id == farm.id;
                return _BreakdownRow(
                    farm: farm,
                    snapshot: snap,
                    isActive: isActive);
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  const _SummaryCard({
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
              Text(sub,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final FarmEntity farm;
  final _FarmSnapshot? snapshot;
  final bool isActive;
  const _BreakdownRow(
      {required this.farm, this.snapshot, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.divider,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(farm.farmName,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('●',
                          style: TextStyle(
                              fontSize: 8,
                              color: AppColors.primary)),
                    ),
                ]),
                Text(
                  '${farm.sizeHectares} ha  •  ${farm.district}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (snapshot != null) ...[
            _Micro('${snapshot!.workerCount}', 'workers',
                AppColors.primary),
            const SizedBox(width: 6),
            _Micro(snapshot!.hoursThisMonth.toStringAsFixed(0),
                'hrs', AppColors.info),
            const SizedBox(width: 6),
            _Micro('${snapshot!.overdueTasks}', 'overdue',
                snapshot!.overdueTasks > 0
                    ? AppColors.error
                    : AppColors.success),
          ] else
            const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _Micro extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Micro(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color)),
      Text(label,
          style: const TextStyle(
              fontSize: 9, color: AppColors.textSecondary)),
    ]);
  }
}