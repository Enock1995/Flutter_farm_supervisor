// lib/providers/weather_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';

class AlertThreshold {
  final double maxTempC;
  final double minTempC;
  final double maxWindKmh;
  final double minHumidity;
  final double maxHumidity;
  final double rainAlertMm;

  const AlertThreshold({
    this.maxTempC = 35.0,
    this.minTempC = 5.0,
    this.maxWindKmh = 40.0,
    this.minHumidity = 20.0,
    this.maxHumidity = 85.0,
    this.rainAlertMm = 10.0,
  });

  AlertThreshold copyWith({
    double? maxTempC,
    double? minTempC,
    double? maxWindKmh,
    double? minHumidity,
    double? maxHumidity,
    double? rainAlertMm,
  }) =>
      AlertThreshold(
        maxTempC: maxTempC ?? this.maxTempC,
        minTempC: minTempC ?? this.minTempC,
        maxWindKmh: maxWindKmh ?? this.maxWindKmh,
        minHumidity: minHumidity ?? this.minHumidity,
        maxHumidity: maxHumidity ?? this.maxHumidity,
        rainAlertMm: rainAlertMm ?? this.rainAlertMm,
      );
}

class ThresholdAlert {
  final String title;
  final String message;
  final String icon;
  final String level; // 'warning' | 'danger'

  const ThresholdAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.level,
  });
}

class WeatherProvider extends ChangeNotifier {
  WeatherResult? _result;
  bool _isLoading = false;
  String _city = 'Harare';

  // ── Threshold alerts ────────────────────────────────────
  AlertThreshold _thresholds = const AlertThreshold();
  AlertThreshold get thresholds => _thresholds;

  // ── AI advisory ─────────────────────────────────────────
  WeatherAiAdvisory? _aiAdvisory;
  bool _aiLoading = false;
  String? _aiError;

  WeatherAiAdvisory? get aiAdvisory => _aiAdvisory;
  bool get aiLoading => _aiLoading;
  String? get aiError => _aiError;

  WeatherResult? get result => _result;
  bool get isLoading => _isLoading;
  String get city => _city;
  WeatherData? get current => _result?.current;
  List<ForecastDay> get forecast => _result?.forecast ?? [];
  bool get hasData => _result?.hasData ?? false;
  String? get error => _result?.error;
  bool get isFromCache => _result?.isFromCache ?? false;

  /// Returns active threshold alerts based on current weather + thresholds.
  List<ThresholdAlert> get thresholdAlerts {
    if (current == null) return [];
    final alerts = <ThresholdAlert>[];
    final w = current!;

    if (w.tempC > _thresholds.maxTempC) {
      alerts.add(ThresholdAlert(
        title: 'Heat Alert — ${w.tempC.round()}°C',
        message:
            'Temperature exceeds your ${_thresholds.maxTempC.round()}°C threshold. '
            'Irrigate early morning, provide shade for sensitive crops.',
        icon: '🌡️',
        level: w.tempC > 38 ? 'danger' : 'warning',
      ));
    }

    if (w.tempC < _thresholds.minTempC) {
      alerts.add(ThresholdAlert(
        title: 'Cold Alert — ${w.tempC.round()}°C',
        message:
            'Temperature below your ${_thresholds.minTempC.round()}°C threshold. '
            'Protect seedlings and frost-sensitive crops overnight.',
        icon: '❄️',
        level: w.tempC < 2 ? 'danger' : 'warning',
      ));
    }

    if (w.windSpeedKmh > _thresholds.maxWindKmh) {
      alerts.add(ThresholdAlert(
        title: 'High Wind — ${w.windSpeedKmh.toStringAsFixed(0)} km/h',
        message:
            'Wind exceeds your ${_thresholds.maxWindKmh.round()} km/h threshold. '
            'Avoid spraying — drift risk. Check crop supports and greenhouses.',
        icon: '💨',
        level: w.windSpeedKmh > 60 ? 'danger' : 'warning',
      ));
    }

    if (w.humidity < _thresholds.minHumidity) {
      alerts.add(ThresholdAlert(
        title: 'Very Dry Air — ${w.humidity}% RH',
        message:
            'Humidity below your ${_thresholds.minHumidity.round()}% threshold. '
            'Increase irrigation frequency. Watch for spider mites.',
        icon: '🏜️',
        level: 'warning',
      ));
    }

    if (w.humidity > _thresholds.maxHumidity) {
      alerts.add(ThresholdAlert(
        title: 'High Humidity — ${w.humidity}% RH',
        message:
            'Humidity exceeds your ${_thresholds.maxHumidity.round()}% threshold. '
            'High disease risk. Inspect for fungal issues.',
        icon: '🍄',
        level: w.humidity > 92 ? 'danger' : 'warning',
      ));
    }

    if ((w.rainMm1h ?? 0) > _thresholds.rainAlertMm) {
      alerts.add(ThresholdAlert(
        title: 'Heavy Rain — ${w.rainMm1h!.toStringAsFixed(1)} mm/h',
        message:
            'Rainfall exceeds your ${_thresholds.rainAlertMm.round()} mm threshold. '
            'Skip irrigation today. Check drainage channels.',
        icon: '🌧️',
        level: (w.rainMm1h ?? 0) > 25 ? 'danger' : 'warning',
      ));
    }

    // Spray window check from forecast
    for (final day in forecast.take(3)) {
      if (day.rainChance > 60 || day.windSpeedMs * 3.6 > 25) {
        alerts.add(ThresholdAlert(
          title: 'Poor Spray Conditions — ${day.dayName}',
          message:
              '${day.dayName} has ${day.rainChance}% rain chance and high wind. '
              'Avoid applying pesticides or fungicides.',
          icon: '🚿',
          level: 'warning',
        ));
        break;
      }
    }

    return alerts;
  }

  /// Returns good spray window days from the 5-day forecast.
  List<String> get goodSprayDays {
    return forecast
        .where((d) =>
            d.rainChance < 20 &&
            d.windSpeedMs * 3.6 < 20 &&
            d.tempMaxC < 32)
        .map((d) => d.dayName)
        .toList();
  }

  Future<void> init({String? userDistrict}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('weather_city');

    if (savedCity != null) {
      _city = savedCity;
    } else if (userDistrict != null && userDistrict.isNotEmpty) {
      _city = _mapDistrictToCity(userDistrict);
    }

    await loadWeather();
  }

  Future<void> loadWeather({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    _result = await WeatherService.fetchWeather(
      city: _city,
      forceRefresh: forceRefresh,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeCity(String newCity) async {
    _city = newCity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_city', newCity);
    await loadWeather(forceRefresh: true);
  }

  List<FarmAdvisory> get advisories {
    if (current == null) return [];
    return WeatherService.getFarmAdvisories(current!);
  }

  // ── Update thresholds ────────────────────────────────────
  void updateThresholds(AlertThreshold newThresholds) {
    _thresholds = newThresholds;
    notifyListeners();
    _saveThresholds();
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('thresh_maxTemp', _thresholds.maxTempC);
    await prefs.setDouble('thresh_minTemp', _thresholds.minTempC);
    await prefs.setDouble('thresh_maxWind', _thresholds.maxWindKmh);
    await prefs.setDouble('thresh_minHumidity', _thresholds.minHumidity);
    await prefs.setDouble('thresh_maxHumidity', _thresholds.maxHumidity);
    await prefs.setDouble('thresh_rain', _thresholds.rainAlertMm);
  }

  Future<void> loadSavedThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    _thresholds = AlertThreshold(
      maxTempC: prefs.getDouble('thresh_maxTemp') ?? 35.0,
      minTempC: prefs.getDouble('thresh_minTemp') ?? 5.0,
      maxWindKmh: prefs.getDouble('thresh_maxWind') ?? 40.0,
      minHumidity: prefs.getDouble('thresh_minHumidity') ?? 20.0,
      maxHumidity: prefs.getDouble('thresh_maxHumidity') ?? 85.0,
      rainAlertMm: prefs.getDouble('thresh_rain') ?? 10.0,
    );
  }

  // ── AI Advisory ──────────────────────────────────────────
  /// Calls Claude AI to generate a detailed farm advisory from weather data.
  Future<void> loadAiAdvisory({
    required String district,
    required String agroRegion,
  }) async {
    if (current == null) return;
    _aiLoading = true;
    _aiError = null;
    notifyListeners();

    try {
      final forecastSummary = forecast
          .map((d) => {
                'day': d.dayName,
                'condition': d.condition,
                'max': d.tempMaxC.round(),
                'min': d.tempMinC.round(),
                'rain': d.rainChance,
              })
          .toList();

      _aiAdvisory = await AiService.weatherAiAdvisory(
        cityName: current!.cityName,
        tempC: current!.tempC,
        humidity: current!.humidity.toDouble(),
        windSpeedKmh: current!.windSpeedKmh,
        rainMm: current!.rainMm1h ?? 0.0,
        condition: current!.condition,
        district: district,
        agroRegion: agroRegion,
        forecastSummary: forecastSummary,
      );
    } catch (e) {
      _aiError = e.toString().replaceAll('AiException: ', '');
    }

    _aiLoading = false;
    notifyListeners();
  }

  static String _mapDistrictToCity(String district) {
    final d = district.toLowerCase().trim();

    const directCities = {
      'harare', 'bulawayo', 'mutare', 'gweru', 'kwekwe',
      'kadoma', 'masvingo', 'chinhoyi', 'marondera',
      'norton', 'chegutu', 'zvishavane', 'bindura',
      'beitbridge', 'hwange', 'kariba', 'rusape',
      'chipinge', 'chiredzi', 'victoria falls',
    };
    if (directCities.contains(d)) {
      return district
          .split(' ')
          .map((w) => w.isEmpty
              ? w
              : w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }

    const Map<String, String> districtToCity = {
      'harare urban': 'Harare', 'harare rural': 'Harare',
      'chitungwiza': 'Harare', 'epworth': 'Harare',
      'marondera': 'Marondera', 'murehwa': 'Marondera',
      'mudzi': 'Marondera', 'mutoko': 'Marondera',
      'goromonzi': 'Harare', 'seke': 'Harare',
      'wedza': 'Marondera', 'chikomba': 'Marondera',
      'uzumba maramba pfungwe': 'Marondera',
      'chinhoyi': 'Chinhoyi', 'makonde': 'Chinhoyi',
      'hurungwe': 'Kariba', 'kariba': 'Kariba',
      'zvimba': 'Chinhoyi', 'chegutu': 'Chegutu',
      'mhondoro-ngezi': 'Kadoma', 'kadoma': 'Kadoma',
      'sanyati': 'Kadoma', 'bindura': 'Bindura',
      'shamva': 'Bindura', 'mazowe': 'Bindura',
      'mt darwin': 'Bindura', 'mount darwin': 'Bindura',
      'centenary': 'Bindura', 'guruve': 'Bindura',
      'rushinga': 'Bindura', 'muzarabani': 'Bindura',
      'mutare': 'Mutare', 'makoni': 'Rusape',
      'rusape': 'Rusape', 'chipinge': 'Chipinge',
      'chimanimani': 'Chipinge', 'buhera': 'Mutare',
      'nyanga': 'Mutare', 'mutasa': 'Mutare',
      'masvingo': 'Masvingo', 'chiredzi': 'Chiredzi',
      'mwenezi': 'Masvingo', 'gutu': 'Masvingo',
      'zaka': 'Masvingo', 'bikita': 'Masvingo',
      'chivi': 'Masvingo', 'gweru': 'Gweru',
      'kwekwe': 'Kwekwe', 'zvishavane': 'Zvishavane',
      'shurugwi': 'Gweru', 'gokwe north': 'Kwekwe',
      'gokwe south': 'Kwekwe', 'mberengwa': 'Zvishavane',
      'chirumanzu': 'Gweru', 'lower gweru': 'Gweru',
      'vungu': 'Gweru', 'bulawayo': 'Bulawayo',
      'hwange': 'Hwange', 'lupane': 'Hwange',
      'nkayi': 'Hwange', 'binga': 'Kariba',
      'tsholotsho': 'Bulawayo', 'umguza': 'Bulawayo',
      'victoria falls': 'Victoria Falls',
      'beitbridge': 'Beitbridge', 'gwanda': 'Beitbridge',
      'insiza': 'Bulawayo', 'matobo': 'Bulawayo',
      'umzingwane': 'Bulawayo', 'bulilima': 'Bulawayo',
      'mangwe': 'Bulawayo',
    };

    return districtToCity[d] ?? 'Harare';
  }
}