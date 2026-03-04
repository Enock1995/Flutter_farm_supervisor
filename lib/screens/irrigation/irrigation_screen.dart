// lib/screens/irrigation/irrigation_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/irrigation_provider.dart';
import '../../services/irrigation_service.dart';

// Irrigation blue accent
const _iBlue = Color(0xFF0288D1);
const _iBlueDark = Color(0xFF01579B);
const _iBlueLight = Color(0xFF29B6F6);

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() =>
      _IrrigationScreenState();
}

class _IrrigationScreenState
    extends State<IrrigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<IrrigationProvider>()
            .load(user.userId);
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
        title: const Text('Irrigation Manager'),
        backgroundColor: _iBlueDark,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _iBlueLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: '💧 My Plots'),
            Tab(text: '📐 Calculator'),
            Tab(text: '📅 Schedule'),
            Tab(text: '📋 History'),
          ],
        ),
      ),
      floatingActionButton:
          _AddSetupFab(tabs: _tabs),
      body: Consumer<IrrigationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _iBlue));
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _PlotsTab(provider: provider),
              const _CalculatorTab(),
              _ScheduleTab(provider: provider),
              _HistoryTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// TAB 1 — MY PLOTS
// =============================================================================

class _PlotsTab extends StatelessWidget {
  final IrrigationProvider provider;
  const _PlotsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final setups = provider.activeSetups;

    return Column(
      children: [
        // Summary bar
        Container(
          color: _iBlueDark,
          padding: const EdgeInsets.fromLTRB(
              16, 8, 16, 14),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _TopStat(
                label: 'Irrigated plots',
                value: '${setups.length}',
                emoji: '💧',
              ),
              _TopStat(
                label: 'Total area',
                value:
                    '${provider.totalAreaHa.toStringAsFixed(2)} ha',
                emoji: '📐',
              ),
              _TopStat(
                label: 'Water this week',
                value: _formatLitres(
                    provider.weeklyWaterApplied),
                emoji: '🪣',
              ),
            ],
          ),
        ),

        // Setups list
        Expanded(
          child: setups.isEmpty
              ? _EmptySetups()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 100),
                  itemCount: setups.length,
                  itemBuilder: (_, i) =>
                      _SetupCard(
                    setup: setups[i],
                    provider: provider,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatLitres(double litres) {
    if (litres >= 1000000) {
      return '${(litres / 1000000).toStringAsFixed(1)} ML';
    }
    if (litres >= 1000) {
      return '${(litres / 1000).toStringAsFixed(1)} kL';
    }
    return '${litres.toStringAsFixed(0)} L';
  }
}

class _SetupCard extends StatelessWidget {
  final IrrigationSetup setup;
  final IrrigationProvider provider;
  const _SetupCard(
      {required this.setup, required this.provider});

  @override
  Widget build(BuildContext context) {
    final lastLog =
        provider.lastLogForSetup(setup.id);
    final daysSince =
        provider.daysSinceIrrigation(setup.id);

    Color statusColor = AppColors.textHint;
    String statusText = 'No irrigation logged';
    if (daysSince != null) {
      if (daysSince == 0) {
        statusColor = AppColors.success;
        statusText = 'Irrigated today ✅';
      } else if (daysSince <= 2) {
        statusColor = AppColors.success;
        statusText = '$daysSince day${daysSince == 1 ? '' : 's'} ago';
      } else if (daysSince <= 5) {
        statusColor = AppColors.warning;
        statusText =
            '⚠️ $daysSince days ago — check if due';
      } else {
        statusColor = AppColors.error;
        statusText =
            '🔴 $daysSince days ago — likely overdue';
      }
    }

    return Dismissible(
      key: Key(setup.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Setup?'),
          content: Text(
              'Remove "${setup.plotName}"? '
              'All irrigation logs for this plot will also be deleted.'),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(
                        color: AppColors.error))),
          ],
        ),
      ),
      onDismissed: (_) =>
          provider.deleteSetup(setup.id),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: _iBlue, width: 4),
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
              // Header row
              Row(
                children: [
                  Text(setup.systemEmoji,
                      style: const TextStyle(
                          fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(setup.plotName,
                            style: AppTextStyles.body
                                .copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700)),
                        Text(setup.systemLabel,
                            style: AppTextStyles
                                .caption
                                .copyWith(
                                    color: _iBlue)),
                      ],
                    ),
                  ),
                  // Area badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _iBlue.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${setup.areaHa.toStringAsFixed(2)} ha',
                      style: AppTextStyles.caption
                          .copyWith(
                        color: _iBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Crop + stage
              if (setup.currentCrop != null)
                Row(
                  children: [
                    const Icon(Icons.eco,
                        size: 14,
                        color: AppColors.primaryLight),
                    const SizedBox(width: 4),
                    Text(setup.currentCrop!,
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .primaryLight,
                                fontWeight:
                                    FontWeight.w700)),
                    if (setup.growthStage != null) ...[
                      const Text(' — ',
                          style: TextStyle(
                              color:
                                  AppColors.textHint)),
                      Expanded(
                        child: Text(
                          setup.growthStage!,
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: AppColors
                                      .textSecondary),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

              // Water source
              if (setup.waterSource != null)
                Row(
                  children: [
                    const Icon(Icons.water_drop,
                        size: 13, color: _iBlue),
                    const SizedBox(width: 4),
                    Text(setup.waterSource!,
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .textSecondary)),
                    if (setup.flowRateLph != null) ...[
                      const Text(' • ',
                          style: TextStyle(
                              color:
                                  AppColors.textHint)),
                      Text(
                        '${setup.flowRateLph!.toStringAsFixed(0)} L/hr',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .textHint),
                      ),
                    ],
                  ],
                ),

              const SizedBox(height: 8),
              Text(statusText,
                  style: AppTextStyles.caption
                      .copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700)),

              const SizedBox(height: 10),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showLogSheet(context, setup),
                      icon: const Icon(
                          Icons.water_drop,
                          size: 15,
                          color: _iBlue),
                      label: const Text('Log Irrigation',
                          style: TextStyle(color: _iBlue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: _iBlue),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showUpdateCropSheet(
                              context, setup, provider),
                      icon: const Icon(Icons.eco,
                          size: 15,
                          color:
                              AppColors.primaryLight),
                      label: const Text(
                          'Update Crop',
                          style: TextStyle(
                              color: AppColors
                                  .primaryLight)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primaryLight),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogSheet(
      BuildContext context, IrrigationSetup setup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _LogIrrigationSheet(setup: setup),
    );
  }

  void _showUpdateCropSheet(BuildContext context,
      IrrigationSetup setup, IrrigationProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateCropSheet(
          setup: setup, provider: prov),
    );
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
  String _crop = 'Maize';
  String _stage = '';
  String _system = 'drip';
  final _areaCtrl = TextEditingController(text: '1.0');
  final _etoCtrl = TextEditingController();
  final _rainCtrl = TextEditingController(text: '0');
  final _flowCtrl = TextEditingController();
  WaterRequirement? _result;

  @override
  void initState() {
    super.initState();
    _stage =
        IrrigationService.cropStages[_crop]!.first;
    final eto =
        IrrigationService.estimateEto(DateTime.now());
    _etoCtrl.text = eto.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _etoCtrl.dispose();
    _rainCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaCtrl.text);
    final eto = double.tryParse(_etoCtrl.text);
    final rain =
        double.tryParse(_rainCtrl.text) ?? 0.0;
    final flow = double.tryParse(_flowCtrl.text);

    if (area == null || eto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill in area and ETo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _result = IrrigationService.calculateRequirement(
        crop: _crop,
        stage: _stage,
        areaHa: area,
        systemType: _system,
        etoMmDay: eto,
        rainfallMmDay: rain,
        flowRateLph: flow,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stages =
        IrrigationService.cropStages[_crop] ?? [];

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_iBlueDark, _iBlue]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text('💧 Water Requirement',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Based on FAO-56 Penman-Monteith Kc × ETo method.',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Crop
          _Label('Crop'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _crop,
            decoration: _dropDec(),
            items: IrrigationService.crops
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: AppTextStyles.body)))
                .toList(),
            onChanged: (v) => setState(() {
              _crop = v!;
              _stage = IrrigationService
                  .cropStages[_crop]!.first;
            }),
          ),
          const SizedBox(height: 12),

          // Growth stage
          _Label('Growth Stage'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: stages.contains(_stage)
                ? _stage
                : stages.first,
            decoration: _dropDec(),
            isExpanded: true,
            items: stages
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: AppTextStyles.bodySmall,
                        overflow:
                            TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) =>
                setState(() => _stage = v!),
          ),
          const SizedBox(height: 12),

          // Irrigation system
          _Label('Irrigation System'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: IrrigationService.systemTypes
                .map((s) {
              final dummy = IrrigationSetup(
                id: '',
                userId: '',
                plotName: '',
                areaHa: 1,
                systemType: s,
                createdAt: DateTime.now(),
              );
              final selected = _system == s;
              return GestureDetector(
                onTap: () =>
                    setState(() => _system = s),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? _iBlue
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _iBlue
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    '${dummy.systemEmoji} ${dummy.systemLabel}',
                    style: AppTextStyles.caption
                        .copyWith(
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Inputs row
          Row(
            children: [
              Expanded(
                child: _InputField(
                  ctrl: _areaCtrl,
                  label: 'Area (ha)',
                  hint: '1.0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InputField(
                  ctrl: _etoCtrl,
                  label: 'ETo (mm/day)',
                  hint: '5.5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  ctrl: _rainCtrl,
                  label: 'Rainfall (mm/day)',
                  hint: '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InputField(
                  ctrl: _flowCtrl,
                  label: 'Flow rate (L/hr) opt.',
                  hint: 'e.g. 5000',
                ),
              ),
            ],
          ),

          // ETo hint
          Padding(
            padding:
                const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              '💡 ETo estimate for this month: '
              '${IrrigationService.estimateEto(DateTime.now()).toStringAsFixed(1)} mm/day',
              style: AppTextStyles.caption.copyWith(
                  color: _iBlue,
                  fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _iBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.calculate),
              label: const Text(
                  'Calculate Water Requirement',
                  style: TextStyle(
                      fontWeight: FontWeight.w700)),
            ),
          ),

          // Result
          if (_result != null) ...[
            const SizedBox(height: 16),
            _WaterResultCard(result: _result!),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  InputDecoration _dropDec() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      );
}

// =============================================================================
// TAB 3 — SCHEDULE
// =============================================================================

class _ScheduleTab extends StatelessWidget {
  final IrrigationProvider provider;
  const _ScheduleTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final eto =
        IrrigationService.estimateEto(DateTime.now());
    final allEntries = <IrrigationScheduleEntry>[];

    for (final setup in provider.activeSetups) {
      if (setup.currentCrop == null) continue;
      final lastLog =
          provider.lastLogForSetup(setup.id);
      final lastDate = lastLog?.irrigatedAt ??
          DateTime.now()
              .subtract(const Duration(days: 3));

      final entries =
          IrrigationService.generateSchedule(
        setup: setup,
        lastIrrigated: lastDate,
        etoMmDay: eto,
      );
      allEntries.addAll(entries);
    }

    allEntries.sort(
        (a, b) => a.date.compareTo(b.date));

    final overdue =
        allEntries.where((e) => e.isDue).toList();
    final upcoming = allEntries
        .where((e) => e.isUpcoming)
        .toList();

    if (provider.activeSetups.isEmpty) {
      return _EmptySchedule();
    }

    if (provider.activeSetups
        .every((s) => s.currentCrop == null)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text('🌱',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'No crops assigned',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Update Crop" on each plot\nto assign a crop and generate a schedule.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ETo info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _iBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _iBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Text('🌡️',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ETo estimate this month: ${eto.toStringAsFixed(1)} mm/day. '
                  'Schedule updates automatically based on crop stage and weather.',
                  style: AppTextStyles.caption
                      .copyWith(color: _iBlue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (overdue.isNotEmpty) ...[
          _SectionLabel('🔴 Due / Overdue',
              AppColors.error),
          const SizedBox(height: 8),
          ...overdue.map(
              (e) => _ScheduleCard(entry: e)),
          const SizedBox(height: 14),
        ],

        if (upcoming.isNotEmpty) ...[
          _SectionLabel('📅 Upcoming', _iBlue),
          const SizedBox(height: 8),
          ...upcoming.map(
              (e) => _ScheduleCard(entry: e)),
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final IrrigationScheduleEntry entry;
  const _ScheduleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];

    final dateStr = entry.isDue
        ? (DateTime.now().difference(entry.date).inDays == 0
            ? 'Today'
            : 'Overdue — ${entry.date.day} ${months[entry.date.month]}')
        : '${days[entry.date.weekday]} ${entry.date.day} ${months[entry.date.month]}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isDue
              ? AppColors.error.withOpacity(0.35)
              : _iBlue.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // Date bubble
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: entry.isDue
                  ? AppColors.error.withOpacity(0.1)
                  : _iBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.date.day}',
                  style: TextStyle(
                    color:
                        entry.isDue ? AppColors.error : _iBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  months[entry.date.month],
                  style: TextStyle(
                    color:
                        entry.isDue ? AppColors.error : _iBlue,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(entry.plotName,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700)),
                Text(dateStr,
                    style: AppTextStyles.caption
                        .copyWith(
                      color: entry.isDue
                          ? AppColors.error
                          : _iBlue,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Apply',
                      value:
                          '${entry.waterMm.toStringAsFixed(1)} mm',
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: 'Volume',
                      value:
                          '${(entry.waterLitres / 1000).toStringAsFixed(1)} kL',
                    ),
                    if (entry.durationMinutes > 0) ...[
                      const SizedBox(width: 12),
                      _MiniStat(
                        label: 'Run for',
                        value:
                            '${entry.durationMinutes.toStringAsFixed(0)} min',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 4 — HISTORY
// =============================================================================

class _HistoryTab extends StatelessWidget {
  final IrrigationProvider provider;
  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final logs = provider.logs;

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text('📋',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No irrigation logged yet',
                  style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                'Tap "Log Irrigation" on any plot\nto start tracking water use.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Tips section
        ExpansionTile(
          leading: const Text('💡',
              style: TextStyle(fontSize: 20)),
          title: Text('Irrigation Tips',
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          children: IrrigationService.irrigationTips
              .map((t) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 10),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(t['emoji']!,
                            style: const TextStyle(
                                fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(t['title']!,
                                  style: AppTextStyles
                                      .caption
                                      .copyWith(
                                          fontWeight:
                                              FontWeight
                                                  .w700)),
                              Text(t['detail']!,
                                  style: AppTextStyles
                                      .caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const Divider(),
        const SizedBox(height: 8),

        Text('Recent Irrigations',
            style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),

        ...logs.map((log) => Dismissible(
              key: Key(log.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white),
              ),
              onDismissed: (_) =>
                  provider.deleteLog(log.id),
              child: _LogCard(log: log),
            )),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final IrrigationLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop,
                color: _iBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(log.plotName,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Text(log.daysAgo,
                        style: AppTextStyles.caption
                            .copyWith(
                                color:
                                    AppColors.textHint)),
                    const Text(' • ',
                        style: TextStyle(
                            color: AppColors.textHint)),
                    Text(
                        '${log.durationMinutes.toStringAsFixed(0)} min',
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(log.waterAppliedLitres / 1000).toStringAsFixed(1)} kL',
                style: AppTextStyles.body.copyWith(
                  color: _iBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${log.waterAppliedMm.toStringAsFixed(1)} mm',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RESULT CARD
// =============================================================================

class _WaterResultCard extends StatelessWidget {
  final WaterRequirement result;
  const _WaterResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final dummy = IrrigationSetup(
      id: '',
      userId: '',
      plotName: '',
      areaHa: result.areaHa,
      systemType: result.systemType,
      createdAt: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _iBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _iBlue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧',
                  style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Water Requirement — ${result.crop}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _iBlue)),
            ],
          ),
          const SizedBox(height: 12),

          // Key numbers
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ResultStat(
                label: 'Daily ETc',
                value:
                    '${result.etcMmPerDay.toStringAsFixed(1)} mm/day',
              ),
              _ResultStat(
                label: 'Irrigation interval',
                value:
                    '${result.suggestedIntervalDays} day${result.suggestedIntervalDays == 1 ? '' : 's'}',
                highlight: true,
              ),
              _ResultStat(
                label: 'Per event (mm)',
                value:
                    '${result.waterPerIrrigationMm.toStringAsFixed(1)} mm',
              ),
              _ResultStat(
                label: 'Per event (volume)',
                value:
                    '${(result.waterPerIrrigationLitres / 1000).toStringAsFixed(1)} kL',
                highlight: true,
              ),
              _ResultStat(
                label: 'System efficiency',
                value:
                    '${(result.efficiency * 100).toStringAsFixed(0)}% (${dummy.systemLabel})',
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _iBlue.withOpacity(0.2)),
            ),
            child: Text(result.recommendation,
                style: AppTextStyles.bodySmall
                    .copyWith(height: 1.6)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEETS
// =============================================================================

class _LogIrrigationSheet extends StatefulWidget {
  final IrrigationSetup setup;
  const _LogIrrigationSheet({required this.setup});

  @override
  State<_LogIrrigationSheet> createState() =>
      _LogIrrigationSheetState();
}

class _LogIrrigationSheetState
    extends State<_LogIrrigationSheet> {
  final _durationCtrl = TextEditingController();
  final _flowCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _weather = 'mild';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.setup.flowRateLph != null) {
      _flowCtrl.text =
          widget.setup.flowRateLph!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _flowCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final duration =
        double.tryParse(_durationCtrl.text);
    final flow = double.tryParse(_flowCtrl.text);

    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter valid irrigation duration.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (flow == null || flow <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your system flow rate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context
        .read<IrrigationProvider>()
        .logIrrigation(
          userId: user.userId,
          setupId: widget.setup.id,
          plotName: widget.setup.plotName,
          areaHa: widget.setup.areaHa,
          irrigatedAt: _date,
          durationMinutes: duration,
          flowRateLph: flow,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          weatherCondition: _weather,
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Irrigation logged!'),
        backgroundColor: _iBlue,
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

    // Auto-calculate water applied preview
    final duration =
        double.tryParse(_durationCtrl.text) ?? 0;
    final flow =
        double.tryParse(_flowCtrl.text) ?? 0;
    final waterL = (duration / 60) * flow;
    final waterMm =
        waterL / (widget.setup.areaHa * 10000);

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
            Text(
              '💧 Log Irrigation — ${widget.setup.plotName}',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // Date
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now()
                      .subtract(
                          const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() => _date = d);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: _iBlue),
                    const SizedBox(width: 10),
                    Text(
                      '${_date.day} ${months[_date.month]} ${_date.year}',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    Text('Change',
                        style: AppTextStyles.caption
                            .copyWith(color: _iBlue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _InputField(
                    ctrl: _durationCtrl,
                    label: 'Duration (minutes) *',
                    hint: 'e.g. 90',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputField(
                    ctrl: _flowCtrl,
                    label: 'Flow rate (L/hr) *',
                    hint: 'e.g. 5000',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            // Live preview
            if (waterL > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _iBlue.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        '${(waterL / 1000).toStringAsFixed(1)} kL applied',
                        style: AppTextStyles.body
                            .copyWith(
                          color: _iBlue,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(
                        '${waterMm.toStringAsFixed(1)} mm',
                        style: AppTextStyles.body
                            .copyWith(
                          color: _iBlue,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Weather condition
            _Label('Weather condition'),
            const SizedBox(height: 6),
            Row(
              children: [
                ('☀️ Hot & Dry', 'hot_dry'),
                ('🌤️ Mild', 'mild'),
                ('🌡️ Cool', 'cool'),
                ('🌧️ Rainy', 'rainy'),
              ]
                  .map((w) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _weather = w.$2),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            margin:
                                const EdgeInsets.only(
                                    right: 4),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 8),
                            decoration: BoxDecoration(
                              color: _weather == w.$2
                                  ? _iBlue
                                      .withOpacity(0.12)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      8),
                              border: Border.all(
                                  color:
                                      _weather == w.$2
                                          ? _iBlue
                                          : AppColors
                                              .divider),
                            ),
                            child: Text(w.$1,
                                textAlign:
                                    TextAlign.center,
                                style: AppTextStyles
                                    .caption
                                    .copyWith(
                                  fontSize: 9.5,
                                  color: _weather == w.$2
                                      ? _iBlue
                                      : AppColors
                                          .textSecondary,
                                  fontWeight:
                                      _weather == w.$2
                                          ? FontWeight.w700
                                          : FontWeight
                                              .w400,
                                )),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes,
                    color: _iBlue),
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
                  backgroundColor: _iBlue,
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
                    : const Text('Save Irrigation Log',
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

// ---------------------------------------------------------------------------

class _UpdateCropSheet extends StatefulWidget {
  final IrrigationSetup setup;
  final IrrigationProvider provider;
  const _UpdateCropSheet(
      {required this.setup, required this.provider});

  @override
  State<_UpdateCropSheet> createState() =>
      _UpdateCropSheetState();
}

class _UpdateCropSheetState
    extends State<_UpdateCropSheet> {
  late String _crop;
  late String _stage;

  @override
  void initState() {
    super.initState();
    _crop = widget.setup.currentCrop ??
        IrrigationService.crops.first;
    final stages =
        IrrigationService.cropStages[_crop] ?? [];
    _stage = widget.setup.growthStage != null &&
            stages.contains(widget.setup.growthStage)
        ? widget.setup.growthStage!
        : stages.first;
  }

  @override
  Widget build(BuildContext context) {
    final stages =
        IrrigationService.cropStages[_crop] ?? [];

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
                24,
      ),
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
          Text('Update Crop — ${widget.setup.plotName}',
              style: AppTextStyles.heading3),
          const SizedBox(height: 16),

          _Label('Crop'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _crop,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
            ),
            items: IrrigationService.crops
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: AppTextStyles.body)))
                .toList(),
            onChanged: (v) => setState(() {
              _crop = v!;
              _stage = IrrigationService
                  .cropStages[_crop]!.first;
            }),
          ),
          const SizedBox(height: 12),

          _Label('Current Growth Stage'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: stages.contains(_stage)
                ? _stage
                : stages.first,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
            ),
            items: stages
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: AppTextStyles.bodySmall,
                        overflow:
                            TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) =>
                setState(() => _stage = v!),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await widget.provider.updateSetupCrop(
                  setupId: widget.setup.id,
                  crop: _crop,
                  stage: _stage,
                );
                if (!mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
              ),
              child: const Text('Update Crop',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddSetupFab extends StatefulWidget {
  final TabController tabs;
  const _AddSetupFab({required this.tabs});

  @override
  State<_AddSetupFab> createState() =>
      _AddSetupFabState();
}

class _AddSetupFabState extends State<_AddSetupFab> {
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
    if (_tabIndex != 0) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AddSetupSheet(),
      ),
      backgroundColor: _iBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text('Add Plot',
          style: AppTextStyles.button),
    );
  }
}

class _AddSetupSheet extends StatefulWidget {
  const _AddSetupSheet();

  @override
  State<_AddSetupSheet> createState() =>
      _AddSetupSheetState();
}

class _AddSetupSheetState
    extends State<_AddSetupSheet> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _flowCtrl = TextEditingController();
  String _system = 'drip';
  String? _waterSource;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _areaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter plot name and area.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final area = double.tryParse(_areaCtrl.text);
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid area.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context
        .read<IrrigationProvider>()
        .addSetup(
          userId: user.userId,
          plotName: _nameCtrl.text.trim(),
          areaHa: area,
          systemType: _system,
          flowRateLph:
              double.tryParse(_flowCtrl.text),
          waterSource: _waterSource,
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Irrigation plot added!'),
        backgroundColor: _iBlue,
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
                24,
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
            Text('Add Irrigation Plot',
                style: AppTextStyles.heading3),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _InputField(
                    ctrl: _nameCtrl,
                    label: 'Plot name *',
                    hint: 'e.g. Block A Tomatoes',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputField(
                    ctrl: _areaCtrl,
                    label: 'Area (ha) *',
                    hint: '1.0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Label('Irrigation System'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: IrrigationService.systemTypes
                  .map((s) {
                final dummy = IrrigationSetup(
                  id: '',
                  userId: '',
                  plotName: '',
                  areaHa: 1,
                  systemType: s,
                  createdAt: DateTime.now(),
                );
                return GestureDetector(
                  onTap: () =>
                      setState(() => _system = s),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6),
                    decoration: BoxDecoration(
                      color: _system == s
                          ? _iBlue
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                          color: _system == s
                              ? _iBlue
                              : AppColors.divider),
                    ),
                    child: Text(
                      '${dummy.systemEmoji} ${dummy.systemLabel}',
                      style: AppTextStyles.caption
                          .copyWith(
                        color: _system == s
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: _system == s
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _InputField(
                    ctrl: _flowCtrl,
                    label: 'Flow rate (L/hr) opt.',
                    hint: 'e.g. 5000',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _Label('Water source'),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _waterSource,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      10)),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10),
                          hintText: 'Select…',
                        ),
                        isExpanded: true,
                        items: IrrigationService
                            .waterSources
                            .map((s) =>
                                DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: AppTextStyles
                                            .bodySmall,
                                        overflow:
                                            TextOverflow
                                                .ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _waterSource = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iBlue,
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
                    : const Text('Add Plot',
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
// SHARED WIDGETS
// =============================================================================

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  const _InputField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          onChanged: onChanged,
          keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.divider),
            ),
            contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.caption
            .copyWith(fontWeight: FontWeight.w600));
  }
}

class _TopStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _TopStat({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textHint)),
        Text(value,
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w700)),
      ],
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
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textHint)),
        Text(value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  highlight ? _iBlue : AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.label
            .copyWith(fontWeight: FontWeight.w700, color: color));
  }
}

class _EmptySetups extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💧',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No irrigation plots yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap + Add Plot to register\nyour first irrigated field.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No schedule yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Add an irrigation plot and assign a crop\nto generate your schedule.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}