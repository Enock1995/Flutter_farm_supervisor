// lib/screens/ai/ai_yield_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import 'ai_shared_widgets.dart';

class AiYieldScreen extends StatefulWidget {
  const AiYieldScreen({super.key});

  @override
  State<AiYieldScreen> createState() => _AiYieldScreenState();
}

class _AiYieldScreenState extends State<AiYieldScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _cropCtrl = TextEditingController();
  final _fieldSizeCtrl = TextEditingController();
  final _rainfallCtrl = TextEditingController();
  final _fertilizerCtrl = TextEditingController();

  String _soilType = 'Sandy loam';

  static const _soilTypes = [
    'Sandy loam',
    'Clay',
    'Loam',
    'Sandy',
    'Clay loam',
    'Silt loam',
  ];

  static const _crops = [
    'Maize',
    'Tobacco',
    'Cotton',
    'Soybean',
    'Sorghum',
    'Groundnuts',
    'Sunflower',
    'Wheat',
    'Barley',
    'Tomato',
    'Cabbage',
    'Onion',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.userId ?? '';
      context.read<AiProvider>().loadYieldHistory(userId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _cropCtrl.dispose();
    _fieldSizeCtrl.dispose();
    _rainfallCtrl.dispose();
    _fertilizerCtrl.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (_cropCtrl.text.trim().isEmpty || _fieldSizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in crop type and field size.')),
      );
      return;
    }
    final fieldSize = double.tryParse(_fieldSizeCtrl.text.trim()) ?? 0;
    if (fieldSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid field size in hectares.')),
      );
      return;
    }
    final user = context.read<AuthProvider>().user;
    await context.read<AiProvider>().predictYield(
          userId: user?.userId ?? '',
          cropType: _cropCtrl.text.trim(),
          fieldSizeHa: fieldSize,
          soilType: _soilType,
          rainfallMm: double.tryParse(_rainfallCtrl.text.trim()) ?? 0,
          fertilizerUsed: _fertilizerCtrl.text.trim().isNotEmpty
              ? _fertilizerCtrl.text.trim()
              : 'None',
          agroRegion: user?.agroRegion ?? 'II',
        );
    if (context.read<AiProvider>().state == AiState.success) {
      context.read<AiProvider>().loadYieldHistory(user?.userId ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Yield Prediction'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Predict'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PredictTab(
            cropCtrl: _cropCtrl,
            fieldSizeCtrl: _fieldSizeCtrl,
            rainfallCtrl: _rainfallCtrl,
            fertilizerCtrl: _fertilizerCtrl,
            soilType: _soilType,
            soilTypes: _soilTypes,
            crops: _crops,
            onSoilChanged: (v) => setState(() => _soilType = v!),
            onPredict: _predict,
          ),
          _YieldHistoryTab(tabs: _tabs),
        ],
      ),
    );
  }
}

// ── Predict tab ───────────────────────────────────────────
class _PredictTab extends StatelessWidget {
  final TextEditingController cropCtrl;
  final TextEditingController fieldSizeCtrl;
  final TextEditingController rainfallCtrl;
  final TextEditingController fertilizerCtrl;
  final String soilType;
  final List<String> soilTypes;
  final List<String> crops;
  final ValueChanged<String?> onSoilChanged;
  final VoidCallback onPredict;

  const _PredictTab({
    required this.cropCtrl,
    required this.fieldSizeCtrl,
    required this.rainfallCtrl,
    required this.fertilizerCtrl,
    required this.soilType,
    required this.soilTypes,
    required this.crops,
    required this.onSoilChanged,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        final isLoading = ai.state == AiState.loading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiHeaderCard(
                icon: Icons.trending_up,
                color: const Color(0xFF7B2D8B),
                title: 'AI Yield Prediction',
                subtitle:
                    'Enter your field data and get an AI-powered yield forecast.',
              ),
              const SizedBox(height: 20),

              Text('Field Information', style: AppTextStyles.heading3),
              const SizedBox(height: 12),

              // Crop type with autocomplete
              Autocomplete<String>(
                optionsBuilder: (v) => crops
                    .where((c) =>
                        c.toLowerCase().contains(v.text.toLowerCase()))
                    .toList(),
                onSelected: (v) => cropCtrl.text = v,
                fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                  return TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Crop Type *',
                      prefixIcon:
                          Icon(Icons.eco_outlined, color: AppColors.primary),
                    ),
                    onChanged: (v) => cropCtrl.text = v,
                  );
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fieldSizeCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Field Size (ha) *',
                        prefixIcon: Icon(Icons.straighten,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: rainfallCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rainfall (mm)',
                        prefixIcon: Icon(Icons.water_drop_outlined,
                            color: AppColors.info),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: soilType,
                decoration: const InputDecoration(
                  labelText: 'Soil Type',
                  prefixIcon:
                      Icon(Icons.layers_outlined, color: AppColors.earth),
                ),
                items: soilTypes
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onSoilChanged,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: fertilizerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fertilizer Used',
                  hintText: 'e.g. AN 200kg/ha + Compound D 150kg/ha',
                  prefixIcon: Icon(Icons.science_outlined,
                      color: AppColors.success),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onPredict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2D8B),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_graph, color: Colors.white),
                  label: Text(
                    isLoading ? 'Predicting...' : 'Predict Yield',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (ai.state == AiState.error)
                AiErrorCard(message: ai.errorMessage),

              if (ai.state == AiState.success && ai.yieldResult != null) ...[
                const Divider(height: 32),
                _YieldResultCard(result: ai.yieldResult!),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Yield result card ─────────────────────────────────────
class _YieldResultCard extends StatelessWidget {
  final dynamic result;
  const _YieldResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isAbove = (result.comparison as String).contains('above');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yield Prediction', style: AppTextStyles.heading3),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2D8B), Color(0xFF9C3FB3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBlock(
                    label: 'Predicted Yield',
                    value:
                        '${result.predictedYieldPerHa.toStringAsFixed(1)} t/ha',
                    white: true,
                  ),
                  Container(height: 50, width: 1, color: Colors.white24),
                  _StatBlock(
                    label: 'Total Harvest',
                    value:
                        '${result.totalPredictedTonnes.toStringAsFixed(1)} t',
                    white: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${result.comparisonPercent}% ${result.comparison} Zimbabwe average (${result.zimAveragePerHa} t/ha)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expected harvest: ${result.harvestWindow}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if ((result.limitingFactors as List).isNotEmpty)
          AiListCard(
            icon: Icons.warning_amber_outlined,
            title: 'Limiting Factors',
            color: AppColors.warning,
            items: List<String>.from(result.limitingFactors),
          ),
        const SizedBox(height: 12),

        if ((result.recommendations as List).isNotEmpty)
          AiListCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Recommendations',
            color: AppColors.success,
            items: List<String>.from(result.recommendations),
          ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool white;
  const _StatBlock(
      {required this.label, required this.value, this.white = false});

  @override
  Widget build(BuildContext context) {
    final textColor = white ? Colors.white : AppColors.textPrimary;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
                fontFamily: 'Poppins')),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: white ? Colors.white70 : AppColors.textSecondary,
                fontFamily: 'Poppins')),
      ],
    );
  }
}

// ── History tab ───────────────────────────────────────────
class _YieldHistoryTab extends StatelessWidget {
  final TabController tabs;
  const _YieldHistoryTab({required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        final history = ai.yieldHistory;
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No predictions yet.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => tabs.animateTo(0),
                  child: const Text('Make your first prediction'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, i) {
            final h = history[i];
            final date = DateTime.parse(h['created_at'] as String);
            final perHa =
                (h['predicted_yield_per_ha'] as num).toDouble();
            final total =
                (h['total_predicted_tonnes'] as num).toDouble();
            final comparison = h['comparison'] as String? ?? '';
            final isAbove = comparison.contains('above');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2D8B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.trending_up,
                            color: isAbove
                                ? AppColors.success
                                : AppColors.error),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['crop_type'] as String? ?? '',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${h['field_size_ha']} ha  •  ${perHa.toStringAsFixed(1)} t/ha  •  ${total.toStringAsFixed(1)} t total',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    AiBadge(
                      label: '${h['comparison_percent']}%',
                      color: isAbove ? AppColors.success : AppColors.error,
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
}