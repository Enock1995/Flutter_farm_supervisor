// lib/screens/horticulture/add_plot_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/horticulture_provider.dart';
import '../../services/advisory/horticulture_advisory_service.dart';
import '../../widgets/primary_button.dart';

class AddPlotScreen extends StatefulWidget {
  const AddPlotScreen({super.key});

  @override
  State<AddPlotScreen> createState() =>
      _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  String? _selectedCrop;
  final _sizeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _plantingDate;
  String _irrigationMethod = 'Drip';
  String _targetMarket = 'Local market / Roadside';

  static const List<String> _irrigationMethods = [
    'Drip', 'Sprinkler', 'Flood / Furrow',
    'Watering Can', 'Rain-fed Only',
  ];

  static const List<String> _markets = [
    'Local market / Roadside',
    'Mbare Musika',
    'Supermarkets (OK, TM, Pick n Pay)',
    'Hotels & Restaurants',
    'Direct to households',
    'Export',
    'Processing / Factory',
  ];

  Map<String, List<Map<String, String>>>
      get _groupedCrops {
    final grouped = <String, List<Map<String, String>>>{};
    for (final c
        in HorticultureAdvisoryService.hortiCrops) {
      final cat = c['category']!;
      grouped.putIfAbsent(cat, () => []);
      // avoid duplicates
      if (!grouped[cat]!.any(
          (existing) => existing['name'] == c['name'])) {
        grouped[cat]!.add(c);
      }
    }
    return grouped;
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate:
          DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.primaryLight)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedCrop == null) {
      _showError('Please select a crop.');
      return;
    }
    final size =
        double.tryParse(_sizeController.text.trim());
    if (size == null || size <= 0) {
      _showError('Please enter a valid plot size.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final harvest = _plantingDate != null
        ? HorticultureAdvisoryService.getEstimatedHarvest(
            _selectedCrop!, _plantingDate!)
        : null;

    await context.read<HorticultureProvider>().addPlot(
          userId: user.userId,
          cropName: _selectedCrop!,
          plotSizeM2: size,
          plantingDate: _plantingDate,
          expectedHarvestDate: harvest,
          irrigationMethod: _irrigationMethod,
          targetMarket: _targetMarket,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedCrop plot added!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Market timing for selected crop
    MarketTimingInfo? marketInfo;
    if (_selectedCrop != null) {
      final harvest = _plantingDate != null
          ? HorticultureAdvisoryService.getEstimatedHarvest(
              _selectedCrop!, _plantingDate!)
          : null;
      marketInfo =
          HorticultureAdvisoryService.getMarketTiming(
              _selectedCrop!, harvest);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Plot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Crop',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Grouped crop selector
            ..._groupedCrops.entries.map((entry) =>
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 10, bottom: 6),
                      child: Text(
                        entry.key,
                        style: AppTextStyles.label
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((crop) {
                        final selected =
                            _selectedCrop == crop['name'];
                        return GestureDetector(
                          onTap: () => setState(() =>
                              _selectedCrop = crop['name']),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 180),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                              border: Border.all(
                                color: selected
                                    ? AppColors
                                        .primaryLight
                                    : AppColors.divider,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Text(crop['icon']!,
                                    style: const TextStyle(
                                        fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  crop['name']!,
                                  style: AppTextStyles
                                      .body
                                      .copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors
                                            .textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )),

            // Market timing card
            if (marketInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: marketInfo.isPeakMonth
                      ? AppColors.success.withOpacity(0.08)
                      : AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: marketInfo.isPeakMonth
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(marketInfo.advice,
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                fontWeight:
                                    FontWeight.w600)),
                    if (marketInfo.profitability !=
                        null) ...[
                      const SizedBox(height: 4),
                      Text(
                          '💰 ${marketInfo.profitability}',
                          style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text('Plot Details',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Plot size
            TextFormField(
              controller: _sizeController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Plot Size *',
                hintText: 'e.g. 500',
                suffixText: 'm²',
                helperText:
                    '100m² = 10x10m. 1000m² = 0.1ha.',
                prefixIcon: const Icon(Icons.straighten,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // Planting date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _plantingDate != null
                          ? AppColors.primaryLight
                          : AppColors.divider,
                      width:
                          _plantingDate != null ? 2 : 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primaryLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Planting Date',
                              style:
                                  AppTextStyles.label),
                          Text(
                            _plantingDate != null
                                ? _fmtDate(
                                    _plantingDate!)
                                : 'Tap to select (optional)',
                            style: AppTextStyles.body
                                .copyWith(
                              color: _plantingDate !=
                                      null
                                  ? AppColors
                                      .textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            // Estimated harvest
            if (_selectedCrop != null &&
                _plantingDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent
                          .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: AppColors.accent,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Est. harvest: ${_fmtDate(HorticultureAdvisoryService.getEstimatedHarvest(_selectedCrop!, _plantingDate!) ?? _plantingDate!)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                              fontWeight:
                                  FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Irrigation method
            Text('Irrigation Method',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _irrigationMethods.map((method) {
                final selected =
                    _irrigationMethod == method;
                return GestureDetector(
                  onTap: () => setState(
                      () => _irrigationMethod = method),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.info
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.info
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(method,
                        style: AppTextStyles.body
                            .copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Target market
            Text('Target Market',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetMarket,
                  isExpanded: true,
                  items: _markets
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style:
                                  AppTextStyles.body)))
                      .toList(),
                  onChanged: (val) => setState(
                      () => _targetMarket = val!),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'e.g. Irrigated plot, near borehole, 300m from road',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            Consumer<HorticultureProvider>(
              builder: (ctx, provider, _) =>
                  PrimaryButton(
                label: 'Add ${_selectedCrop ?? 'Plot'}',
                icon: Icons.add_circle_outline,
                isLoading: provider.isLoading,
                onPressed:
                    _selectedCrop != null ? _save : null,
                color: AppColors.primaryLight,
              ),
            ),
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