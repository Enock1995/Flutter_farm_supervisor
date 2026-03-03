// lib/screens/weather/weather_screen.dart
// Developed by Sir Enocks — Cor Technologies
// Real-time weather via OpenWeatherMap + farm advisory engine

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/weather_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      context.read<WeatherProvider>().init(
            userDistrict: user?.district ?? '',
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: _skyColor(
                    provider.current?.condition ?? ''),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.location_city,
                        color: Colors.white),
                    tooltip: 'Change city',
                    onPressed: () =>
                        _showCityPicker(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white),
                    tooltip: 'Refresh',
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.loadWeather(
                            forceRefresh: true),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _WeatherHero(
                      provider: provider),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      Colors.white54,
                  tabs: const [
                    Tab(text: 'Current'),
                    Tab(text: '5-Day Forecast'),
                    Tab(text: 'Farm Advisory'),
                  ],
                ),
              ),
            ],
            body: provider.isLoading && !provider.hasData
                ? _LoadingView()
                : !provider.hasData
                    ? _ErrorView(
                        error: provider.error,
                        onRetry: () => provider
                            .loadWeather(forceRefresh: true),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _CurrentTab(
                              provider: provider),
                          _ForecastTab(
                              forecast: provider.forecast),
                          _AdvisoryTab(
                              advisories:
                                  provider.advisories),
                        ],
                      ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CITY PICKER
  // ---------------------------------------------------------------------------
  void _showCityPicker(
      BuildContext context, WeatherProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
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
      case 'clear':
        return const Color(0xFF1565C0);
      case 'clouds':
        return const Color(0xFF546E7A);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF37474F);
      case 'thunderstorm':
        return const Color(0xFF263238);
      case 'snow':
        return const Color(0xFF78909C);
      default:
        return AppColors.primaryDark;
    }
  }
}

// =============================================================================
// HERO HEADER
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
          padding:
              const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: w == null
              ? const Center(
                  child: Text('Loading…',
                      style: TextStyle(
                          color: Colors.white)))
              : Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    // Weather icon + temp
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _conditionEmoji(
                                    w.condition),
                                style: const TextStyle(
                                    fontSize: 46),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                w.tempDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight:
                                      FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _capitalize(w.description),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                  Icons.location_on,
                                  color: Colors.white60,
                                  size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${w.cityName}, ${w.country}',
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Cache badge
                    if (w.isFromCache)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off,
                                size: 12,
                                color: Colors.white70),
                            SizedBox(width: 4),
                            Text('Cached',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
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
      case 'clear':
        return const Color(0xFF1565C0);
      case 'clouds':
        return const Color(0xFF546E7A);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF37474F);
      case 'thunderstorm':
        return const Color(0xFF263238);
      default:
        return AppColors.primaryDark;
    }
  }
}

// =============================================================================
// TAB 1 — CURRENT WEATHER
// =============================================================================
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
          // Cache / refresh notice
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
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                icon: '🌡️',
                label: 'Feels Like',
                value: w.feelsLikeDisplay,
                sub:
                    'Min ${w.tempMinC.round()}° / Max ${w.tempMaxC.round()}°',
              ),
              _StatCard(
                icon: '💧',
                label: 'Humidity',
                value: '${w.humidity}%',
                sub: w.humidity > 80
                    ? 'High — disease risk'
                    : w.humidity < 30
                        ? 'Very dry'
                        : 'Comfortable',
              ),
              _StatCard(
                icon: '💨',
                label: 'Wind',
                value:
                    '${w.windSpeedKmh.toStringAsFixed(1)} km/h',
                sub: w.windDirection,
              ),
              _StatCard(
                icon: '☁️',
                label: 'Cloud Cover',
                value: '${w.cloudiness}%',
                sub: w.rainMm1h != null
                    ? 'Rain: ${w.rainMm1h!.toStringAsFixed(1)} mm/h'
                    : 'No rain',
              ),
              _StatCard(
                icon: '🔽',
                label: 'Pressure',
                value: '${w.pressure} hPa',
                sub: w.pressure > 1013
                    ? 'High — stable'
                    : 'Low — changeable',
              ),
              _StatCard(
                icon: '👁️',
                label: 'Visibility',
                value: w.visibility >= 1000
                    ? '${(w.visibility / 1000).toStringAsFixed(1)} km'
                    : '${w.visibility} m',
                sub: w.visibility > 5000
                    ? 'Clear'
                    : 'Reduced',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sunrise / Sunset
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _SunTime(
                    icon: '🌅',
                    label: 'Sunrise',
                    time: _fmtTime(w.sunrise)),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                ),
                _SunTime(
                    icon: '🌇',
                    label: 'Sunset',
                    time: _fmtTime(w.sunset)),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                ),
                _SunTime(
                    icon: '⏱️',
                    label: 'Daylight',
                    time: _daylightHours(
                        w.sunrise, w.sunset)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Last updated
          Center(
            child: Text(
              'Last updated: ${_fmtDateTime(w.fetchedAt)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDateTime(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]}, ${_fmtTime(d)}';
  }

  String _daylightHours(DateTime rise, DateTime set) {
    final diff = set.difference(rise);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }
}

// =============================================================================
// TAB 2 — 5-DAY FORECAST
// =============================================================================
class _ForecastTab extends StatelessWidget {
  final List<ForecastDay> forecast;
  const _ForecastTab({required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return const Center(
        child: Text('No forecast data available.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('5-Day Forecast',
            style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...forecast.map((day) => _ForecastCard(day: day)),
        const SizedBox(height: 20),

        // Forecast tips
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Planning Your Week',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._getWeeklyTips(forecast).map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppColors.primary)),
                      Expanded(
                          child: Text(tip,
                              style:
                                  AppTextStyles.bodySmall)),
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
        .where((d) =>
            d.condition.toLowerCase() == 'rain' ||
            d.condition.toLowerCase() == 'thunderstorm')
        .toList();
    final dryDays = days
        .where((d) =>
            d.condition.toLowerCase() == 'clear' &&
            d.windSpeedMs * 3.6 < 15)
        .toList();

    if (rainyDays.isNotEmpty) {
      final names = rainyDays.map((d) => d.dayName).join(', ');
      tips.add(
          'Rain expected on $names — avoid spraying on these days.');
    }
    if (dryDays.isNotEmpty) {
      final names = dryDays.map((d) => d.dayName).join(', ');
      tips.add(
          '$names look good for pesticide/fungicide applications.');
    }

    final hotDays =
        days.where((d) => d.tempMaxC > 32).toList();
    if (hotDays.isNotEmpty) {
      tips.add(
          'High temperatures forecast — irrigate early morning on hot days.');
    }
    if (tips.isEmpty) {
      tips.add(
          'Conditions look stable this week — good for general farm work.');
    }
    return tips;
  }
}

class _ForecastCard extends StatelessWidget {
  final ForecastDay day;
  const _ForecastCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final hasRain =
        day.rainMm > 0 || day.rainChance > 20;

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
          // Day name
          SizedBox(
            width: 40,
            child: Text(
              day.dayName,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700),
            ),
          ),
          // Icon
          Text(_conditionEmoji(day.condition),
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                      style: AppTextStyles.caption
                          .copyWith(
                        color: hasRain
                            ? AppColors.info
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Temp range
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${day.tempMaxC.round()}°',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark),
              ),
              Text(
                '${day.tempMinC.round()}°',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3 — FARM ADVISORY
// =============================================================================
class _AdvisoryTab extends StatelessWidget {
  final List<FarmAdvisory> advisories;
  const _AdvisoryTab({required this.advisories});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Farm Advisory',
            style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Real-time recommendations based on current weather conditions.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        ...advisories.map(
            (a) => _AdvisoryCard(advisory: a)),
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
      case 'success':
        return AppColors.success.withOpacity(0.08);
      case 'warning':
        return AppColors.warning.withOpacity(0.08);
      case 'error':
        return AppColors.error.withOpacity(0.08);
      default:
        return AppColors.info.withOpacity(0.08);
    }
  }

  Color get _borderColor {
    switch (advisory.color) {
      case 'success':
        return AppColors.success.withOpacity(0.35);
      case 'warning':
        return AppColors.warning.withOpacity(0.35);
      case 'error':
        return AppColors.error.withOpacity(0.35);
      default:
        return AppColors.info.withOpacity(0.35);
    }
  }

  Color get _titleColor {
    switch (advisory.color) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
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
          Text(advisory.icon,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  advisory.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(advisory.body,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CITY PICKER SHEET
// =============================================================================
class _CityPickerSheet extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onSelected;
  const _CityPickerSheet(
      {required this.currentCity,
      required this.onSelected});

  @override
  State<_CityPickerSheet> createState() =>
      _CityPickerSheetState();
}

class _CityPickerSheetState
    extends State<_CityPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = WeatherService.zimbabweCities
        .where((c) =>
            c.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select City',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) =>
                  setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search Zimbabwe city…',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final city = filtered[i];
                  final isCurrent =
                      city == widget.currentCity;
                  return ListTile(
                    leading: Icon(
                      Icons.location_city,
                      color: isCurrent
                          ? AppColors.primaryLight
                          : AppColors.textHint,
                    ),
                    title: Text(city,
                        style: AppTextStyles.body
                            .copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isCurrent
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                        )),
                    trailing: isCurrent
                        ? const Icon(Icons.check,
                            color:
                                AppColors.primaryLight)
                        : null,
                    onTap: () =>
                        widget.onSelected(city),
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
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
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
              Text(icon,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark)),
          Text(sub,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint)),
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
      {required this.icon,
      required this.label,
      required this.time});

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
          CircularProgressIndicator(
              color: AppColors.primaryLight),
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
  const _ErrorView(
      {required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌧️',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Weather Unavailable',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
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