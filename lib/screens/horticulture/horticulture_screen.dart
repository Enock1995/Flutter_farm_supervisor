// lib/screens/horticulture/horticulture_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/horticulture_provider.dart';
import '../../services/advisory/horticulture_advisory_service.dart';
import 'add_plot_screen.dart';
import 'plot_detail_screen.dart';

class HorticultureScreen extends StatefulWidget {
  const HorticultureScreen({super.key});

  @override
  State<HorticultureScreen> createState() =>
      _HorticultureScreenState();
}

class _HorticultureScreenState
    extends State<HorticultureScreen>
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
            .read<HorticultureProvider>()
            .loadPlots(user.userId);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Horticulture'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Plots'),
            Tab(text: 'Market Prices'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddPlotScreen()),
          );
        },
        backgroundColor: AppColors.primaryLight,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Plot',
            style: AppTextStyles.button),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyPlotsTab(),
          _MarketPricesTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — MY PLOTS
// =============================================================================
class _MyPlotsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HorticultureProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator());
        }

        if (provider.plots.isEmpty) {
          return _EmptyState();
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            _StatsRow(provider: provider),
            const SizedBox(height: 16),

            if (provider.activePlots.isNotEmpty) ...[
              _SectionLabel(
                  label:
                      '🌱 Active Plots (${provider.activePlots.length})'),
              const SizedBox(height: 8),
              ...provider.activePlots.map((plot) =>
                  _PlotCard(
                    plot: plot,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlotDetailScreen(plot: plot),
                      ),
                    ),
                  )),
            ],

            if (provider.completedPlots.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(
                  label:
                      '✅ Completed (${provider.completedPlots.length})'),
              const SizedBox(height: 8),
              ...provider.completedPlots.map((plot) =>
                  _PlotCard(
                    plot: plot,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlotDetailScreen(plot: plot),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HorticultureProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalM2 = provider.activePlots
        .fold(0.0, (s, p) => s + p.plotSizeM2);
    final totalRevenue = provider.completedPlots
        .fold(
            0.0,
            (s, p) =>
                s + (p.revenueUsd ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primaryLight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _StatPill(
              label: 'Active Plots',
              value:
                  '${provider.activePlots.length}'),
          _StatPill(
              label: 'Total Area',
              value:
                  '${totalM2.toInt()} m²'),
          _StatPill(
              label: 'Revenue',
              value:
                  '\$${totalRevenue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class _PlotCard extends StatelessWidget {
  final HortiPlot plot;
  final VoidCallback onTap;
  const _PlotCard(
      {required this.plot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = HorticultureAdvisoryService
        .getCropIcon(plot.cropName);
    final stageInfo = plot.plantingDate != null
        ? HorticultureAdvisoryService.getCurrentStage(
            plot.cropName, plot.plantingDate!)
        : null;
    final marketInfo =
        HorticultureAdvisoryService.getMarketTiming(
            plot.cropName, plot.expectedHarvestDate);

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon,
                        style: const TextStyle(
                            fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(plot.cropName,
                          style:
                              AppTextStyles.heading3),
                      Row(
                        children: [
                          Text(
                              '${plot.plotSizeM2.toInt()} m²',
                              style: AppTextStyles
                                  .bodySmall),
                          const Text(' • '),
                          Text(plot.irrigationMethod,
                              style: AppTextStyles
                                  .bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                // Market timing indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: marketInfo.isPeakMonth
                        ? AppColors.success
                            .withOpacity(0.1)
                        : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color: marketInfo.isPeakMonth
                          ? AppColors.success
                              .withOpacity(0.4)
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    marketInfo.isPeakMonth
                        ? '💰 Peak'
                        : '📊 Moderate',
                    style: AppTextStyles.caption
                        .copyWith(
                      color: marketInfo.isPeakMonth
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
              ],
            ),

            // Progress bar
            if (stageInfo != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stageInfo
                                .progressPercent /
                            100,
                        backgroundColor:
                            AppColors.divider,
                        valueColor:
                            const AlwaysStoppedAnimation(
                                AppColors
                                    .primaryLight),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stageInfo.progressPercent.toInt()}%',
                    style: AppTextStyles.caption
                        .copyWith(
                            fontWeight:
                                FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${stageInfo.icon} ${stageInfo.stageName}  •  Day ${plot.daysGrowing}',
                style: AppTextStyles.bodySmall
                    .copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500),
              ),
            ],

            // Harvest info
            if (plot.expectedHarvestDate != null &&
                plot.isActive) ...[
              const SizedBox(height: 6),
              Text(
                'Est. harvest: ${_fmtDate(plot.expectedHarvestDate!)}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600),
              ),
            ],

            if (!plot.isActive &&
                plot.yieldKg != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 14,
                      color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Yield: ${plot.yieldKg} kg  •  Revenue: \$${plot.revenueUsd?.toStringAsFixed(2) ?? '—'}',
                    style:
                        AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight:
                                FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥬',
                style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No Plots Yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first horticultural plot.',
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
// TAB 2 — MARKET PRICES
// =============================================================================
class _MarketPricesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final crops = HorticultureAdvisoryService.marketGuide.keys.toList();

    final peakNow = crops.where((c) {
      final months = List<int>.from(
          HorticultureAdvisoryService
                  .marketGuide[c]?['peak_price_months']
              as List? ??
              []);
      return months.contains(currentMonth);
    }).toList();

    final otherCrops =
        crops.where((c) => !peakNow.contains(c)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.store,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Zimbabwe market prices for ${_monthName(currentMonth)}. Buy when supply is high, sell during peak months.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (peakNow.isNotEmpty) ...[
          _SectionLabel(
              label:
                  '💰 Peak Price Now (${peakNow.length} crops)'),
          const SizedBox(height: 8),
          ...peakNow.map((crop) =>
              _MarketPriceCard(cropName: crop, isPeak: true)),
          const SizedBox(height: 16),
        ],

        _SectionLabel(label: '📊 All Crops'),
        const SizedBox(height: 8),
        ...otherCrops.map((crop) =>
            _MarketPriceCard(cropName: crop, isPeak: false)),
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

class _MarketPriceCard extends StatelessWidget {
  final String cropName;
  final bool isPeak;
  const _MarketPriceCard(
      {required this.cropName, required this.isPeak});

  @override
  Widget build(BuildContext context) {
    final guide = HorticultureAdvisoryService
        .marketGuide[cropName]!;
    final icon = HorticultureAdvisoryService
        .getCropIcon(cropName);
    final markets =
        List<String>.from(guide['best_markets'] as List);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPeak
              ? AppColors.success.withOpacity(0.4)
              : AppColors.divider,
          width: isPeak ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isPeak,
          leading: Text(icon,
              style: const TextStyle(fontSize: 28)),
          title: Text(cropName,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPeak
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPeak
                      ? '💰 ${guide['peak_price_usd']}'
                      : guide['low_price_usd'].toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: isPeak
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PricePill(
                          label: 'Peak',
                          value: guide['peak_price_usd']
                              .toString(),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PricePill(
                          label: 'Low',
                          value: guide['low_price_usd']
                              .toString(),
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Best Markets:',
                      style: AppTextStyles.label
                          .copyWith(
                              fontWeight:
                                  FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(markets.take(3).join(' • '),
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  if (guide['tip'] != null)
                    Text('💡 ${guide['tip']}',
                        style: AppTextStyles.caption
                            .copyWith(
                                fontStyle:
                                    FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PricePill(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color)),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
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