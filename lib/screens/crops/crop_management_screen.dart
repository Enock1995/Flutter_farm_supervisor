// lib/screens/crops/crop_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crop_provider.dart';
import '../../services/advisory/crop_advisory_service.dart';
import 'add_crop_screen.dart';
import 'crop_detail_screen.dart';

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({super.key});

  @override
  State<CropManagementScreen> createState() =>
      _CropManagementScreenState();
}

class _CropManagementScreenState
    extends State<CropManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CropProvider>().loadCrops(user.userId);
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
        title: const Text('Crop Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Crops'),
            Tab(text: 'Planting Guide'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddCropScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Crop',
            style: AppTextStyles.button),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCropsTab(),
          _PlantingGuideTab(region: user?.agroRegion ?? ''),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — MY CROPS
// =============================================================================
class _MyCropsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator());
        }

        if (provider.activeCrops.isEmpty) {
          return _EmptyCropsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            final user = context.read<AuthProvider>().user;
            if (user != null) {
              await context
                  .read<CropProvider>()
                  .loadCrops(user.userId);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active crops
              if (provider.activeCrops.isNotEmpty) ...[
                _SectionLabel(
                    label:
                        '🌱 Active Crops (${provider.activeCrops.length})'),
                const SizedBox(height: 8),
                ...provider.activeCrops.map((crop) =>
                    _CropCard(
                        crop: crop,
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CropDetailScreen(
                                        crop: crop),
                              ),
                            ))),
              ],
              // Completed crops
              if (provider.completedCrops.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionLabel(
                    label:
                        '✅ Completed (${provider.completedCrops.length})'),
                const SizedBox(height: 8),
                ...provider.completedCrops.map((crop) =>
                    _CropCard(
                        crop: crop,
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CropDetailScreen(
                                        crop: crop),
                              ),
                            ))),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _CropCard extends StatelessWidget {
  final CropRecord crop;
  final VoidCallback onTap;

  const _CropCard({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final stageInfo = crop.plantingDate != null
        ? CropAdvisoryService.getCurrentStage(
            crop.cropName, crop.plantingDate!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      stageInfo?.icon ?? '🌱',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(crop.cropName,
                          style: AppTextStyles.heading3),
                      if (crop.fieldSizeHa != null)
                        Text(
                          '${crop.fieldSizeHa} ha',
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
              ],
            ),
            if (stageInfo != null) ...[
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            stageInfo.progressPercent / 100,
                        backgroundColor:
                            AppColors.divider,
                        valueColor:
                            const AlwaysStoppedAnimation(
                                AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${stageInfo.progressPercent.toInt()}%',
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stageInfo.stageName,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
              if (crop.plantingDate != null)
                Text(
                  'Day ${crop.daysGrowing} since planting',
                  style: AppTextStyles.caption,
                ),
            ] else if (crop.plantingDate == null) ...[
              const SizedBox(height: 8),
              Text(
                'No planting date set — tap to add details',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.warning),
              ),
            ],
            if (!crop.isActive && crop.yieldKg != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.scale,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Yield: ${crop.yieldKg} kg',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCropsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱',
                style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No Crops Yet',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first crop and start tracking its progress.',
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
// TAB 2 — PLANTING GUIDE
// =============================================================================
class _PlantingGuideTab extends StatelessWidget {
  final String region;
  const _PlantingGuideTab({required this.region});

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final crops = CropAdvisoryService.plantingCalendar.keys
        .toList()
      ..sort();

    final canPlantNow = crops
        .where((c) {
          final months = CropAdvisoryService
                  .plantingCalendar[c]?[region] ??
              [];
          return months.contains(currentMonth);
        })
        .toList();

    final plantSoon = crops
        .where((c) {
          final nextMonth =
              currentMonth == 12 ? 1 : currentMonth + 1;
          final months = CropAdvisoryService
                  .plantingCalendar[c]?[region] ??
              [];
          return !months.contains(currentMonth) &&
              months.contains(nextMonth);
        })
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Region context
        Container(
          padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  'Showing planting guide for Region $region — ${_monthName(currentMonth)} ${DateTime.now().year}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Plant now
        if (canPlantNow.isNotEmpty) ...[
          _SectionLabel(
              label: '✅ Plant NOW (${canPlantNow.length} crops)'),
          const SizedBox(height: 8),
          ...canPlantNow.map((crop) => _PlantingCard(
              crop: crop,
              region: region,
              urgency: 'now')),
          const SizedBox(height: 20),
        ],

        // Plant soon
        if (plantSoon.isNotEmpty) ...[
          _SectionLabel(
              label: '⏰ Plant Next Month (${plantSoon.length} crops)'),
          const SizedBox(height: 8),
          ...plantSoon.map((crop) => _PlantingCard(
              crop: crop,
              region: region,
              urgency: 'soon')),
          const SizedBox(height: 20),
        ],

        // All crops
        _SectionLabel(label: '📅 All Crops Calendar'),
        const SizedBox(height: 8),
        ...crops
            .where((c) {
              final months = CropAdvisoryService
                      .plantingCalendar[c]?[region] ??
                  [];
              return months.isNotEmpty;
            })
            .map((crop) => _PlantingCard(
                crop: crop, region: region, urgency: 'later')),
        const SizedBox(height: 80),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October',
      'November', 'December'
    ];
    return names[month];
  }
}

class _PlantingCard extends StatelessWidget {
  final String crop;
  final String region;
  final String urgency;

  const _PlantingCard({
    required this.crop,
    required this.region,
    required this.urgency,
  });

  @override
  Widget build(BuildContext context) {
    final status = CropAdvisoryService.getPlantingStatus(
        crop, region, DateTime.now().month);
    final fertilizer =
        CropAdvisoryService.fertilizerGuide[crop];

    final borderColor = urgency == 'now'
        ? AppColors.success
        : urgency == 'soon'
            ? AppColors.warning
            : AppColors.divider;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('🌱',
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          title: Text(crop,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Best months: ${status.bestMonths.join(', ')}',
            style: AppTextStyles.caption,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          borderColor.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(status.message,
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                fontWeight:
                                    FontWeight.w600)),
                  ),
                  if (fertilizer != null) ...[
                    const SizedBox(height: 12),
                    Text('Fertilizer Guide:',
                        style: AppTextStyles.label
                            .copyWith(
                                fontWeight:
                                    FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (fertilizer['basal'] != null)
                      _FertRow('Basal',
                          fertilizer['basal'].toString()),
                    if (fertilizer['topdress1'] != null)
                      _FertRow('Top dress 1',
                          fertilizer['topdress1']
                              .toString()),
                    if (fertilizer['note'] != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 6),
                        child: Text(
                          '💡 ${fertilizer['note']}',
                          style: AppTextStyles.caption
                              .copyWith(
                                  fontStyle:
                                      FontStyle.italic),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FertRow extends StatelessWidget {
  final String label;
  final String value;
  const _FertRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
          Expanded(
              child:
                  Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary));
  }
}