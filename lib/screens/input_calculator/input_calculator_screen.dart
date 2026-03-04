// lib/screens/input_calculator/input_calculator_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/input_calculator_provider.dart';
import '../../services/input_calculator_service.dart';

const _calcColor = Color(0xFF6A1B9A); // purple accent
const _calcLight = Color(0xFFAB47BC);

class InputCalculatorScreen extends StatefulWidget {
  const InputCalculatorScreen({super.key});

  @override
  State<InputCalculatorScreen> createState() =>
      _InputCalculatorScreenState();
}

class _InputCalculatorScreenState
    extends State<InputCalculatorScreen>
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
            .read<InputCalculatorProvider>()
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
        title: const Text('Input Calculator'),
        backgroundColor: _calcColor,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _calcLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: '🧪 Spray'),
            Tab(text: '🌱 Seed'),
            Tab(text: '🪣 Tank Mix'),
            Tab(text: '📋 Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _SprayTab(),
          _SeedTab(),
          _TankMixTab(),
          _SavedTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — SPRAY CALCULATOR
// =============================================================================

class _SprayTab extends StatefulWidget {
  const _SprayTab();

  @override
  State<_SprayTab> createState() =>
      _SprayTabState();
}

class _SprayTabState extends State<_SprayTab> {
  final _productCtrl = TextEditingController();
  final _areaCtrl =
      TextEditingController(text: '1.0');
  final _doseCtrl = TextEditingController();
  final _tankCtrl =
      TextEditingController(text: '16');
  String _doseUnit = 'ml/ha';
  String _equipment =
      'Knapsack sprayer (field crops)';
  SprayCalcResult? _result;

  @override
  void dispose() {
    _productCtrl.dispose();
    _areaCtrl.dispose();
    _doseCtrl.dispose();
    _tankCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_productCtrl.text.trim().isEmpty ||
        _doseCtrl.text.trim().isEmpty) {
      _snack('Enter product name and dose rate.');
      return;
    }
    final area = double.tryParse(_areaCtrl.text);
    final dose = double.tryParse(_doseCtrl.text);
    final tank = double.tryParse(_tankCtrl.text);
    if (area == null || dose == null || tank == null) {
      _snack('Enter valid numbers for area, dose, and tank size.');
      return;
    }
    setState(() {
      _result = InputCalculatorService.calculateSpray(
        productName: _productCtrl.text.trim(),
        areaHa: area,
        productDose: dose,
        doseUnit: _doseUnit,
        equipment: _equipment,
        tankCapacityL: tank,
      );
    });
  }

  void _save() {
    if (_result == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    context.read<InputCalculatorProvider>().saveCalculation(
          userId: user.userId,
          type: 'spray',
          title: '${_result!.productName} — ${_result!.areaHa.toStringAsFixed(2)} ha',
          summary:
              '${_result!.tanksNeeded} tank${_result!.tanksNeeded == 1 ? '' : 's'} · '
              '${_result!.waterVolumeLitres.toStringAsFixed(0)} L water · '
              '${_result!.unit == 'g/L' ? _result!.productAmountG.toStringAsFixed(0) + ' g' : _result!.productAmountMl.toStringAsFixed(0) + ' ml'} product',
          inputs: {
            'product': _productCtrl.text,
            'area': _areaCtrl.text,
            'dose': _doseCtrl.text,
            'unit': _doseUnit,
            'equipment': _equipment,
            'tank': _tankCtrl.text,
          },
        );
    _snack('Calculation saved!',
        color: _calcColor);
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalcHeader(
            emoji: '🧪',
            title: 'Spray Calculator',
            subtitle:
                'Water volume, product quantity, and tank loads',
            color: _calcColor,
          ),
          const SizedBox(height: 16),

          // Product name
          _Field(
            ctrl: _productCtrl,
            label: 'Product name *',
            hint: 'e.g. Mancozeb 80WP',
            isText: true,
          ),
          const SizedBox(height: 12),

          // Dose + unit
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(
                  ctrl: _doseCtrl,
                  label: 'Dose rate *',
                  hint: 'e.g. 250',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _Lbl('Unit'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _doseUnit,
                      decoration: _dropDec(),
                      items: InputCalculatorService
                          .productUnits
                          .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u,
                                  style: AppTextStyles
                                      .bodySmall)))
                          .toList(),
                      onChanged: (v) => setState(
                          () => _doseUnit = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Equipment
          _Lbl('Spray equipment'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _equipment,
            isExpanded: true,
            decoration: _dropDec(),
            items: InputCalculatorService
                .equipmentTypes
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: AppTextStyles.bodySmall,
                        overflow:
                            TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) =>
                setState(() => _equipment = v!),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _Field(
                  ctrl: _areaCtrl,
                  label: 'Area (ha) *',
                  hint: '1.0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  ctrl: _tankCtrl,
                  label: 'Tank capacity (L) *',
                  hint: '16',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _CalcButton(
            label: 'Calculate Spray Program',
            onTap: _calculate,
            color: _calcColor,
          ),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _SprayResult(result: _result!, onSave: _save),
          ],
        ],
      ),
    );
  }
}

// Spray Result Card
class _SprayResult extends StatelessWidget {
  final SprayCalcResult result;
  final VoidCallback onSave;
  const _SprayResult(
      {required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isPowder = result.unit == 'g/L';
    final totalProduct = isPowder
        ? '${result.productAmountG.toStringAsFixed(0)} g'
        : '${result.productAmountMl.toStringAsFixed(0)} ml';
    final perTank = isPowder
        ? '${result.productPerTank.toStringAsFixed(1)} g'
        : '${result.productPerTank.toStringAsFixed(1)} ml';
    final concentration =
        '${result.concentrationPct.toStringAsFixed(2)} ${result.unit}';

    return Container(
      decoration: BoxDecoration(
        color: _calcColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _calcColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _calcColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🧪',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.productName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _calcColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                      Icons.bookmark_add_outlined,
                      color: _calcColor),
                  tooltip: 'Save calculation',
                  onPressed: onSave,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Key stats
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Stat(
                        label: 'Total water',
                        value:
                            '${result.waterVolumeLitres.toStringAsFixed(0)} L',
                        highlight: true),
                    _Stat(
                        label: 'Total product',
                        value: totalProduct,
                        highlight: true),
                    _Stat(
                        label: 'Concentration',
                        value: concentration),
                    _Stat(
                        label: 'Tank loads',
                        value:
                            '${result.tanksNeeded} × ${result.tankCapacityL.toStringAsFixed(0)} L'),
                    _Stat(
                        label: 'Per tank',
                        value: perTank,
                        highlight: true),
                  ],
                ),
                const SizedBox(height: 14),

                // Mixing steps
                _SubHeader('📋 Mixing Steps'),
                const SizedBox(height: 6),
                ...result.mixingSteps
                    .asMap()
                    .entries
                    .map((e) => _Step(
                        number: e.key + 1,
                        text: e.value)),

                const SizedBox(height: 12),

                // Safety
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ Safety',
                          style: AppTextStyles.caption
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.warning)),
                      const SizedBox(height: 6),
                      ...result.safetyNotes.map(
                        (n) => Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 3),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors
                                          .warning)),
                              Expanded(
                                  child: Text(n,
                                      style: AppTextStyles
                                          .caption)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
// TAB 2 — SEED CALCULATOR
// =============================================================================

class _SeedTab extends StatefulWidget {
  const _SeedTab();

  @override
  State<_SeedTab> createState() => _SeedTabState();
}

class _SeedTabState extends State<_SeedTab> {
  String _crop = 'Maize';
  final _areaCtrl =
      TextEditingController(text: '1.0');
  final _customRateCtrl = TextEditingController();
  final _customRowCtrl = TextEditingController();
  final _customPlantCtrl = TextEditingController();
  bool _useCustom = false;
  SeedCalcResult? _result;

  @override
  void dispose() {
    _areaCtrl.dispose();
    _customRateCtrl.dispose();
    _customRowCtrl.dispose();
    _customPlantCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
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
    setState(() {
      _result = InputCalculatorService.calculateSeed(
        crop: _crop,
        areaHa: area,
        customRateKgHa: _useCustom
            ? double.tryParse(_customRateCtrl.text)
            : null,
        customRowSpacingCm: _useCustom
            ? double.tryParse(_customRowCtrl.text)
            : null,
        customPlantSpacingCm: _useCustom
            ? double.tryParse(_customPlantCtrl.text)
            : null,
      );
    });
  }

  void _save() {
    if (_result == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    context.read<InputCalculatorProvider>().saveCalculation(
          userId: user.userId,
          type: 'seed',
          title:
              '${_result!.crop} seed — ${_result!.areaHa.toStringAsFixed(2)} ha',
          summary:
              '${_result!.totalSeedKg < 1 ? _result!.totalSeedG.toStringAsFixed(0) + ' g' : _result!.totalSeedKg.toStringAsFixed(1) + ' kg'} seed · '
              '${(_result!.totalPlants / 1000).toStringAsFixed(0)}k plants',
          inputs: {'crop': _crop, 'area': _areaCtrl.text},
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved!'),
        backgroundColor: _calcColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = InputCalculatorService
        .cropSeedData[_crop];
    final defaultRate = data != null
        ? (data['rate_kg_ha'] as num).toDouble()
        : 0.0;
    final defaultRow = data != null
        ? (data['row_spacing_cm'] as num).toDouble()
        : 0.0;
    final defaultPlant = data != null
        ? (data['plant_spacing_cm'] as num).toDouble()
        : 0.0;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalcHeader(
            emoji: '🌱',
            title: 'Seed Calculator',
            subtitle:
                'Quantity needed, plant population, and packaging',
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 16),

          _Lbl('Crop'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _crop,
            isExpanded: true,
            decoration: _dropDec(),
            items: InputCalculatorService.cropNames
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: AppTextStyles.body)))
                .toList(),
            onChanged: (v) => setState(() {
              _crop = v!;
              _customRateCtrl.clear();
              _customRowCtrl.clear();
              _customPlantCtrl.clear();
            }),
          ),
          const SizedBox(height: 12),

          _Field(
              ctrl: _areaCtrl,
              label: 'Area to plant (ha) *',
              hint: '1.0'),
          const SizedBox(height: 12),

          // Default rate info chip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight
                  .withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primaryLight
                      .withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('📋',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Default for $_crop: '
                    '${defaultRate < 1 ? '${(defaultRate * 1000).toStringAsFixed(0)} g/ha' : '${defaultRate.toStringAsFixed(0)} kg/ha'} · '
                    '${defaultRow.toStringAsFixed(0)} cm × ${defaultPlant.toStringAsFixed(0)} cm',
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors
                                .primaryLight,
                            fontWeight:
                                FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Custom toggle
          Row(
            children: [
              Switch(
                value: _useCustom,
                activeColor: _calcColor,
                onChanged: (v) =>
                    setState(() => _useCustom = v),
              ),
              Text('Use custom seeding rates',
                  style: AppTextStyles.body),
            ],
          ),

          if (_useCustom) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _customRateCtrl,
                    label: 'Seed rate (kg/ha)',
                    hint:
                        '${defaultRate.toStringAsFixed(1)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    ctrl: _customRowCtrl,
                    label: 'Row spacing (cm)',
                    hint:
                        '${defaultRow.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    ctrl: _customPlantCtrl,
                    label: 'Plant spacing (cm)',
                    hint:
                        '${defaultPlant.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _CalcButton(
            label: 'Calculate Seed Requirement',
            onTap: _calculate,
            color: AppColors.primaryLight,
          ),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _SeedResult(
                result: _result!, onSave: _save),
          ],
        ],
      ),
    );
  }
}

class _SeedResult extends StatelessWidget {
  final SeedCalcResult result;
  final VoidCallback onSave;
  const _SeedResult(
      {required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final seedDisplay = result.totalSeedKg < 1
        ? '${result.totalSeedG.toStringAsFixed(0)} g'
        : '${result.totalSeedKg.toStringAsFixed(2)} kg';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                AppColors.primaryLight.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  AppColors.primaryLight.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🌱',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${result.crop} — ${result.areaHa.toStringAsFixed(2)} ha',
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                      Icons.bookmark_add_outlined,
                      color: AppColors.primaryLight),
                  onPressed: onSave,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Stat(
                        label: 'Seed needed',
                        value: seedDisplay,
                        highlight: true),
                    _Stat(
                        label: 'Rate',
                        value:
                            '${result.seedingRateKgHa < 1 ? (result.seedingRateKgHa * 1000).toStringAsFixed(0) + " g" : result.seedingRateKgHa.toStringAsFixed(0) + " kg"}/ha'),
                    _Stat(
                        label: 'Row spacing',
                        value:
                            '${result.rowSpacingCm.toStringAsFixed(0)} cm'),
                    _Stat(
                        label: 'Plant spacing',
                        value:
                            '${result.plantSpacingCm.toStringAsFixed(0)} cm'),
                    _Stat(
                        label: 'Plants/ha',
                        value:
                            '${result.plantsPerHa.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}'),
                    _Stat(
                        label: 'Total plants',
                        value:
                            '${result.totalPlants.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}',
                        highlight: true),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success
                            .withOpacity(0.3)),
                  ),
                  child: Text(
                    '📦 ${result.packagingAdvice}',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                _SubHeader('📝 Planting Notes'),
                const SizedBox(height: 6),
                ...result.notes.map(
                  (n) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                color: AppColors
                                    .primaryLight)),
                        Expanded(
                            child: Text(n,
                                style: AppTextStyles
                                    .bodySmall
                                    .copyWith(
                                        height: 1.5))),
                      ],
                    ),
                  ),
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
// TAB 3 — TANK MIX CALCULATOR
// =============================================================================

class _TankMixTab extends StatefulWidget {
  const _TankMixTab();

  @override
  State<_TankMixTab> createState() =>
      _TankMixTabState();
}

class _TankMixTabState extends State<_TankMixTab> {
  final _tankCtrl =
      TextEditingController(text: '200');
  List<TankMixProduct> _selected = [];
  TankMixResult? _result;

  @override
  void dispose() {
    _tankCtrl.dispose();
    super.dispose();
  }

  void _toggleProduct(TankMixProduct p) {
    setState(() {
      if (_selected.any((s) => s.name == p.name)) {
        _selected.removeWhere(
            (s) => s.name == p.name);
        _result = null;
      } else {
        if (_selected.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Max 5 products per tank mix.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _selected.add(p);
        _result = null;
      }
    });
  }

  void _calculate() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Select at least one product.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final tank = double.tryParse(_tankCtrl.text);
    if (tank == null || tank <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid tank size.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _result =
          InputCalculatorService.calculateTankMix(
        tankSizeL: tank,
        products: _selected,
      );
    });
  }

  void _save() {
    if (_result == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final names =
        _selected.map((p) => p.name).join(' + ');
    context.read<InputCalculatorProvider>().saveCalculation(
          userId: user.userId,
          type: 'mix',
          title: 'Tank mix — ${_tankCtrl.text} L',
          summary: names,
          inputs: {'tank': _tankCtrl.text, 'products': names},
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved!'),
        backgroundColor: _calcColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group products by type
    final grouped = <String, List<TankMixProduct>>{};
    for (final p
        in InputCalculatorService.commonProducts) {
      grouped.putIfAbsent(p.type, () => []).add(p);
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalcHeader(
            emoji: '🪣',
            title: 'Tank Mix Calculator',
            subtitle:
                'Quantities per tank + compatibility check',
            color: const Color(0xFF00838F),
          ),
          const SizedBox(height: 14),

          // Tank size
          _Field(
              ctrl: _tankCtrl,
              label: 'Tank size (litres) *',
              hint: '200'),
          const SizedBox(height: 12),

          // Selected chips
          if (_selected.isNotEmpty) ...[
            Text(
              '✅ Selected (${_selected.length}):',
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selected
                  .map((p) => Chip(
                        label: Text(
                            '${p.typeEmoji} ${p.name}',
                            style: const TextStyle(
                                fontSize: 12)),
                        onDeleted: () =>
                            _toggleProduct(p),
                        backgroundColor:
                            _calcColor.withOpacity(0.1),
                        deleteIconColor: _calcColor,
                        side: const BorderSide(
                            color: _calcColor),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Product library by type
          ...grouped.entries.map((entry) {
            final typeLabel =
                entry.key[0].toUpperCase() +
                    entry.key.substring(1) +
                    's';
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(
                          bottom: 6),
                  child: Text(
                    '${entry.value.first.typeEmoji} $typeLabel',
                    style: AppTextStyles.label
                        .copyWith(
                            fontWeight:
                                FontWeight.w700,
                            color: AppColors
                                .textSecondary),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: entry.value.map((p) {
                    final isSelected = _selected
                        .any((s) => s.name == p.name);
                    return GestureDetector(
                      onTap: () => _toggleProduct(p),
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 150),
                        padding: const EdgeInsets
                            .symmetric(
                            horizontal: 10,
                            vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _calcColor
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? _calcColor
                                  : AppColors.divider),
                        ),
                        child: Text(
                          p.name,
                          style: AppTextStyles.caption
                              .copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          _CalcButton(
            label: 'Calculate Tank Mix',
            onTap: _calculate,
            color: const Color(0xFF00838F),
          ),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _MixResult(
                result: _result!, onSave: _save),
          ],
        ],
      ),
    );
  }
}

class _MixResult extends StatelessWidget {
  final TankMixResult result;
  final VoidCallback onSave;
  const _MixResult(
      {required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00838F);

    return Container(
      decoration: BoxDecoration(
        color: teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: teal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🪣',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${result.tankSizeL.toStringAsFixed(0)} L Tank Mix',
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: teal),
                  ),
                ),
                // Compatibility badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isCompatible
                        ? AppColors.success
                        : AppColors.error,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.isCompatible
                        ? '✅ Compatible'
                        : '⚠️ Warnings',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: Icon(
                      Icons.bookmark_add_outlined,
                      color: teal),
                  onPressed: onSave,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Compatibility warnings
                if (result.compatibilityWarnings
                    .isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error
                              .withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compatibility Warnings',
                          style: AppTextStyles.caption
                              .copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...result
                            .compatibilityWarnings
                            .map(
                              (w) => Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                        bottom: 4),
                                child: Text(w,
                                    style: AppTextStyles
                                        .caption),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Quantities per product
                _SubHeader(
                    '⚗️ Quantities for ${result.tankSizeL.toStringAsFixed(0)} L'),
                const SizedBox(height: 8),
                ...result.quantities.map(
                  (q) => Container(
                    margin: const EdgeInsets.only(
                        bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(q.name,
                              style: AppTextStyles.body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w600)),
                        ),
                        Text(
                          '${q.amount.toStringAsFixed(1)} ${q.unit}',
                          style: AppTextStyles.body
                              .copyWith(
                            color: teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Mixing order
                _SubHeader('📋 Mixing Order (WISSA)'),
                const SizedBox(height: 6),
                ...result.mixingOrder.map(
                  (step) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 5),
                    child: Text(step,
                        style: AppTextStyles.bodySmall
                            .copyWith(height: 1.5)),
                  ),
                ),

                const SizedBox(height: 10),

                // Safety
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ Safety Reminders',
                          style: AppTextStyles.caption
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.warning)),
                      const SizedBox(height: 6),
                      ...result.safetyNotes.map(
                        (n) => Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 3),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors
                                          .warning)),
                              Expanded(
                                  child: Text(n,
                                      style: AppTextStyles
                                          .caption)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
// TAB 4 — SAVED CALCULATIONS
// =============================================================================

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<InputCalculatorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: _calcColor));
        }

        if (provider.saved.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text('📋',
                      style:
                          TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('No saved calculations',
                      style: AppTextStyles.heading3
                          .copyWith(
                              color: AppColors
                                  .textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon after\n'
                    'any calculation to save it.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 80),
          itemCount: provider.saved.length,
          itemBuilder: (_, i) {
            final calc = provider.saved[i];
            return Dismissible(
              key: Key(calc.id),
              direction:
                  DismissDirection.endToStart,
              background: Container(
                margin:
                    const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(
                    right: 20),
                child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white),
              ),
              onDismissed: (_) =>
                  provider
                      .deleteCalculation(calc.id),
              child: Container(
                margin:
                    const EdgeInsets.only(bottom: 8),
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _calcColor
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(
                              calc.typeEmoji,
                              style: const TextStyle(
                                  fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(calc.title,
                              style: AppTextStyles
                                  .body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w700)),
                          Text(calc.summary,
                              style: AppTextStyles
                                  .caption
                                  .copyWith(
                                      color: AppColors
                                          .textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _daysAgo(calc.savedAt),
                      style: AppTextStyles.caption
                          .copyWith(
                              color:
                                  AppColors.textHint),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _daysAgo(DateTime d) {
    final diff =
        DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _CalcHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _CalcHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _CalcButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool isText;
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lbl(label),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isText
              ? TextInputType.text
              : const TextInputType.numberWithOptions(
                  decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
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

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text,
          style: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w600));
}

InputDecoration _dropDec() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.divider),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
    );

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Stat({
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
              color: highlight
                  ? _calcColor
                  : AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text,
          style: AppTextStyles.body
              .copyWith(fontWeight: FontWeight.w700));
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step(
      {required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(
                top: 1, right: 8),
            decoration: const BoxDecoration(
              color: _calcColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(height: 1.5))),
        ],
      ),
    );
  }
}