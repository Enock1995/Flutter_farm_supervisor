// lib/screens/weather/weather_screen.dart
// Developed by Sir Enocks — Cor Technologies
// Basic: Current, Forecast, Farm Advisory
// Premium: Threshold Alerts, AI Advisory

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/weather_service.dart';
import '../../services/ai_service.dart';
import '../../services/subscription_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 5 tabs: 3 basic + 2 premium
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final provider = context.read<WeatherProvider>();
      provider.init(userDistrict: user?.district ?? '');
      provider.loadSavedThresholds();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.user?.hasPremiumAccess ?? false;

    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor:
                    _skyColor(provider.current?.condition ?? ''),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.location_city, color: Colors.white),
                    tooltip: 'Change city',
                    onPressed: () => _showCityPicker(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.loadWeather(forceRefresh: true),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _WeatherHero(provider: provider),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'Current'),
                    const Tab(text: '5-Day'),
                    const Tab(text: 'Advisory'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Alerts'),
                          if (!isPremium) ...[
                            const SizedBox(width: 4),
                            const Text('👑',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('AI Plan'),
                          if (!isPremium) ...[
                            const SizedBox(width: 4),
                            const Text('👑',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            body: provider.isLoading && !provider.hasData
                ? _LoadingView()
                : !provider.hasData
                    ? _ErrorView(
                        error: provider.error,
                        onRetry: () =>
                            provider.loadWeather(forceRefresh: true),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _CurrentTab(provider: provider),
                          _ForecastTab(forecast: provider.forecast),
                          _AdvisoryTab(advisories: provider.advisories),
                          // ── Premium tabs ──────────────────
                          isPremium
                              ? _AlertsTab(provider: provider)
                              : const _PremiumLockTab(
                                  feature: 'Threshold Alerts',
                                  description:
                                      'Set custom thresholds for temperature, wind, humidity and rain. '
                                      'Get instant alerts when conditions affect your crops.',
                                ),
                          isPremium
                              ? _AiAdvisoryTab(provider: provider)
                              : const _PremiumLockTab(
                                  feature: 'AI Farm Plan',
                                  description:
                                      'Claude AI analyses your weather data and generates a '
                                      'personalised 7-day farming action plan with spray windows, '
                                      'disease risk and daily priorities.',
                                ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  void _showCityPicker(BuildContext context, WeatherProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CityPickerSheet(
        currentCity: provider.city,
        onSelected: (city) {
          Navigator.pop(context);
          provider.changeCity(city);
        },
      ),
    );
  }

  Color _skyColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return const Color(0xFF1565C0);
      case 'clouds':       return const Color(0xFF546E7A);
      case 'rain':
      case 'drizzle':      return const Color(0xFF37474F);
      case 'thunderstorm': return const Color(0xFF263238);
      case 'snow':         return const Color(0xFF78909C);
      default:             return AppColors.primaryDark;
    }
  }
}

// =============================================================================
// PREMIUM LOCK TAB
// =============================================================================
class _PremiumLockTab extends StatelessWidget {
  final String feature;
  final String description;
  const _PremiumLockTab(
      {required this.feature, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2D8B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Text('👑',
                  style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text('$feature — Premium',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(description,
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2D8B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Upgrade to Premium',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 4 — THRESHOLD ALERTS (Premium)
// =============================================================================
class _AlertsTab extends StatefulWidget {
  final WeatherProvider provider;
  const _AlertsTab({required this.provider});

  @override
  State<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<_AlertsTab> {
  bool _editMode = false;
  late AlertThreshold _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.provider.thresholds;
  }

  void _save() {
    widget.provider.updateThresholds(_draft);
    setState(() => _editMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert thresholds saved ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = widget.provider.thresholdAlerts;
    final goodSprayDays = widget.provider.goodSprayDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active alerts
          Row(
            children: [
              Text('Active Alerts', style: AppTextStyles.heading3),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _editMode = !_editMode),
                icon: Icon(_editMode ? Icons.close : Icons.tune,
                    size: 16),
                label: Text(_editMode ? 'Cancel' : 'Set Thresholds'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('✅',
                      style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('All Clear',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                        Text(
                          'No weather thresholds exceeded. Conditions are within your safe ranges.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.map((a) => _AlertCard(alert: a)),

          const SizedBox(height: 20),

          // Good spray days
          if (goodSprayDays.isNotEmpty) ...[
            Text('🚿 Good Spray Days', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: goodSprayDays
                        .map((day) => Chip(
                              label: Text(day),
                              backgroundColor:
                                  AppColors.info.withOpacity(0.12),
                              labelStyle: TextStyle(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Low wind, dry conditions and cool temperatures — '
                    'ideal for pesticide/fungicide application.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Threshold editor
          if (_editMode) ...[
            Text('Set Alert Thresholds',
                style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'You will be alerted when current weather exceeds these values.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _ThresholdSlider(
              label: '🌡️ Max Temperature',
              value: _draft.maxTempC,
              min: 25,
              max: 45,
              unit: '°C',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(maxTempC: v)),
            ),
            _ThresholdSlider(
              label: '❄️ Min Temperature',
              value: _draft.minTempC,
              min: 0,
              max: 15,
              unit: '°C',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(minTempC: v)),
            ),
            _ThresholdSlider(
              label: '💨 Max Wind Speed',
              value: _draft.maxWindKmh,
              min: 15,
              max: 80,
              unit: ' km/h',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(maxWindKmh: v)),
            ),
            _ThresholdSlider(
              label: '🏜️ Min Humidity',
              value: _draft.minHumidity,
              min: 10,
              max: 40,
              unit: '%',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(minHumidity: v)),
            ),
            _ThresholdSlider(
              label: '🍄 Max Humidity',
              value: _draft.maxHumidity,
              min: 70,
              max: 98,
              unit: '%',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(maxHumidity: v)),
            ),
            _ThresholdSlider(
              label: '🌧️ Rain Alert (per hour)',
              value: _draft.rainAlertMm,
              min: 2,
              max: 30,
              unit: ' mm',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(rainAlertMm: v)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Thresholds',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final ThresholdAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDanger = alert.level == 'danger';
    final color = isDanger ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDanger ? '🔴 DANGER' : '⚠️ WARNING',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${value.round()}$unit',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min)).toInt(),
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 5 — AI ADVISORY (Premium)
// =============================================================================
class _AiAdvisoryTab extends StatelessWidget {
  final WeatherProvider provider;
  const _AiAdvisoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final advisory = provider.aiAdvisory;

    if (provider.aiLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF7B2D8B)),
            const SizedBox(height: 20),
            Text('Claude AI is analysing your weather data...',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('This takes 10–20 seconds',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint)),
          ],
        ),
      );
    }

    if (advisory == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('AI Farm Advisory',
                  style: AppTextStyles.heading2),
              const SizedBox(height: 10),
              Text(
                'Claude AI will analyse your current weather and 5-day forecast '
                'to generate a personalised farming action plan — spray windows, '
                'disease risk, irrigation advice and daily priorities.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (provider.aiError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(provider.aiError!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => provider.loadAiAdvisory(
                    district: auth.user?.district ?? 'Harare',
                    agroRegion: auth.user?.agroRegion ?? '2',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2D8B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI Farm Plan',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show advisory results
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall risk banner
          _RiskBanner(risk: advisory.overallRisk, summary: advisory.summary),
          const SizedBox(height: 16),

          // AI alerts
          if (advisory.alerts.isNotEmpty) ...[
            Text('⚠️ AI Weather Alerts', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...advisory.alerts.map((a) => _AiAlertCard(alert: a)),
            const SizedBox(height: 16),
          ],

          // Quick advice row
          Text('Today\'s Quick Advice', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _QuickAdviceGrid(advisory: advisory),
          const SizedBox(height: 16),

          // Spray windows
          if (advisory.sprayDays.isNotEmpty) ...[
            Text('🚿 Best Spray Days', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: advisory.sprayDays
                  .map((d) => Chip(
                        label: Text(d),
                        backgroundColor:
                            AppColors.info.withOpacity(0.12),
                        labelStyle: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Disease pressure
          _DiseasePressureCard(advisory: advisory),
          const SizedBox(height: 16),

          // 7-day plan
          if (advisory.thisWeekPlan.isNotEmpty) ...[
            Text('📅 7-Day Action Plan', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            ...advisory.thisWeekPlan.map((p) => _DayPlanCard(plan: p)),
            const SizedBox(height: 16),
          ],

          // Refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => provider.loadAiAdvisory(
                  district: context.read<AuthProvider>().user?.district ?? 'Harare',
                  agroRegion:
                      context.read<AuthProvider>().user?.agroRegion ?? '2',
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate Plan'),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final String risk;
  final String summary;
  const _RiskBanner({required this.risk, required this.summary});

  @override
  Widget build(BuildContext context) {
    Color color;
    String emoji;
    switch (risk) {
      case 'Critical': color = AppColors.error;   emoji = '🔴'; break;
      case 'High':     color = AppColors.warning; emoji = '🟠'; break;
      case 'Medium':   color = const Color(0xFFF9A825); emoji = '🟡'; break;
      default:         color = AppColors.success; emoji = '🟢';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Risk: $risk',
                    style: AppTextStyles.heading3
                        .copyWith(color: color)),
                const SizedBox(height: 4),
                Text(summary, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAlertCard extends StatelessWidget {
  final WeatherAlert alert;
  const _AiAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert.severityColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(alert.severity,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _QuickAdviceGrid extends StatelessWidget {
  final WeatherAiAdvisory advisory;
  const _QuickAdviceGrid({required this.advisory});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('💧', 'Irrigation', advisory.irrigationAdvice),
      ('🌱', 'Planting', advisory.plantingAdvice),
      ('🌾', 'Harvest', advisory.harvestAdvice),
    ];

    return Column(
      children: items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(item.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2,
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  Text(item.$3, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _DiseasePressureCard extends StatelessWidget {
  final WeatherAiAdvisory advisory;
  const _DiseasePressureCard({required this.advisory});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (advisory.diseasePressure) {
      case 'High':   color = AppColors.error; break;
      case 'Medium': color = AppColors.warning; break;
      default:       color = AppColors.success;
    }

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
          Row(
            children: [
              const Text('🍄', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Disease Pressure: ${advisory.diseasePressure}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          if (advisory.diseaseRiskCrops.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...advisory.diseaseRiskCrops.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.textHint)),
                      Expanded(
                          child: Text(r,
                              style: AppTextStyles.bodySmall)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _DayPlanCard extends StatelessWidget {
  final DayPlan plan;
  const _DayPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (plan.priority) {
      case 'High':   priorityColor = AppColors.error; break;
      case 'Medium': priorityColor = AppColors.warning; break;
      default:       priorityColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(plan.day,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Container(
            width: 4,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
              child: Text(plan.action, style: AppTextStyles.bodySmall)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(plan.priority,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: priorityColor)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXISTING TABS — unchanged from original
// =============================================================================

class _WeatherHero extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = provider.current;
    final bgColor = _skyBg(w?.condition ?? '');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.75)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: w == null
              ? const Center(
                  child: Text('Loading…',
                      style: TextStyle(color: Colors.white)))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_conditionEmoji(w.condition),
                                  style: const TextStyle(fontSize: 46)),
                              const SizedBox(width: 10),
                              Text(w.tempDisplay,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w300)),
                            ],
                          ),
                          Text(_capitalize(w.description),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white60, size: 14),
                              const SizedBox(width: 3),
                              Text('${w.cityName}, ${w.country}',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (w.isFromCache)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 12, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('Cached',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _skyBg(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return const Color(0xFF1565C0);
      case 'clouds':       return const Color(0xFF546E7A);
      case 'rain':
      case 'drizzle':      return const Color(0xFF37474F);
      case 'thunderstorm': return const Color(0xFF263238);
      default:             return AppColors.primaryDark;
    }
  }
}

class _CurrentTab extends StatelessWidget {
  final WeatherProvider provider;
  const _CurrentTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = provider.current!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.isFromCache || provider.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error ??
                          'Showing cached data from ${_fmtTime(w.fetchedAt)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(icon: '🌡️', label: 'Feels Like',
                  value: w.feelsLikeDisplay,
                  sub: 'Min ${w.tempMinC.round()}° / Max ${w.tempMaxC.round()}°'),
              _StatCard(icon: '💧', label: 'Humidity',
                  value: '${w.humidity}%',
                  sub: w.humidity > 80 ? 'High — disease risk'
                      : w.humidity < 30 ? 'Very dry' : 'Comfortable'),
              _StatCard(icon: '💨', label: 'Wind',
                  value: '${w.windSpeedKmh.toStringAsFixed(1)} km/h',
                  sub: w.windDirection),
              _StatCard(icon: '☁️', label: 'Cloud Cover',
                  value: '${w.cloudiness}%',
                  sub: w.rainMm1h != null
                      ? 'Rain: ${w.rainMm1h!.toStringAsFixed(1)} mm/h'
                      : 'No rain'),
              _StatCard(icon: '🔽', label: 'Pressure',
                  value: '${w.pressure} hPa',
                  sub: w.pressure > 1013 ? 'High — stable' : 'Low — changeable'),
              _StatCard(icon: '👁️', label: 'Visibility',
                  value: w.visibility >= 1000
                      ? '${(w.visibility / 1000).toStringAsFixed(1)} km'
                      : '${w.visibility} m',
                  sub: w.visibility > 5000 ? 'Clear' : 'Reduced'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SunTime(icon: '🌅', label: 'Sunrise', time: _fmtTime(w.sunrise)),
                Container(width: 1, height: 40, color: AppColors.divider),
                _SunTime(icon: '🌇', label: 'Sunset', time: _fmtTime(w.sunset)),
                Container(width: 1, height: 40, color: AppColors.divider),
                _SunTime(
                    icon: '⏱️',
                    label: 'Daylight',
                    time: _daylightHours(w.sunrise, w.sunset)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Last updated: ${_fmtDateTime(w.fetchedAt)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]}, ${_fmtTime(d)}';
  }

  String _daylightHours(DateTime rise, DateTime set) {
    final diff = set.difference(rise);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

class _ForecastTab extends StatelessWidget {
  final List<ForecastDay> forecast;
  const _ForecastTab({required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return const Center(child: Text('No forecast data available.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('5-Day Forecast', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...forecast.map((day) => _ForecastCard(day: day)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Planning Your Week',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._getWeeklyTips(forecast).map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.primary)),
                      Expanded(
                          child: Text(tip, style: AppTextStyles.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<String> _getWeeklyTips(List<ForecastDay> days) {
    final tips = <String>[];
    final rainyDays = days
        .where((d) => d.condition.toLowerCase() == 'rain' ||
            d.condition.toLowerCase() == 'thunderstorm')
        .toList();
    final dryDays = days
        .where((d) =>
            d.condition.toLowerCase() == 'clear' && d.windSpeedMs * 3.6 < 15)
        .toList();
    if (rainyDays.isNotEmpty) {
      tips.add(
          'Rain expected on ${rainyDays.map((d) => d.dayName).join(', ')} — avoid spraying.');
    }
    if (dryDays.isNotEmpty) {
      tips.add(
          '${dryDays.map((d) => d.dayName).join(', ')} look good for pesticide applications.');
    }
    if (days.any((d) => d.tempMaxC > 32)) {
      tips.add('High temperatures forecast — irrigate early morning on hot days.');
    }
    if (tips.isEmpty) {
      tips.add('Conditions look stable — good for general farm work.');
    }
    return tips;
  }
}

class _ForecastCard extends StatelessWidget {
  final ForecastDay day;
  const _ForecastCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final hasRain = day.rainMm > 0 || day.rainChance > 20;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRain
              ? AppColors.info.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(day.dayName,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(_conditionEmoji(day.condition),
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_capitalize(day.description),
                    style: AppTextStyles.body),
                Row(
                  children: [
                    Icon(Icons.water_drop,
                        size: 12,
                        color: hasRain
                            ? AppColors.info
                            : AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      '${day.rainChance}%  •  ${day.humidity}% humidity',
                      style: AppTextStyles.caption.copyWith(
                        color: hasRain ? AppColors.info : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${day.tempMaxC.round()}°',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
              Text('${day.tempMinC.round()}°',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvisoryTab extends StatelessWidget {
  final List<FarmAdvisory> advisories;
  const _AdvisoryTab({required this.advisories});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Farm Advisory', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Real-time recommendations based on current weather conditions.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        ...advisories.map((a) => _AdvisoryCard(advisory: a)),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final FarmAdvisory advisory;
  const _AdvisoryCard({required this.advisory});

  Color get _bgColor {
    switch (advisory.color) {
      case 'success': return AppColors.success.withOpacity(0.08);
      case 'warning': return AppColors.warning.withOpacity(0.08);
      case 'error':   return AppColors.error.withOpacity(0.08);
      default:        return AppColors.info.withOpacity(0.08);
    }
  }

  Color get _borderColor {
    switch (advisory.color) {
      case 'success': return AppColors.success.withOpacity(0.35);
      case 'warning': return AppColors.warning.withOpacity(0.35);
      case 'error':   return AppColors.error.withOpacity(0.35);
      default:        return AppColors.info.withOpacity(0.35);
    }
  }

  Color get _titleColor {
    switch (advisory.color) {
      case 'success': return AppColors.success;
      case 'warning': return AppColors.warning;
      case 'error':   return AppColors.error;
      default:        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advisory.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advisory.title,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700, color: _titleColor)),
                const SizedBox(height: 4),
                Text(advisory.body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onSelected;
  const _CityPickerSheet(
      {required this.currentCity, required this.onSelected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = WeatherService.zimbabweCities
        .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Select City', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search Zimbabwe city…',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final city = filtered[i];
                  final isCurrent = city == widget.currentCity;
                  return ListTile(
                    leading: Icon(Icons.location_city,
                        color: isCurrent
                            ? AppColors.primaryLight
                            : AppColors.textHint),
                    title: Text(city,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isCurrent
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                        )),
                    trailing: isCurrent
                        ? const Icon(Icons.check,
                            color: AppColors.primaryLight)
                        : null,
                    onTap: () => widget.onSelected(city),
                  );
                },
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

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;
  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.primaryDark)),
          Text(sub,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _SunTime extends StatelessWidget {
  final String icon;
  final String label;
  final String time;
  const _SunTime(
      {required this.icon, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(time,
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textHint)),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryLight),
          SizedBox(height: 16),
          Text('Fetching weather data…'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌧️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Weather Unavailable',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              error ??
                  'Unable to load weather data. Check your connection.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

String _conditionEmoji(String condition) {
  switch (condition.toLowerCase()) {
    case 'clear':        return '☀️';
    case 'clouds':       return '☁️';
    case 'rain':         return '🌧️';
    case 'drizzle':      return '🌦️';
    case 'thunderstorm': return '⛈️';
    case 'snow':         return '❄️';
    case 'mist':
    case 'fog':
    case 'haze':         return '🌫️';
    default:             return '🌤️';
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);