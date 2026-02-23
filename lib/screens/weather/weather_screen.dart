// lib/screens/weather/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final region = user?.agroRegion ?? 'IIa';
    final district = user?.district ?? 'Harare';
    final currentMonth = DateTime.now().month;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Weather & Climate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentConditionsCard(
                district: district, region: region),
            const SizedBox(height: 16),
            _SeasonCard(
                region: region, month: currentMonth),
            const SizedBox(height: 16),
            _MonthlyCalendarCard(region: region),
            const SizedBox(height: 16),
            _FarmingAdviceCard(
                region: region, month: currentMonth),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CURRENT CONDITIONS CARD
// ---------------------------------------------------------------------------
class _CurrentConditionsCard extends StatelessWidget {
  final String district;
  final String region;
  const _CurrentConditionsCard(
      {required this.district, required this.region});

  @override
  Widget build(BuildContext context) {
    final month = DateTime.now().month;
    final isRainy = month >= 10 || month <= 4;
    final isDry = month >= 5 && month <= 9;
    final isPeak = month == 12 || month == 1 || month == 2;

    String condition;
    String tempRange;
    String icon;
    Color bgColor;

    if (isPeak) {
      condition = 'Hot & Wet Season';
      tempRange = '22–35°C';
      icon = '⛈️';
      bgColor = const Color(0xFF1565C0);
    } else if (isRainy) {
      condition = 'Rainy Season';
      tempRange = '18–30°C';
      icon = '🌧️';
      bgColor = const Color(0xFF1976D2);
    } else if (month == 5 || month == 6) {
      condition = 'Cool Dry Season';
      tempRange = '8–22°C';
      icon = '🌤️';
      bgColor = const Color(0xFF0288D1);
    } else if (month == 7 || month == 8) {
      condition = 'Cold Dry Season';
      tempRange = '4–20°C';
      icon = '🌬️';
      bgColor = const Color(0xFF01579B);
    } else {
      condition = 'Hot Dry Season';
      tempRange = '20–35°C';
      icon = '☀️';
      bgColor = const Color(0xFFE65100);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(district,
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white)),
                  Text('Region $region',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70)),
                ],
              ),
              Text(icon,
                  style: const TextStyle(fontSize: 52)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tempRange,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          Text(condition,
              style: AppTextStyles.heading3
                  .copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              _WeatherStat(
                  icon: '💧',
                  label: 'Season',
                  value: _seasonName(month)),
              const SizedBox(width: 16),
              _WeatherStat(
                  icon: '🌱',
                  label: 'Farming',
                  value: _farmingStatus(month)),
              const SizedBox(width: 16),
              _WeatherStat(
                  icon: '☔',
                  label: 'Rain',
                  value: _rainStatus(month, region)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live weather unavailable offline. Showing seasonal averages for your region.',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _seasonName(int m) {
    if (m >= 10 || m <= 4) return 'Rainy';
    if (m >= 5 && m <= 8) return 'Dry';
    return 'Late Dry';
  }

  String _farmingStatus(int m) {
    if (m == 10 || m == 11) return 'Plant Now';
    if (m >= 12 || m <= 3) return 'Growing';
    if (m == 4 || m == 5) return 'Harvest';
    return 'Land Prep';
  }

  String _rainStatus(int m, String region) {
    if (m >= 11 && m <= 3) {
      return region == 'I' || region == 'IIa'
          ? 'Good'
          : 'Moderate';
    }
    if (m >= 10) return 'Starting';
    return 'None';
  }
}

class _WeatherStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _WeatherStat(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.body
                  .copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SEASON CARD
// ---------------------------------------------------------------------------
class _SeasonCard extends StatelessWidget {
  final String region;
  final int month;
  const _SeasonCard(
      {required this.region, required this.month});

  @override
  Widget build(BuildContext context) {
    final info = _getSeasonInfo(region, month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined,
                  color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Season Overview',
                  style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _SeasonStat(
                      label: 'Rainfall',
                      value: info['rainfall']!,
                      icon: '🌧️')),
              Expanded(
                  child: _SeasonStat(
                      label: 'Humidity',
                      value: info['humidity']!,
                      icon: '💦')),
              Expanded(
                  child: _SeasonStat(
                      label: 'Wind',
                      value: info['wind']!,
                      icon: '💨')),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              info['advice']!,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getSeasonInfo(
      String region, int month) {
    // Rainy season
    if (month >= 11 && month <= 3) {
      final rainfall = region == 'I'
          ? '150–200mm/month'
          : region == 'IIa' || region == 'IIb'
              ? '100–150mm/month'
              : region == 'III'
                  ? '75–100mm/month'
                  : '50–75mm/month';
      return {
        'rainfall': rainfall,
        'humidity': '70–85%',
        'wind': 'Light–Moderate',
        'advice':
            '🌱 Peak growing season. Ensure timely planting, weeding, and pest scouting. Monitor for fungal diseases in humid conditions.',
      };
    }
    // Post-rainy / harvest (April–May)
    if (month == 4 || month == 5) {
      return {
        'rainfall': '20–60mm/month',
        'humidity': '50–65%',
        'wind': 'Moderate',
        'advice':
            '🌾 Harvest season. Dry grain and produce quickly to avoid post-harvest losses. Start land preparation for next season.',
      };
    }
    // Cold dry (June–August)
    if (month >= 6 && month <= 8) {
      return {
        'rainfall': '0–5mm/month',
        'humidity': '30–45%',
        'wind': 'Strong & Cold',
        'advice':
            '❄️ Cold dry season. Good time for wheat in high regions. Protect livestock from cold. Maintain water sources for animals.',
      };
    }
    // Hot dry (September–October)
    return {
      'rainfall': '5–30mm/month',
      'humidity': '25–40%',
      'wind': 'Hot & Dry',
      'advice':
          '🔥 Hot dry season. Prepare land for planting. Vaccinate livestock before rains. Water is critical — check all sources.',
    };
  }
}

class _SeasonStat extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _SeasonStat(
      {required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        Text(label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// MONTHLY RAINFALL CALENDAR
// ---------------------------------------------------------------------------
class _MonthlyCalendarCard extends StatelessWidget {
  final String region;
  const _MonthlyCalendarCard({required this.region});

  // Average monthly rainfall mm per region
  static const Map<String, List<int>> _rainfall = {
    'I':   [200, 180, 120, 50, 10, 2, 1, 2, 10, 50, 120, 180],
    'IIa': [170, 150, 100, 40, 8, 1, 1, 1, 8, 40, 100, 150],
    'IIb': [150, 130, 90, 35, 6, 1, 0, 1, 7, 35, 90, 130],
    'III': [110, 100, 70, 25, 4, 0, 0, 0, 5, 25, 70, 100],
    'IV':  [75, 65, 50, 15, 2, 0, 0, 0, 3, 15, 50, 65],
    'V':   [50, 45, 35, 10, 1, 0, 0, 0, 2, 10, 35, 45],
  };

  @override
  Widget build(BuildContext context) {
    final data = _rainfall[region] ??
        _rainfall['IIa']!;
    final currentMonth = DateTime.now().month;
    final maxRain =
        data.reduce((a, b) => a > b ? a : b).toDouble();

    const months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Monthly Rainfall — Region $region',
                  style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final isNow = (i + 1) == currentMonth;
              final height = maxRain > 0
                  ? (data[i] / maxRain * 80).clamp(4.0, 80.0)
                  : 4.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      if (isNow)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: Duration(
                            milliseconds: 300 + i * 50),
                        height: height,
                        decoration: BoxDecoration(
                          color: isNow
                              ? AppColors.accent
                              : data[i] > 50
                                  ? AppColors.primary
                                  : data[i] > 10
                                      ? AppColors
                                          .primaryLight
                                          .withOpacity(0.6)
                                      : AppColors.divider,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(months[i],
                          style:
                              AppTextStyles.caption.copyWith(
                            fontWeight: isNow
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isNow
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Legend(
                  color: AppColors.primary,
                  label: 'High (>50mm)'),
              const SizedBox(width: 12),
              _Legend(
                  color:
                      AppColors.primaryLight.withOpacity(0.6),
                  label: 'Low (10–50mm)'),
              const SizedBox(width: 12),
              _Legend(
                  color: AppColors.accent,
                  label: 'Now'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FARMING ADVICE CARD
// ---------------------------------------------------------------------------
class _FarmingAdviceCard extends StatelessWidget {
  final String region;
  final int month;
  const _FarmingAdviceCard(
      {required this.region, required this.month});

  static const Map<int, Map<String, String>> _advice = {
    1: {
      'title': 'January — Peak Rainy Season 🌧️',
      'crop': 'Top-dress maize. Scout intensively for Fall Armyworm. Apply fungicide for grey leaf spot.',
      'livestock': 'Tick dipping every week. Watch for East Coast Fever. Keep cattle in dry areas.',
      'general': 'Roads may flood — plan input delivery early. Store critical medications on farm.',
    },
    2: {
      'title': 'February — Late Rains 🌿',
      'crop': 'Monitor crop for stalk borer. Maize at silking — no spray. Scout for diseases.',
      'livestock': 'Continue weekly dipping. Treat any sick animals promptly.',
      'general': 'Start planning marketing — assess crop yield. Check grain storage facilities.',
    },
    3: {
      'title': 'March — Rains Ending 🌦️',
      'crop': 'Assess crop maturity. Begin early harvesting where possible. Watch for aflatoxin risk.',
      'livestock': 'Check body condition scores — supplement thin animals.',
      'general': 'Order drying and storage materials. Contact grain buyers early.',
    },
    4: {
      'title': 'April — Harvest Season 🌾',
      'crop': 'Harvest maize, groundnuts, soybeans. Dry grain to 12–13% before storage.',
      'livestock': 'Vaccinate for Enterotoxaemia (goats/sheep). FMD vaccination due.',
      'general': 'Keep harvested grain off the ground. Use certified storage bags.',
    },
    5: {
      'title': 'May — Post-Harvest 🚜',
      'crop': 'Plant wheat (Regions I, IIa). Prepare land for next season. Plow in crop residues.',
      'livestock': 'Begin dry-season feeding program. Check water points.',
      'general': 'Record season results. Budget for next season inputs.',
    },
    6: {
      'title': 'June — Cold Season ❄️',
      'crop': 'Manage wheat — weed and fertilize. Irrigate winter crops.',
      'livestock': 'Protect young animals from cold nights. Provide extra feed.',
      'general': 'Service farm equipment. Repair fencing and storage facilities.',
    },
    7: {
      'title': 'July — Mid Winter ❄️',
      'crop': 'Monitor wheat for rust diseases. Apply fungicide if needed.',
      'livestock': 'Deworming season — dose all small stock. Continue body condition monitoring.',
      'general': 'Order inputs for next rainy season. Attend farm training days.',
    },
    8: {
      'title': 'August — Late Winter 🌬️',
      'crop': 'Plan crop varieties for next season. Order certified seed and fertilizer.',
      'livestock': 'Begin vaccinating for anthrax and blackleg before rains.',
      'general': 'Start land preparation — deep plough now for better moisture retention.',
    },
    9: {
      'title': 'September — Pre-season 🌡️',
      'crop': 'Land preparation in full swing. Apply lime if needed.',
      'livestock': 'Complete all pre-season vaccinations. FMD due. Service dip tanks.',
      'general': 'Confirm seed, fertilizer, and chemical orders. Check irrigation.',
    },
    10: {
      'title': 'October — Planting Season Begins 🌱',
      'crop': 'Plant as soon as first good rains arrive. Plant tobacco seedbeds.',
      'livestock': 'FMD vaccination due. Weekly tick dipping starts.',
      'general': 'Monitor weather forecasts daily. Have inputs ready before first rains.',
    },
    11: {
      'title': 'November — Main Planting 🌱',
      'crop': 'Plant maize, cotton, groundnuts. Top-dress tobacco. Weed early.',
      'livestock': 'Watch for disease outbreaks after rains begin. Monitor tick loads.',
      'general': 'Early planted crops are 2–3 weeks ahead — protect the advantage.',
    },
    12: {
      'title': 'December — Growing Season 🌿',
      'crop': 'Weed maize. Scout for Fall Armyworm. Apply insecticide in whorl if needed.',
      'livestock': 'Continue weekly dipping. Ensure adequate water for all animals.',
      'general': 'Peak growing season. Daily field scouting is critical now.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final info = _advice[month] ?? _advice[1]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(info['title']!,
                    style: AppTextStyles.heading3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AdviceTile(
              icon: '🌾',
              title: 'Crop Tasks',
              content: info['crop']!,
              color: AppColors.primary),
          const SizedBox(height: 10),
          _AdviceTile(
              icon: '🐄',
              title: 'Livestock Tasks',
              content: info['livestock']!,
              color: AppColors.earth),
          const SizedBox(height: 10),
          _AdviceTile(
              icon: '📋',
              title: 'General',
              content: info['general']!,
              color: AppColors.info),
        ],
      ),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  final String icon;
  final String title;
  final String content;
  final Color color;
  const _AdviceTile(
      {required this.icon,
      required this.title,
      required this.content,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 3),
                Text(content,
                    style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}