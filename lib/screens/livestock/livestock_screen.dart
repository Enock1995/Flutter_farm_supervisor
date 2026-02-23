// lib/screens/livestock/livestock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/livestock_provider.dart';
import '../../services/advisory/livestock_advisory_service.dart';
import 'add_livestock_screen.dart';
import 'livestock_detail_screen.dart';

class LivestockScreen extends StatefulWidget {
  const LivestockScreen({super.key});

  @override
  State<LivestockScreen> createState() =>
      _LivestockScreenState();
}

class _LivestockScreenState extends State<LivestockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<LivestockProvider>()
            .loadLivestock(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Livestock'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Animals'),
            Tab(text: 'Health Alerts'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddLivestockScreen()),
          );
        },
        backgroundColor: AppColors.earth,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Animals',
            style: AppTextStyles.button),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyAnimalsTab(),
          _HealthAlertsTab(
              region: user?.agroRegion ?? '',
              userId: user?.userId ?? ''),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — MY ANIMALS
// =============================================================================
class _MyAnimalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LivestockProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator());
        }

        if (provider.records.isEmpty) {
          return _EmptyState();
        }

        // Summary card
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HerdSummaryCard(provider: provider),
            const SizedBox(height: 16),
            Text(
              'Your Animals (${provider.records.length} groups)',
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...provider.records.map((record) =>
                _AnimalCard(
                  record: record,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LivestockDetailScreen(
                              record: record),
                    ),
                  ),
                  onUpdateCount: (newCount) => context
                      .read<LivestockProvider>()
                      .updateCount(record.id, newCount),
                )),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _HerdSummaryCard extends StatelessWidget {
  final LivestockProvider provider;
  const _HerdSummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Count by category
    final categories = <String, int>{};
    for (final r in provider.records) {
      final category = LivestockAdvisoryService.animalTypes
          .firstWhere(
            (a) => a['name'] == r.animalType,
            orElse: () => {'category': 'Other'},
          )['category']!;
      categories[category] =
          (categories[category] ?? 0) + r.count;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.earth, AppColors.earthLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐾',
                  style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('My Herd Overview',
                  style: AppTextStyles.heading3
                      .copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryPill(
                  label: 'Total Animals',
                  value: '${provider.totalAnimals}'),
              const SizedBox(width: 10),
              _SummaryPill(
                  label: 'Species',
                  value:
                      '${provider.records.length}'),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: categories.entries
                  .map((e) => Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryPill(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.heading2
                  .copyWith(color: Colors.white)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final LivestockRecord record;
  final VoidCallback onTap;
  final Function(int) onUpdateCount;

  const _AnimalCard({
    required this.record,
    required this.onTap,
    required this.onUpdateCount,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        LivestockAdvisoryService.getIcon(record.animalType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.earth.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(record.animalType,
                      style: AppTextStyles.heading3),
                  if (record.breed != null &&
                      record.breed!.isNotEmpty)
                    Text(record.breed!,
                        style: AppTextStyles.bodySmall),
                  if (record.notes != null &&
                      record.notes!.isNotEmpty)
                    Text(record.notes!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Count adjuster
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.earth.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => onUpdateCount(
                        record.count - 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.remove,
                          size: 18,
                          color: AppColors.earth),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8),
                    child: Text(
                      '${record.count}',
                      style: AppTextStyles.heading3
                          .copyWith(
                              color: AppColors.earth),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onUpdateCount(
                        record.count + 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.add,
                          size: 18,
                          color: AppColors.earth),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐾',
                style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No Animals Yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to record your livestock.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 2 — HEALTH ALERTS
// =============================================================================
class _HealthAlertsTab extends StatelessWidget {
  final String region;
  final String userId;
  const _HealthAlertsTab(
      {required this.region, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final provider = context.watch<LivestockProvider>();
    final animalTypes =
        provider.records.map((r) => r.animalType).toList();

    if (animalTypes.isEmpty) {
      return Center(
        child: Text(
          'Add your animals first to see health alerts.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month banner
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Health alerts for ${_monthName(currentMonth)} — Region $region',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),

        // Alerts per animal type
        ...animalTypes.map((animalType) {
          final alerts =
              LivestockAdvisoryService.getMonthlyAlerts(
                  animalType, region, currentMonth);
          return _AlertCard(
              animalType: animalType, alerts: alerts);
        }),

        const SizedBox(height: 80),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return names[m];
  }
}

class _AlertCard extends StatelessWidget {
  final String animalType;
  final List<String> alerts;
  const _AlertCard(
      {required this.animalType, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final icon =
        LivestockAdvisoryService.getIcon(animalType);
    final hasUrgent = alerts.any((a) => a.startsWith('🔴'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUrgent
              ? AppColors.error.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasUrgent,
          leading: Text(icon,
              style: const TextStyle(fontSize: 28)),
          title: Text(animalType,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${alerts.length} alert${alerts.length == 1 ? '' : 's'}',
            style: AppTextStyles.caption.copyWith(
              color: hasUrgent
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: alerts
                    .map((alert) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(alert,
                                    style: AppTextStyles
                                        .body),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}