// lib/screens/crops/crop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/crop_provider.dart';
import '../../services/advisory/crop_advisory_service.dart';
import '../../widgets/primary_button.dart';

class CropDetailScreen extends StatefulWidget {
  final CropRecord crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() =>
      _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final stageInfo = crop.plantingDate != null
        ? CropAdvisoryService.getCurrentStage(
            crop.cropName, crop.plantingDate!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
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
                      AppColors.primary
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        stageInfo?.icon ?? '🌱',
                        style: const TextStyle(
                            fontSize: 48),
                      ),
                      Text(
                        crop.cropName,
                        style: AppTextStyles.heading2
                            .copyWith(color: Colors.white),
                      ),
                      if (crop.fieldSizeHa != null)
                        Text(
                          '${crop.fieldSizeHa} hectares',
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
                Tab(text: 'Pests'),
                Tab(text: 'Fertilizer'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProgressTab(crop: crop, stageInfo: stageInfo),
            _PestGuideTab(cropName: crop.cropName),
            _FertilizerTab(cropName: crop.cropName),
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
  final CropRecord crop;
  final CropStageInfo? stageInfo;

  const _ProgressTab(
      {required this.crop, required this.stageInfo});

  @override
  Widget build(BuildContext context) {
    final stages = CropAdvisoryService
            .growthStages[crop.cropName] ??
        [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress
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
                      Text(
                        '${stageInfo!.icon} ${stageInfo!.stageName}',
                        style: AppTextStyles.heading3,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
                      value:
                          stageInfo!.progressPercent / 100,
                      backgroundColor: AppColors.divider,
                      valueColor:
                          const AlwaysStoppedAnimation(
                              AppColors.primary),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (crop.plantingDate != null)
                    Text(
                      'Day ${crop.daysGrowing} since planting — ${stageInfo!.daysInStage} days in current stage',
                      style: AppTextStyles.bodySmall,
                    ),
                  if (crop.expectedHarvestDate != null)
                    Text(
                      'Est. harvest: ${_fmtDate(crop.expectedHarvestDate!)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current tasks
            Text('📋 Current Tasks',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.primary.withOpacity(0.2)),
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
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 18,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(task,
                                        style: AppTextStyles
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
                          child: Text(
                            stageInfo!.tip,
                            style: AppTextStyles
                                .bodySmall
                                .copyWith(
                                    fontStyle:
                                        FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add a planting date to track growth stages and get task reminders.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // All growth stages timeline
          Text('📅 Growth Stage Timeline',
              style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          ...stages.asMap().entries.map((entry) {
            final i = entry.key;
            final stage = entry.value;
            final isCurrent =
                stageInfo?.stageIndex == i;
            final isPast = stageInfo != null &&
                i < stageInfo!.stageIndex;

            return _StageTimelineTile(
              stageNumber: i + 1,
              stageName: stage['stage'] as String,
              days: stage['days'] as int,
              icon: stage['icon'] as String,
              isCurrent: isCurrent,
              isPast: isPast,
              isLast: i == stages.length - 1,
            );
          }),

          const SizedBox(height: 20),

          // Record harvest button
          if (crop.isActive)
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

          if (!crop.isActive && crop.yieldKg != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.success, size: 32),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Harvest Complete!',
                          style: AppTextStyles.body
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.success)),
                      Text(
                          'Yield: ${crop.yieldKg} kg',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Record Harvest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How much did you harvest from your ${crop.cropName}?',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: yieldController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Yield',
                suffixText: 'kg',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final yield_ = double.tryParse(
                  yieldController.text.trim());
              if (yield_ == null) return;
              await context
                  .read<CropProvider>()
                  .recordHarvest(
                    cropId: crop.id,
                    harvestDate: DateTime.now(),
                    yieldKg: yield_,
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

class _StageTimelineTile extends StatelessWidget {
  final int stageNumber;
  final String stageName;
  final int days;
  final String icon;
  final bool isCurrent;
  final bool isPast;
  final bool isLast;

  const _StageTimelineTile({
    required this.stageNumber,
    required this.stageName,
    required this.days,
    required this.icon,
    required this.isCurrent,
    required this.isPast,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppColors.primary
        : isPast
            ? AppColors.success
            : AppColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary
                    : isPast
                        ? AppColors.success
                        : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: isPast
                    ? const Icon(Icons.check,
                        size: 18, color: Colors.white)
                    : isCurrent
                        ? Text(icon,
                            style: const TextStyle(
                                fontSize: 16))
                        : Text('$stageNumber',
                            style: AppTextStyles.caption
                                .copyWith(color: color)),
              ),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 40,
                  color: isPast
                      ? AppColors.success
                      : AppColors.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: isCurrent
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text('~$days days',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PEST GUIDE TAB
// =============================================================================
class _PestGuideTab extends StatelessWidget {
  final String cropName;
  const _PestGuideTab({required this.cropName});

  @override
  Widget build(BuildContext context) {
    final pests =
        CropAdvisoryService.pestGuide[cropName] ?? [];

    if (pests.isEmpty) {
      return Center(
        child: Text(
          'No pest guide available for $cropName yet.',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pest = pests[index];
        final isHighSeverity = pest['severity'] == 'Very High' ||
            pest['severity'] == 'High';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighSeverity
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.divider,
            ),
          ),
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              leading: Text(pest['icon'] as String,
                  style: const TextStyle(fontSize: 28)),
              title: Text(pest['name'] as String,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHighSeverity
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pest['severity'] as String,
                      style: AppTextStyles.caption.copyWith(
                        color: isHighSeverity
                            ? AppColors.error
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(pest['type'] as String,
                      style: AppTextStyles.caption),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _PestSection('🔍 Symptoms',
                          pest['symptoms'] as String),
                      _PestSection('👁️ Scouting',
                          pest['scouting'] as String),
                      _PestSection('💊 Control',
                          pest['control'] as String),
                      _PestSection('🛡️ Prevention',
                          pest['prevention'] as String),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PestSection extends StatelessWidget {
  final String title;
  final String content;
  const _PestSection(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(content, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// =============================================================================
// FERTILIZER TAB
// =============================================================================
class _FertilizerTab extends StatelessWidget {
  final String cropName;
  const _FertilizerTab({required this.cropName});

  @override
  Widget build(BuildContext context) {
    final guide =
        CropAdvisoryService.fertilizerGuide[cropName];

    if (guide == null) {
      return Center(
        child: Text(
          'No fertilizer guide available for $cropName yet.',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    final deficiencies =
        guide['deficiencies'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application schedule
          Text('Fertilizer Schedule',
              style: AppTextStyles.heading3),
          const SizedBox(height: 12),

          if (guide['basal'] != null)
            _FertCard(
              step: 1,
              timing: 'At Planting (Basal)',
              product: guide['basal'].toString(),
              color: AppColors.info,
            ),
          if (guide['topdress1'] != null)
            _FertCard(
              step: 2,
              timing: 'Top Dress 1',
              product: guide['topdress1'].toString(),
              color: AppColors.primary,
            ),
          if (guide['topdress2'] != null)
            _FertCard(
              step: 3,
              timing: 'Top Dress 2',
              product: guide['topdress2'].toString(),
              color: AppColors.primaryLight,
            ),
          if (guide['foliar'] != null)
            _FertCard(
              step: 4,
              timing: 'Foliar Spray',
              product: guide['foliar'].toString(),
              color: AppColors.accent,
            ),

          if (guide['note'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('💡',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(guide['note'].toString(),
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                fontStyle:
                                    FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],

          if (deficiencies != null) ...[
            const SizedBox(height: 24),
            Text('Deficiency Symptoms',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'If you see these signs, your crop is lacking a nutrient:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            ...deficiencies.entries.map((entry) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(entry.key[0],
                            style: AppTextStyles.body
                                .copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.warning)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: AppTextStyles.body
                                    .copyWith(
                                        fontWeight:
                                            FontWeight
                                                .w600)),
                            Text(entry.value.toString(),
                                style: AppTextStyles
                                    .bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FertCard extends StatelessWidget {
  final int step;
  final String timing;
  final String product;
  final Color color;

  const _FertCard({
    required this.step,
    required this.timing,
    required this.product,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$step',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timing,
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(product,
                    style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}