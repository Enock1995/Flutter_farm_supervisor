// lib/screens/farm_management/activity_feed_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/task_activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() =>
      _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  ActivityType? _activeFilter;

  // Filter pill options
  static const _filters = [
    {'label': 'All',      'value': null},
    {'label': '📋 Tasks', 'value': ActivityType.taskCreated},
    {'label': '✅ Done',  'value': ActivityType.taskCompleted},
    {'label': '🟢 Clock-In',  'value': ActivityType.workerClockedIn},
    {'label': '🔴 Clock-Out', 'value': ActivityType.workerClockedOut},
    {'label': '👤 Workers',   'value': ActivityType.workerJoined},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  Future<void> _loadFeed() async {
    final provider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;

    if (provider.selectedFarm == null) {
      await provider.loadFarms(user.userId);
    }
    final farm = provider.selectedFarm;
    if (farm != null) {
      await provider.loadActivityFeed(farm.id,
          filterType: _activeFilter);
    }
  }

  Future<void> _applyFilter(ActivityType? type) async {
    setState(() => _activeFilter = type);
    final provider = context.read<FarmManagementProvider>();
    final farm = provider.selectedFarm;
    if (farm != null) {
      await provider.loadActivityFeed(farm.id, filterType: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Feed'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<FarmManagementProvider>(
        builder: (context, provider, _) {
          final farm = provider.selectedFarm;

          if (farm == null) {
            return const _NoFarmWidget();
          }

          final feed = provider.activityFeed;

          return RefreshIndicator(
            onRefresh: _loadFeed,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Farm context banner
                SliverToBoxAdapter(
                  child: _FarmBanner(farm: farm),
                ),

                // Filter pills
                SliverToBoxAdapter(
                  child: _FilterRow(
                    activeFilter: _activeFilter,
                    filters: _filters,
                    onSelect: _applyFilter,
                  ),
                ),

                // Feed
                if (feed.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyFeedWidget(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          // Date section headers
                          final item = feed[i];
                          final showHeader = i == 0 ||
                              !_isSameDay(
                                  feed[i - 1].createdAt,
                                  item.createdAt);
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (showHeader)
                                _DateHeader(
                                    date: item.createdAt),
                              _ActivityTile(item: item),
                            ],
                          );
                        },
                        childCount: feed.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── FARM BANNER ───────────────────────────────────────────
class _FarmBanner extends StatelessWidget {
  final dynamic farm;
  const _FarmBanner({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.farmName,
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                Text(
                  '${farm.farmCode} · ${farm.district}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.history,
              color: Colors.white60, size: 18),
        ],
      ),
    );
  }
}

// ── FILTER PILLS ──────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final ActivityType? activeFilter;
  final List<Map<String, dynamic>> filters;
  final Function(ActivityType?) onSelect;
  const _FilterRow(
      {required this.activeFilter,
      required this.filters,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: filters.map((f) {
          final isActive =
              activeFilter == f['value'];
          return GestureDetector(
            onTap: () =>
                onSelect(f['value'] as ActivityType?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.divider,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary
                              .withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── DATE SECTION HEADER ───────────────────────────────────
class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

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
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
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
            child: Text(
              _label(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTIVITY TILE ─────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  const _ActivityTile({required this.item});

  Color _colorFor(ActivityType type) {
    switch (type) {
      case ActivityType.taskCompleted:
      case ActivityType.workerApproved:
        return AppColors.success;
      case ActivityType.taskCancelled:
        return AppColors.error;
      case ActivityType.taskStarted:
      case ActivityType.workerClockedIn:
        return AppColors.info;
      case ActivityType.workerClockedOut:
        return AppColors.warning;
      case ActivityType.taskCreated:
      case ActivityType.workerJoined:
      case ActivityType.farmRegistered:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(item.type);
    final time = item.createdAt;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    item.type.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Content card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),

                  // Detail
                  if (item.detail != null &&
                      item.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.detail!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],

                  // Actor badge
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 11, color: color),
                            const SizedBox(width: 3),
                            Text(
                              item.actorName,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.divider.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.type.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── EMPTY / NO FARM ───────────────────────────────────────
class _EmptyFeedWidget extends StatelessWidget {
  const _EmptyFeedWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📡',
              style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('No activity yet',
              style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Events like task updates, clock-ins, and\nworker joins will appear here.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌾',
                style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No Farm Registered',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Register a farm first to see its activity feed.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}