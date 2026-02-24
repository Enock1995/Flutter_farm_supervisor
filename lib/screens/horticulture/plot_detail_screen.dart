// lib/screens/horticulture/plot_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/horticulture_provider.dart';
import '../../services/advisory/horticulture_advisory_service.dart';
import '../../widgets/primary_button.dart';

class PlotDetailScreen extends StatefulWidget {
  final HortiPlot plot;
  const PlotDetailScreen({super.key, required this.plot});

  @override
  State<PlotDetailScreen> createState() =>
      _PlotDetailScreenState();
}

class _PlotDetailScreenState
    extends State<PlotDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plot = widget.plot;
    final icon = HorticultureAdvisoryService.getCropIcon(
        plot.cropName);
    final stageInfo = plot.plantingDate != null
        ? HorticultureAdvisoryService.getCurrentStage(
            plot.cropName, plot.plantingDate!)
        : null;
    final marketInfo =
        HorticultureAdvisoryService.getMarketTiming(
            plot.cropName, plot.expectedHarvestDate);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primaryLight,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primaryLight
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(icon,
                          style: const TextStyle(
                              fontSize: 42)),
                      Text(plot.cropName,
                          style: AppTextStyles.heading2
                              .copyWith(
                                  color: Colors.white)),
                      Text(
                        '${plot.plotSizeM2.toInt()} m²  •  ${plot.irrigationMethod}',
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Progress'),
                Tab(text: 'Irrigation'),
                Tab(text: 'Market'),
                Tab(text: 'Stages'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProgressTab(
                plot: plot, stageInfo: stageInfo),
            _IrrigationTab(cropName: plot.cropName),
            _MarketTab(
                cropName: plot.cropName,
                marketInfo: marketInfo),
            _StagesTab(
                cropName: plot.cropName,
                stageInfo: stageInfo),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROGRESS TAB
// =============================================================================
class _ProgressTab extends StatelessWidget {
  final HortiPlot plot;
  final PlotStageInfo? stageInfo;
  const _ProgressTab(
      {required this.plot, required this.stageInfo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress card
          if (stageInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${stageInfo!.icon} ${stageInfo!.stageName}',
                          style: AppTextStyles.heading3,
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stageInfo!.progressPercent.toInt()}%',
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stageInfo!.progressPercent /
                          100,
                      backgroundColor: AppColors.divider,
                      valueColor:
                          const AlwaysStoppedAnimation(
                              AppColors.primaryLight),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (plot.plantingDate != null)
                    Text(
                      'Day ${plot.daysGrowing} — ${stageInfo!.daysInStage} days in this stage',
                      style: AppTextStyles.bodySmall,
                    ),
                  if (plot.expectedHarvestDate != null)
                    Text(
                      'Est. harvest: ${_fmtDate(plot.expectedHarvestDate!)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                              color: AppColors.accent,
                              fontWeight:
                                  FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Irrigation reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('💧',
                      style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Irrigation Now',
                            style: AppTextStyles.label
                                .copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.info)),
                        Text(
                            stageInfo!.irrigationFrequency,
                            style: AppTextStyles.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Current tasks
            Text('📋 Current Tasks',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight
                    .withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryLight
                        .withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  ...stageInfo!.currentTasks
                      .map((task) => Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 4),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Icon(
                                    Icons
                                        .check_box_outline_blank,
                                    size: 18,
                                    color: AppColors
                                        .primaryLight),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(task,
                                        style:
                                            AppTextStyles
                                                .body)),
                              ],
                            ),
                          )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('💡',
                            style:
                                TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(stageInfo!.tip,
                              style: AppTextStyles
                                  .bodySmall
                                  .copyWith(
                                      fontStyle:
                                          FontStyle
                                              .italic)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning
                        .withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add a planting date to track growth stages.',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Plot details summary
          Text('Plot Summary',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _DetailRow('🌱 Crop', plot.cropName),
          _DetailRow('📐 Plot Size',
              '${plot.plotSizeM2.toInt()} m² (${plot.plotSizeHa.toStringAsFixed(3)} ha)'),
          _DetailRow(
              '💧 Irrigation', plot.irrigationMethod),
          _DetailRow('🏪 Market', plot.targetMarket),
          if (plot.notes != null)
            _DetailRow('📝 Notes', plot.notes!),

          const SizedBox(height: 20),

          // Harvest recording
          if (plot.isActive) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  _showRecordHarvestDialog(context),
              icon: const Icon(Icons.agriculture),
              label: const Text('Record Harvest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(
                    color: AppColors.success),
                minimumSize:
                    const Size(double.infinity, 48),
              ),
            ),
          ] else if (plot.yieldKg != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success
                        .withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.success,
                          size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Harvested!',
                              style: AppTextStyles.body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight.w700,
                                      color: AppColors
                                          .success)),
                          Text(
                              'Yield: ${plot.yieldKg} kg',
                              style:
                                  AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  if (plot.revenueUsd != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Revenue: \$${plot.revenueUsd!.toStringAsFixed(2)}',
                      style: AppTextStyles.heading3
                          .copyWith(
                              color: AppColors.success),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

 void _showRecordHarvestDialog(BuildContext context) {
    final yieldController = TextEditingController();
    final revenueController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
            'Record Harvest — ${plot.cropName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: yieldController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Yield (kg)',
                prefixIcon:
                    const Icon(Icons.scale),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: revenueController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Revenue (USD)',
                prefixIcon: const Icon(
                    Icons.attach_money),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final yield_ = double.tryParse(
                  yieldController.text.trim());
              final revenue = double.tryParse(
                  revenueController.text.trim());
              if (yield_ == null) return;
              await context
                  .read<HorticultureProvider>()
                  .recordHarvest(
                    plotId: plot.id,
                    harvestDate: DateTime.now(),
                    yieldKg: yield_,
                    revenueUsd: revenue ?? 0,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

// =============================================================================
// IRRIGATION TAB
// =============================================================================
class _IrrigationTab extends StatelessWidget {
  final String cropName;
  const _IrrigationTab({required this.cropName});

  @override
  Widget build(BuildContext context) {
    final guide = HorticultureAdvisoryService
        .irrigationGuide[cropName];

    if (guide == null) {
      return Center(
          child: Text(
              'No irrigation guide for $cropName yet.'));
    }

    final schedule =
        guide['schedule'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IrrigCard('💧 Irrigation Method',
              guide['method'].toString(),
              color: AppColors.info),
          const SizedBox(height: 10),
          _IrrigCard('📊 Weekly Requirement',
              guide['weekly_requirement'].toString(),
              color: AppColors.primary),
          const SizedBox(height: 10),
          _IrrigCard(
              '⚠️ Critical Stages',
              guide['critical_stages'].toString(),
              color: AppColors.warning),
          const SizedBox(height: 20),

          Text('Signs to Watch',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('🌵 Water Stress (Under-irrigation)',
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
                const SizedBox(height: 4),
                Text(
                    guide['symptoms_of_stress']
                        .toString(),
                    style: AppTextStyles.body),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.info.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('🌊 Over-irrigation',
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.info)),
                const SizedBox(height: 4),
                Text(
                    guide['symptoms_of_overwatering']
                        .toString(),
                    style: AppTextStyles.body),
              ],
            ),
          ),

          if (schedule != null) ...[
            const SizedBox(height: 20),
            Text('Seasonal Schedule',
                style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...schedule.entries.map((e) => Container(
                  margin:
                      const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scheduleLabel(e.key),
                        style: AppTextStyles.label
                            .copyWith(
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(e.value.toString(),
                          style: AppTextStyles.body),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _scheduleLabel(String key) {
    const map = {
      'summer_rainy': '🌧️ Rainy Season (Oct–Apr)',
      'cool_dry': '❄️ Cool Dry Season (May–Aug)',
      'hot_dry': '☀️ Hot Dry Season (Sep–Oct)',
    };
    return map[key] ?? key;
  }
}

class _IrrigCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  const _IrrigCard(this.title, this.content,
      {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 4),
          Text(content, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// =============================================================================
// MARKET TAB
// =============================================================================
class _MarketTab extends StatelessWidget {
  final String cropName;
  final MarketTimingInfo marketInfo;
  const _MarketTab(
      {required this.cropName,
      required this.marketInfo});

  @override
  Widget build(BuildContext context) {
    final guide = HorticultureAdvisoryService
        .marketGuide[cropName];
    if (guide == null) {
      return Center(
          child:
              Text('No market guide for $cropName.'));
    }

    final peakMonths =
        List<int>.from(guide['peak_price_months'] as List);
    final currentMonth = DateTime.now().month;
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market timing alert
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: marketInfo.isPeakMonth
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: marketInfo.isPeakMonth
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Text(marketInfo.advice,
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 16),

          // Price range
          Row(
            children: [
              Expanded(
                child: _PriceCard(
                  label: '📈 Peak Price',
                  value: guide['peak_price_usd']
                      .toString(),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceCard(
                  label: '📉 Low Price',
                  value: guide['low_price_usd']
                      .toString(),
                  color: AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly price calendar
          Text('Monthly Price Calendar',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(12, (i) {
                final month = i + 1;
                final isPeak =
                    peakMonths.contains(month);
                final isNow = month == currentMonth;
                final lowMonths = List<int>.from(
                    guide['low_price_months'] as List);
                final isLow = lowMonths.contains(month);

                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPeak
                        ? AppColors.success
                        : isLow
                            ? AppColors.error
                                .withOpacity(0.15)
                            : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color: isNow
                          ? AppColors.accent
                          : Colors.transparent,
                      width: isNow ? 2 : 0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(monthNames[i],
                          style: AppTextStyles.caption
                              .copyWith(
                            fontWeight: isNow
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isPeak
                                ? Colors.white
                                : isLow
                                    ? AppColors.error
                                    : AppColors
                                        .textSecondary,
                          )),
                      if (isPeak)
                        const Text('💰',
                            style: TextStyle(
                                fontSize: 10)),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Legend(
                  color: AppColors.success,
                  label: 'Peak price'),
              const SizedBox(width: 12),
              _Legend(
                  color: AppColors.error
                      .withOpacity(0.3),
                  label: 'Low price'),
              const SizedBox(width: 12),
              _Legend(
                  color: Colors.transparent,
                  label: '= Now',
                  border: AppColors.accent),
            ],
          ),

          const SizedBox(height: 20),

          // Best markets
          Text('Best Markets',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          ...(guide['best_markets'] as List)
              .map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.store,
                            color: AppColors.primary,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(m.toString(),
                            style: AppTextStyles.body),
                      ],
                    ),
                  )),

          const SizedBox(height: 16),

          // Grading & packaging
          _MarketInfoCard('📦 Grading',
              guide['grading'].toString()),
          const SizedBox(height: 10),
          _MarketInfoCard('🎁 Packaging',
              guide['packaging'].toString()),
          const SizedBox(height: 10),
          _MarketInfoCard('⏰ Shelf Life',
              guide['shelf_life'].toString()),
          const SizedBox(height: 10),
          if (guide['profitability'] != null)
            _MarketInfoCard('💰 Profitability',
                guide['profitability'].toString()),
          const SizedBox(height: 10),
          if (guide['tip'] != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent
                        .withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('💡',
                      style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        guide['tip'].toString(),
                        style: AppTextStyles.body
                            .copyWith(
                                fontStyle:
                                    FontStyle.italic)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceCard(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MarketInfoCard extends StatelessWidget {
  final String title;
  final String content;
  const _MarketInfoCard(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(content,
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final Color? border;
  const _Legend(
      {required this.color,
      required this.label,
      this.border});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null
                ? Border.all(color: border!, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// =============================================================================
// STAGES TAB (full timeline)
// =============================================================================
class _StagesTab extends StatelessWidget {
  final String cropName;
  final PlotStageInfo? stageInfo;
  const _StagesTab(
      {required this.cropName,
      required this.stageInfo});

  @override
  Widget build(BuildContext context) {
    final stages = HorticultureAdvisoryService
        .growthStages[cropName];
    if (stages == null) {
      return Center(
          child: Text(
              'No stage data for $cropName yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      itemBuilder: (context, i) {
        final stage = stages[i];
        final isCurrent = stageInfo?.stageIndex == i;
        final isPast = stageInfo != null &&
            i < stageInfo!.stageIndex;
        final isLast = i == stages.length - 1;
        final color = isCurrent
            ? AppColors.primaryLight
            : isPast
                ? AppColors.success
                : AppColors.textHint;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryLight
                        : isPast
                            ? AppColors.success
                            : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color, width: 2),
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check,
                            size: 18,
                            color: Colors.white)
                        : isCurrent
                            ? Text(
                                stage['icon']
                                    as String,
                                style:
                                    const TextStyle(
                                        fontSize: 16))
                            : Text('${i + 1}',
                                style:
                                    AppTextStyles
                                        .caption
                                        .copyWith(
                                            color:
                                                color)),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: isPast
                        ? AppColors.success
                        : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primaryLight
                          .withOpacity(0.07)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primaryLight
                            .withOpacity(0.4)
                        : AppColors.divider,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stage['stage'] as String,
                            style: AppTextStyles.body
                                .copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? AppColors
                                      .primaryLight
                                  : AppColors
                                      .textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(
                                0.12),
                            borderRadius:
                                BorderRadius.circular(
                                    6),
                          ),
                          child: Text(
                            '~${stage['days']} days',
                            style: AppTextStyles
                                .caption
                                .copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 8),
                      Text('💧 ${stage['irrigation']}',
                          style: AppTextStyles
                              .bodySmall
                              .copyWith(
                                  color:
                                      AppColors.info)),
                      const SizedBox(height: 4),
                      Text('💡 ${stage['tip']}',
                          style: AppTextStyles
                              .bodySmall
                              .copyWith(
                                  fontStyle:
                                      FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}