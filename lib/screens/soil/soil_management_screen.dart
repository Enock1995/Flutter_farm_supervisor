// lib/screens/soil/soil_management_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/soil_provider.dart';
import '../../services/soil_service.dart';

class SoilManagementScreen extends StatefulWidget {
  const SoilManagementScreen({super.key});

  @override
  State<SoilManagementScreen> createState() =>
      _SoilManagementScreenState();
}

class _SoilManagementScreenState
    extends State<SoilManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<SoilProvider>().load(user.userId);
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
        title: const Text('Soil Management'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Records'),
            Tab(text: 'Calculator'),
            Tab(text: 'Labs & Tips'),
          ],
        ),
      ),
      floatingActionButton: Consumer<SoilProvider>(
        builder: (_, __, ___) => FloatingActionButton.extended(
          onPressed: () => _showLogSheet(context),
          backgroundColor: AppColors.earth,
          icon: const Icon(Icons.science_outlined,
              color: Colors.white),
          label: Text('Log Soil Test',
              style: AppTextStyles.button),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _RecordsTab(),
          const _CalculatorTab(),
          const _LabsTipsTab(),
        ],
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogSoilTestSheet(),
    );
  }
}

// =============================================================================
// TAB 1 — MY RECORDS
// =============================================================================

class _RecordsTab extends StatelessWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SoilProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.earth));
        }

        if (provider.records.isEmpty) {
          return _EmptyRecords();
        }

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Summary header
            _SummaryHeader(provider: provider),
            const SizedBox(height: 16),

            // Records
            ...provider.records
                .map((r) => _SoilRecordCard(record: r)),
          ],
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final SoilProvider provider;
  const _SummaryHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HeaderStat(
              emoji: '🗺️',
              value: '${provider.totalPlots}',
              label: 'Plots'),
          _HeaderStat(
              emoji: '🔴',
              value: '${provider.plotsNeedingLime}',
              label: 'Need Lime'),
          _HeaderStat(
              emoji: '✅',
              value:
                  '${provider.totalPlots - provider.plotsNeedingLime}',
              label: 'pH OK'),
        ],
      ),
    );
  }
}

class _SoilRecordCard extends StatelessWidget {
  final SoilRecord record;
  const _SoilRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${record.testDate.day} ${months[record.testDate.month]} ${record.testDate.year}';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.white),
      ),
      onDismissed: (_) => context
          .read<SoilProvider>()
          .deleteRecord(record.id),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SoilDetailScreen(record: record),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: record.needsLime
                    ? AppColors.error
                    : AppColors.success,
                width: 4,
              ),
              top: const BorderSide(
                  color: AppColors.divider),
              right: const BorderSide(
                  color: AppColors.divider),
              bottom: const BorderSide(
                  color: AppColors.divider),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(record.plotName,
                          style: AppTextStyles.body
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w700)),
                    ),
                    Text(dateStr,
                        style: AppTextStyles.caption
                            .copyWith(
                                color:
                                    AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 10),

                // Nutrient grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (record.ph != null)
                      _NutrientChip(
                        label: 'pH',
                        value: record.ph!
                            .toStringAsFixed(1),
                        status: record.phStatus,
                        emoji: record.phEmoji,
                      ),
                    if (record.nitrogen != null)
                      _NutrientChip(
                        label: 'N',
                        value:
                            '${(record.nitrogen! * 100).toStringAsFixed(1)}%',
                        status: record.nStatus,
                        emoji: _statusEmoji(
                            record.nStatus),
                      ),
                    if (record.phosphorus != null)
                      _NutrientChip(
                        label: 'P',
                        value:
                            '${record.phosphorus!.toStringAsFixed(0)} ppm',
                        status: record.pStatus,
                        emoji: _statusEmoji(
                            record.pStatus),
                      ),
                    if (record.potassium != null)
                      _NutrientChip(
                        label: 'K',
                        value:
                            '${record.potassium!.toStringAsFixed(0)} ppm',
                        status: record.kStatus,
                        emoji: _statusEmoji(
                            record.kStatus),
                      ),
                    if (record.organicMatter != null)
                      _NutrientChip(
                        label: 'OM',
                        value:
                            '${record.organicMatter!.toStringAsFixed(1)}%',
                        status: record.omStatus,
                        emoji: _statusEmoji(
                            record.omStatus),
                      ),
                  ],
                ),

                if (record.texture != null ||
                    record.plotSizeHa != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (record.texture != null)
                        _InfoTag(
                            '🪨 ${record.texture}'),
                      if (record.plotSizeHa != null)
                        _InfoTag(
                            '📐 ${record.plotSizeHa!.toStringAsFixed(2)} ha'),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.needsLime
                          ? '⚠️ Needs liming'
                          : '✅ pH good',
                      style: AppTextStyles.caption
                          .copyWith(
                        color: record.needsLime
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('Tap for recommendations →',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .primaryLight)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'Very Low':  return '🔴';
      case 'Low':       return '🟠';
      case 'Medium':    return '🟡';
      case 'High':      return '🟢';
      case 'Very High': return '🔵';
      default:          return '❓';
    }
  }
}

// =============================================================================
// TAB 2 — CALCULATOR
// =============================================================================

class _CalculatorTab extends StatefulWidget {
  const _CalculatorTab();

  @override
  State<_CalculatorTab> createState() =>
      _CalculatorTabState();
}

class _CalculatorTabState
    extends State<_CalculatorTab> {
  // Lime calc
  final _currentPhCtrl = TextEditingController();
  final _targetPhCtrl =
      TextEditingController(text: '6.2');
  final _plotSizeLimeCtrl =
      TextEditingController(text: '1.0');
  String _limeTexture = 'Loamy';
  LimeCalcResult? _limeResult;

  // Fertilizer calc
  String _fertCrop = 'Maize';
  final _plotSizeFertCtrl =
      TextEditingController(text: '1.0');
  String _nStatus = 'Low';
  String _pStatus = 'Low';
  String _kStatus = 'Medium';
  List<FertilizerCalcResult>? _fertResults;

  @override
  void dispose() {
    _currentPhCtrl.dispose();
    _targetPhCtrl.dispose();
    _plotSizeLimeCtrl.dispose();
    _plotSizeFertCtrl.dispose();
    super.dispose();
  }

  void _calcLime() {
    final currentPh =
        double.tryParse(_currentPhCtrl.text);
    final targetPh =
        double.tryParse(_targetPhCtrl.text);
    final size =
        double.tryParse(_plotSizeLimeCtrl.text);

    if (currentPh == null ||
        targetPh == null ||
        size == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _limeResult = SoilService.calculateLime(
        currentPh: currentPh,
        targetPh: targetPh,
        texture: _limeTexture,
        plotSizeHa: size,
      );
    });
  }

  void _calcFertilizer() {
    final size =
        double.tryParse(_plotSizeFertCtrl.text);
    if (size == null) return;

    setState(() {
      _fertResults =
          SoilService.calculateFertilizer(
        crop: _fertCrop,
        plotSizeHa: size,
        nStatus: _nStatus,
        pStatus: _pStatus,
        kStatus: _kStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LIME CALCULATOR ──
          _CalcHeader(
              emoji: '🪨',
              title: 'Lime Calculator',
              subtitle:
                  'How much lime does your soil need?'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CalcField(
                        controller: _currentPhCtrl,
                        label: 'Current pH',
                        hint: 'e.g. 5.2',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CalcField(
                        controller: _targetPhCtrl,
                        label: 'Target pH',
                        hint: '6.2',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CalcField(
                        controller: _plotSizeLimeCtrl,
                        label: 'Plot size (ha)',
                        hint: '1.0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Soil Texture',
                              style: AppTextStyles
                                  .caption),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<
                              String>(
                            value: _limeTexture,
                            decoration:
                                InputDecoration(
                              filled: true,
                              fillColor:
                                  AppColors.background,
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                borderSide:
                                    const BorderSide(
                                        color: AppColors
                                            .divider),
                              ),
                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 12,
                                      vertical: 10),
                            ),
                            items: SoilService.textures
                                .map((t) =>
                                    DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: AppTextStyles
                                                .bodySmall)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() =>
                                    _limeTexture =
                                        v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calcLime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  10)),
                    ),
                    child: const Text(
                        'Calculate Lime Requirement'),
                  ),
                ),
              ],
            ),
          ),

          // Lime result
          if (_limeResult != null) ...[
            const SizedBox(height: 12),
            _LimeResultCard(result: _limeResult!),
          ],

          const SizedBox(height: 24),

          // ── FERTILIZER CALCULATOR ──
          _CalcHeader(
              emoji: '🌱',
              title: 'Fertilizer Calculator',
              subtitle:
                  'Basal & top dress quantities per crop'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Crop',
                              style:
                                  AppTextStyles.caption),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<
                              String>(
                            value: _fertCrop,
                            decoration:
                                InputDecoration(
                              filled: true,
                              fillColor:
                                  AppColors.background,
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                borderSide:
                                    const BorderSide(
                                        color: AppColors
                                            .divider),
                              ),
                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 12,
                                      vertical: 10),
                            ),
                            items: SoilService.crops
                                .map((c) =>
                                    DropdownMenuItem(
                                        value: c,
                                        child: Text(c,
                                            style: AppTextStyles
                                                .bodySmall)))
                                .toList(),
                            onChanged: (v) =>
                                setState(
                                    () => _fertCrop =
                                        v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CalcField(
                        controller: _plotSizeFertCtrl,
                        label: 'Plot size (ha)',
                        hint: '1.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Soil status inputs
                Text('Soil Nutrient Status',
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700)),
                Text(
                    '(From soil test or best estimate)',
                    style: AppTextStyles.caption
                        .copyWith(
                            color:
                                AppColors.textHint)),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Nitrogen (N)',
                  value: _nStatus,
                  onChanged: (v) =>
                      setState(() => _nStatus = v),
                ),
                _StatusRow(
                  label: 'Phosphorus (P)',
                  value: _pStatus,
                  onChanged: (v) =>
                      setState(() => _pStatus = v),
                ),
                _StatusRow(
                  label: 'Potassium (K)',
                  value: _kStatus,
                  onChanged: (v) =>
                      setState(() => _kStatus = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calcFertilizer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  10)),
                    ),
                    child: const Text(
                        'Calculate Fertilizer Program'),
                  ),
                ),
              ],
            ),
          ),

          // Fertilizer results
          if (_fertResults != null) ...[
            const SizedBox(height: 12),
            ..._fertResults!.map(
                (r) => _FertResultCard(result: r)),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3 — LABS & TIPS
// =============================================================================

class _LabsTipsTab extends StatelessWidget {
  const _LabsTipsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soil testing labs
          Text('🔬 Soil Testing Labs in Zimbabwe',
              style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            'Get a soil test done before every planting season '
            'for accurate recommendations.',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...SoilService.labs.map((lab) => Container(
                margin: const EdgeInsets.only(
                    bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Text('🔬',
                        style: TextStyle(
                            fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(lab['name']!,
                              style: AppTextStyles
                                  .body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w700)),
                          Text(lab['contact']!,
                              style: AppTextStyles
                                  .caption
                                  .copyWith(
                                      color: AppColors
                                          .primaryLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // Tips
          Text('💡 Soil Health Tips',
              style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          ..._tips.map((tip) => Container(
                margin: const EdgeInsets.only(
                    bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.earth
                      .withOpacity(0.06),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.earth
                          .withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(tip['emoji']!,
                        style: const TextStyle(
                            fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(tip['title']!,
                              style: AppTextStyles
                                  .body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w700)),
                          const SizedBox(height: 4),
                          Text(tip['detail']!,
                              style: AppTextStyles
                                  .bodySmall
                                  .copyWith(
                                      height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _tips = [
    {
      'emoji': '🧪',
      'title': 'Test every 3 years minimum',
      'detail':
          'Soil chemistry changes with each crop season. '
              'Test pH and nutrients before every tobacco or '
              'horticulture season, and every 3 years for field crops.',
    },
    {
      'emoji': '🪨',
      'title': 'Lime well in advance',
      'detail':
          'Apply lime at least 4–6 weeks before planting. '
              'Lime reacts slowly — ploughing it in during land preparation '
              'gives best results. Aim for pH 5.8–6.5 for most crops.',
    },
    {
      'emoji': '♻️',
      'title': 'Never burn crop residues',
      'detail':
          'Burning destroys organic matter, beneficial microbes, and surface '
              'nutrients. Instead, incorporate residues by ploughing, or '
              'use as mulch. This builds organic matter over time.',
    },
    {
      'emoji': '🌿',
      'title': 'Apply manure before the rains',
      'detail':
          'Apply 5–10 tonnes/ha of kraal manure before the first rains '
              'and plough it in. This releases nutrients slowly through the '
              'season and improves water-holding capacity.',
    },
    {
      'emoji': '🔄',
      'title': 'Rotate crops annually',
      'detail':
          'Crop rotation breaks pest cycles, reduces disease buildup, '
              'and balances nutrient depletion. Follow maize with soybeans '
              '(fixes nitrogen), then a vegetable crop.',
    },
    {
      'emoji': '💧',
      'title': 'Avoid waterlogging',
      'detail':
          'Waterlogged soils become anaerobic, killing beneficial organisms '
              'and causing nutrient loss. Ensure proper drainage channels '
              'and avoid compaction from heavy machinery on wet soil.',
    },
  ];
}

// =============================================================================
// DETAIL SCREEN
// =============================================================================

class SoilDetailScreen extends StatefulWidget {
  final SoilRecord record;
  const SoilDetailScreen(
      {super.key, required this.record});

  @override
  State<SoilDetailScreen> createState() =>
      _SoilDetailScreenState();
}

class _SoilDetailScreenState
    extends State<SoilDetailScreen> {
  String? _targetCrop;

  @override
  Widget build(BuildContext context) {
    final recs =
        SoilService.generateRecommendations(
      widget.record,
      targetCrop: _targetCrop,
    );

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${widget.record.testDate.day} '
        '${months[widget.record.testDate.month]} '
        '${widget.record.testDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.record.plotName),
        actions: [
          // Crop selector for tailored recs
          Padding(
            padding:
                const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _targetCrop,
              hint: const Text('For crop…',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              dropdownColor: AppColors.primaryDark,
              style: const TextStyle(
                  color: Colors.white),
              underline: const SizedBox.shrink(),
              iconEnabledColor: Colors.white,
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('All crops')),
                ...SoilService.crops.map((c) =>
                    DropdownMenuItem(
                        value: c, child: Text(c))),
              ],
              onChanged: (v) =>
                  setState(() => _targetCrop = v),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Test info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.record.plotName,
                          style: AppTextStyles
                              .heading3,
                        ),
                      ),
                      Text(dateStr,
                          style: AppTextStyles
                              .caption
                              .copyWith(
                                  color: AppColors
                                      .textHint)),
                    ],
                  ),
                  if (widget.record.labName !=
                      null) ...[
                    const SizedBox(height: 4),
                    Text(
                        '🔬 ${widget.record.labName}',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .textSecondary)),
                  ],
                  const Divider(height: 20),

                  // Nutrient readings
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (widget.record.ph != null)
                        _ReadingTile(
                          label: 'pH',
                          value: widget.record.ph!
                              .toStringAsFixed(1),
                          status:
                              widget.record.phStatus,
                          emoji: widget.record.phEmoji,
                        ),
                      if (widget.record.nitrogen !=
                          null)
                        _ReadingTile(
                          label: 'Nitrogen',
                          value:
                              '${(widget.record.nitrogen! * 100).toStringAsFixed(2)}%',
                          status:
                              widget.record.nStatus,
                          emoji: _se(
                              widget.record.nStatus),
                        ),
                      if (widget.record.phosphorus !=
                          null)
                        _ReadingTile(
                          label: 'Phosphorus',
                          value:
                              '${widget.record.phosphorus!.toStringAsFixed(1)} ppm',
                          status:
                              widget.record.pStatus,
                          emoji: _se(
                              widget.record.pStatus),
                        ),
                      if (widget.record.potassium !=
                          null)
                        _ReadingTile(
                          label: 'Potassium',
                          value:
                              '${widget.record.potassium!.toStringAsFixed(0)} ppm',
                          status:
                              widget.record.kStatus,
                          emoji: _se(
                              widget.record.kStatus),
                        ),
                      if (widget.record
                              .organicMatter !=
                          null)
                        _ReadingTile(
                          label: 'Org. Matter',
                          value:
                              '${widget.record.organicMatter!.toStringAsFixed(1)}%',
                          status:
                              widget.record.omStatus,
                          emoji: _se(
                              widget.record.omStatus),
                        ),
                    ],
                  ),

                  if (widget.record.texture !=
                          null ||
                      widget.record.plotSizeHa !=
                          null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.record.texture !=
                            null)
                          _InfoTag(
                              '🪨 ${widget.record.texture}'),
                        if (widget.record.plotSizeHa !=
                            null)
                          _InfoTag(
                              '📐 ${widget.record.plotSizeHa!.toStringAsFixed(2)} ha'),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            Row(
              children: [
                Text('📋 Recommendations',
                    style: AppTextStyles.heading3),
                if (_targetCrop != null) ...[
                  const SizedBox(width: 8),
                  _InfoTag('For $_targetCrop'),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ...recs.map(
                (r) => _RecommendationCard(rec: r)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _se(String status) {
    switch (status) {
      case 'Very Low':  return '🔴';
      case 'Low':       return '🟠';
      case 'Medium':    return '🟡';
      case 'High':      return '🟢';
      case 'Very High': return '🔵';
      default:          return '❓';
    }
  }
}

// =============================================================================
// LOG SOIL TEST SHEET
// =============================================================================

class _LogSoilTestSheet extends StatefulWidget {
  const _LogSoilTestSheet();

  @override
  State<_LogSoilTestSheet> createState() =>
      _LogSoilTestSheetState();
}

class _LogSoilTestSheetState
    extends State<_LogSoilTestSheet> {
  final _plotCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _nCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  final _omCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _labCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _texture;
  DateTime _testDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in [
      _plotCtrl, _phCtrl, _nCtrl, _pCtrl,
      _kCtrl, _omCtrl, _sizeCtrl, _labCtrl, _notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_plotCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a plot name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<SoilProvider>().addRecord(
          userId: user.userId,
          plotName: _plotCtrl.text.trim(),
          testDate: _testDate,
          ph: double.tryParse(_phCtrl.text),
          nitrogen: double.tryParse(_nCtrl.text),
          phosphorus: double.tryParse(_pCtrl.text),
          potassium: double.tryParse(_kCtrl.text),
          organicMatter:
              double.tryParse(_omCtrl.text),
          texture: _texture,
          plotSizeHa:
              double.tryParse(_sizeCtrl.text),
          labName: _labCtrl.text.trim().isEmpty
              ? null
              : _labCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Soil test recorded!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Log Soil Test',
                style: AppTextStyles.heading3),
            Text(
              'Enter values from your lab report. '
              'You can fill in just pH if that\'s all you have.',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Plot name + date
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _plotCtrl,
                    decoration: InputDecoration(
                      labelText: 'Plot name *',
                      prefixIcon: const Icon(
                          Icons.map_outlined,
                          color: AppColors.earth),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  10)),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _testDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        setState(() => _testDate = d);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.earth),
                          Text(
                            '${_testDate.day} ${months[_testDate.month]}',
                            style: AppTextStyles
                                .caption
                                .copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // pH (most important)
            Row(
              children: [
                Expanded(
                  child: _NumField(
                      ctrl: _phCtrl,
                      label: 'pH',
                      hint: 'e.g. 5.8'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumField(
                      ctrl: _sizeCtrl,
                      label: 'Plot size (ha)',
                      hint: '1.0'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // NPK + OM
            Text('Nutrients (from lab report)',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _NumField(
                        ctrl: _nCtrl,
                        label: 'N (%)',
                        hint: '0.15')),
                const SizedBox(width: 8),
                Expanded(
                    child: _NumField(
                        ctrl: _pCtrl,
                        label: 'P (ppm)',
                        hint: '8')),
                const SizedBox(width: 8),
                Expanded(
                    child: _NumField(
                        ctrl: _kCtrl,
                        label: 'K (ppm)',
                        hint: '120')),
                const SizedBox(width: 8),
                Expanded(
                    child: _NumField(
                        ctrl: _omCtrl,
                        label: 'OM (%)',
                        hint: '2.1')),
              ],
            ),
            const SizedBox(height: 12),

            // Texture
            Text('Soil Texture',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: SoilService.textures
                  .map((t) => GestureDetector(
                        onTap: () => setState(
                            () => _texture = t),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 150),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                          decoration: BoxDecoration(
                            color: _texture == t
                                ? AppColors.earth
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    20),
                            border: Border.all(
                              color: _texture == t
                                  ? AppColors.earth
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(t,
                              style: AppTextStyles
                                  .caption
                                  .copyWith(
                                color: _texture == t
                                    ? Colors.white
                                    : AppColors
                                        .textPrimary,
                                fontWeight:
                                    _texture == t
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                              )),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Lab + notes
            TextField(
              controller: _labCtrl,
              decoration: InputDecoration(
                labelText: 'Lab name (optional)',
                prefixIcon: const Icon(Icons.science,
                    color: AppColors.earth),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.earth),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earth,
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
                    : const Text('Save Soil Record',
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

// =============================================================================
// RESULT CARDS
// =============================================================================

class _LimeResultCard extends StatelessWidget {
  final LimeCalcResult result;
  const _LimeResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                const Color(0xFF5D4037).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🪨 Lime Requirement',
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  label: 'Rate',
                  value:
                      '${result.limeRatePerHa.toStringAsFixed(1)} t/ha',
                ),
              ),
              Expanded(
                child: _ResultStat(
                  label: 'Total needed',
                  value:
                      '${result.totalLimeNeeded.toStringAsFixed(1)} tonnes',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(result.limeType,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Text(result.basis,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textHint)),
          const SizedBox(height: 10),
          ...result.applicationNotes.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: Color(0xFF5D4037))),
                  Expanded(
                      child: Text(n,
                          style:
                              AppTextStyles.caption)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FertResultCard extends StatelessWidget {
  final FertilizerCalcResult result;
  const _FertResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(result.phase,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(height: 8),
          Text(result.product,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  label: 'Rate',
                  value:
                      '${result.ratePerHa.toStringAsFixed(0)} kg/ha',
                ),
              ),
              Expanded(
                child: _ResultStat(
                  label: 'Total for plot',
                  value:
                      '${result.totalForPlot.toStringAsFixed(0)} kg',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow2(
              icon: '⏰', label: 'When', value: result.timing),
          _DetailRow2(
              icon: '🔧',
              label: 'How',
              value: result.method),
          if (result.notes.isNotEmpty)
            ...result.notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ',
                        style: TextStyle(fontSize: 12)),
                    Expanded(
                        child: Text(n,
                            style: AppTextStyles.caption
                                .copyWith(
                                    color: AppColors
                                        .textSecondary))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final SoilRecommendation rec;
  const _RecommendationCard({required this.rec});

  Color get _bgColor {
    switch (rec.priority) {
      case 'urgent': return AppColors.error.withOpacity(0.06);
      case 'high':   return AppColors.warning.withOpacity(0.06);
      case 'medium': return AppColors.info.withOpacity(0.06);
      default:       return AppColors.success.withOpacity(0.06);
    }
  }

  Color get _borderColor {
    switch (rec.priority) {
      case 'urgent': return AppColors.error.withOpacity(0.3);
      case 'high':   return AppColors.warning.withOpacity(0.3);
      case 'medium': return AppColors.info.withOpacity(0.3);
      default:       return AppColors.success.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rec.categoryEmoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(rec.title,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700)),
              ),
              Text(rec.priorityEmoji,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(rec.detail,
              style: AppTextStyles.bodySmall
                  .copyWith(height: 1.5)),
          if (rec.productExample != null ||
              rec.quantity != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (rec.productExample != null)
                  Expanded(
                    child: Text(
                      '🧪 ${rec.productExample}',
                      style: AppTextStyles.caption
                          .copyWith(
                              color:
                                  AppColors.textSecondary,
                              fontWeight:
                                  FontWeight.w600),
                    ),
                  ),
                if (rec.quantity != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    child: Text(rec.quantity!,
                        style: AppTextStyles.caption
                            .copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _CalcHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _CalcHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading3),
            Text(subtitle,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _CalcField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _CalcField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.divider),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _statuses = [
    'Very Low', 'Low', 'Medium', 'High', 'Very High'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isDense: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          style: AppTextStyles.bodySmall)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final String emoji;
  const _NutrientChip({
    required this.label,
    required this.value,
    required this.status,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          Text(value,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          Text(status, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final String emoji;
  const _ReadingTile({
    required this.label,
    required this.value,
    required this.status,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.heading3
                  .copyWith(fontSize: 18)),
          Text(status,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _ResultStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18,
            color: highlight
                ? AppColors.primaryLight
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow2 extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _DetailRow2({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon ',
              style: const TextStyle(fontSize: 13)),
          SizedBox(
            width: 40,
            child: Text('$label:',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  const _NumField({
    required this.ctrl,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String text;
  const _InfoTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _HeaderStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
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

class _EmptyRecords extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No soil records yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap + Log Soil Test to record\nyour first soil analysis.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}