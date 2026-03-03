// lib/services/weather_service.dart
// Real-time weather via OpenWeatherMap API.
// Hybrid: fetches live when online, serves cached data when offline.
// Developed by Sir Enocks — Cor Technologies

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class WeatherData {
  final String cityName;
  final String country;
  final double tempC;
  final double feelsLikeC;
  final double tempMinC;
  final double tempMaxC;
  final int humidity;
  final double windSpeedMs;
  final int windDeg;
  final String condition;       // e.g. "Clouds"
  final String description;     // e.g. "scattered clouds"
  final String iconCode;        // e.g. "04d"
  final int cloudiness;         // %
  final double? rainMm1h;       // mm in last hour (if any)
  final int pressure;           // hPa
  final int visibility;         // metres
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime fetchedAt;
  final bool isFromCache;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.tempC,
    required this.feelsLikeC,
    required this.tempMinC,
    required this.tempMaxC,
    required this.humidity,
    required this.windSpeedMs,
    required this.windDeg,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.cloudiness,
    this.rainMm1h,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.fetchedAt,
    this.isFromCache = false,
  });

  String get windDirection {
    const dirs = ['N','NE','E','SE','S','SW','W','NW'];
    return dirs[((windDeg % 360) / 45).round() % 8];
  }

  double get windSpeedKmh => windSpeedMs * 3.6;

  String get tempDisplay => '${tempC.round()}°C';
  String get feelsLikeDisplay => '${feelsLikeC.round()}°C';
  String get windDisplay =>
      '${windSpeedKmh.toStringAsFixed(1)} km/h $windDirection';

  Map<String, dynamic> toJson() => {
        'city_name': cityName,
        'country': country,
        'temp_c': tempC,
        'feels_like_c': feelsLikeC,
        'temp_min_c': tempMinC,
        'temp_max_c': tempMaxC,
        'humidity': humidity,
        'wind_speed_ms': windSpeedMs,
        'wind_deg': windDeg,
        'condition': condition,
        'description': description,
        'icon_code': iconCode,
        'cloudiness': cloudiness,
        'rain_mm_1h': rainMm1h,
        'pressure': pressure,
        'visibility': visibility,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> j,
      {bool fromCache = false}) =>
      WeatherData(
        cityName: j['city_name'] ?? '',
        country: j['country'] ?? '',
        tempC: (j['temp_c'] as num).toDouble(),
        feelsLikeC: (j['feels_like_c'] as num).toDouble(),
        tempMinC: (j['temp_min_c'] as num).toDouble(),
        tempMaxC: (j['temp_max_c'] as num).toDouble(),
        humidity: j['humidity'] as int,
        windSpeedMs: (j['wind_speed_ms'] as num).toDouble(),
        windDeg: j['wind_deg'] as int,
        condition: j['condition'] ?? '',
        description: j['description'] ?? '',
        iconCode: j['icon_code'] ?? '01d',
        cloudiness: j['cloudiness'] as int,
        rainMm1h: j['rain_mm_1h'] != null
            ? (j['rain_mm_1h'] as num).toDouble()
            : null,
        pressure: j['pressure'] as int,
        visibility: j['visibility'] as int,
        sunrise: DateTime.parse(j['sunrise']),
        sunset: DateTime.parse(j['sunset']),
        fetchedAt: DateTime.parse(j['fetched_at']),
        isFromCache: fromCache,
      );

  /// Parse directly from raw OWM /weather response
  factory WeatherData.fromOwmJson(Map<String, dynamic> j) {
    final main = j['main'] as Map<String, dynamic>;
    final weather =
        (j['weather'] as List).first as Map<String, dynamic>;
    final wind = j['wind'] as Map<String, dynamic>? ?? {};
    final clouds = j['clouds'] as Map<String, dynamic>? ?? {};
    final rain = j['rain'] as Map<String, dynamic>?;
    final sys = j['sys'] as Map<String, dynamic>? ?? {};

    return WeatherData(
      cityName: j['name'] as String? ?? '',
      country: sys['country'] as String? ?? '',
      tempC: (main['temp'] as num).toDouble() - 273.15,
      feelsLikeC: (main['feels_like'] as num).toDouble() - 273.15,
      tempMinC: (main['temp_min'] as num).toDouble() - 273.15,
      tempMaxC: (main['temp_max'] as num).toDouble() - 273.15,
      humidity: main['humidity'] as int,
      windSpeedMs: (wind['speed'] as num?)?.toDouble() ?? 0,
      windDeg: (wind['deg'] as num?)?.toInt() ?? 0,
      condition: weather['main'] as String,
      description: weather['description'] as String,
      iconCode: weather['icon'] as String,
      cloudiness: (clouds['all'] as num?)?.toInt() ?? 0,
      rainMm1h: rain?['1h'] != null
          ? (rain!['1h'] as num).toDouble()
          : null,
      pressure: main['pressure'] as int,
      visibility: (j['visibility'] as num?)?.toInt() ?? 10000,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (((sys['sunrise'] as num?) ?? 0) * 1000).toInt()),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (((sys['sunset'] as num?) ?? 0) * 1000).toInt()),
      fetchedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------

class ForecastDay {
  final DateTime date;
  final double tempMinC;
  final double tempMaxC;
  final double tempAvgC;
  final int humidity;
  final double windSpeedMs;
  final String condition;
  final String description;
  final String iconCode;
  final double rainMm;
  final int rainChance; // %

  const ForecastDay({
    required this.date,
    required this.tempMinC,
    required this.tempMaxC,
    required this.tempAvgC,
    required this.humidity,
    required this.windSpeedMs,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.rainMm,
    required this.rainChance,
  });

  String get dayName {
    const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return days[date.weekday % 7];
  }

  String get tempDisplay =>
      '${tempMinC.round()}° / ${tempMaxC.round()}°C';

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'temp_min_c': tempMinC,
        'temp_max_c': tempMaxC,
        'temp_avg_c': tempAvgC,
        'humidity': humidity,
        'wind_speed_ms': windSpeedMs,
        'condition': condition,
        'description': description,
        'icon_code': iconCode,
        'rain_mm': rainMm,
        'rain_chance': rainChance,
      };

  factory ForecastDay.fromJson(Map<String, dynamic> j) =>
      ForecastDay(
        date: DateTime.parse(j['date']),
        tempMinC: (j['temp_min_c'] as num).toDouble(),
        tempMaxC: (j['temp_max_c'] as num).toDouble(),
        tempAvgC: (j['temp_avg_c'] as num).toDouble(),
        humidity: j['humidity'] as int,
        windSpeedMs: (j['wind_speed_ms'] as num).toDouble(),
        condition: j['condition'],
        description: j['description'],
        iconCode: j['icon_code'],
        rainMm: (j['rain_mm'] as num).toDouble(),
        rainChance: j['rain_chance'] as int,
      );
}

// ---------------------------------------------------------------------------

class WeatherResult {
  final WeatherData? current;
  final List<ForecastDay> forecast;
  final bool isFromCache;
  final String? error;

  const WeatherResult({
    this.current,
    this.forecast = const [],
    this.isFromCache = false,
    this.error,
  });

  bool get hasData => current != null;
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class WeatherService {
  static const _apiKey = 'fc1a78d88893e007ce3d1358e6b08f54';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const _cacheCurrentKey = 'weather_current_v2';
  static const _cacheForecastKey = 'weather_forecast_v2';
  static const _cacheTimestampKey = 'weather_fetched_at';
  static const _cacheMaxAgeMinutes = 30;

  // ---------------------------------------------------------------------------
  // PUBLIC: fetch weather for a city name
  // ---------------------------------------------------------------------------
  static Future<WeatherResult> fetchWeather({
    required String city,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Return fresh cache if available and not forcing refresh
    if (!forceRefresh) {
      final cached = _loadCache(prefs);
      if (cached != null) return cached;
    }

    // Try live fetch
    try {
      final current = await _fetchCurrent(city);
      final forecast = await _fetchForecast(city);
      _saveCache(prefs, current, forecast);
      return WeatherResult(
        current: current,
        forecast: forecast,
        isFromCache: false,
      );
    } on WeatherException catch (e) {
      // Live failed — try stale cache
      final stale = _loadCache(prefs, ignoreAge: true);
      if (stale != null) {
        return WeatherResult(
          current: stale.current,
          forecast: stale.forecast,
          isFromCache: true,
          error: 'Offline — showing last update. ${e.message}',
        );
      }
      return WeatherResult(error: e.message);
    } catch (e) {
      final stale = _loadCache(prefs, ignoreAge: true);
      if (stale != null) {
        return WeatherResult(
          current: stale.current,
          forecast: stale.forecast,
          isFromCache: true,
          error: 'Offline — showing last update.',
        );
      }
      return WeatherResult(error: 'Unable to load weather. Check connection.');
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH CURRENT WEATHER
  // ---------------------------------------------------------------------------
  static Future<WeatherData> _fetchCurrent(String city) async {
    final uri = Uri.parse(
        '$_baseUrl/weather?q=${Uri.encodeComponent(city)}&appid=$_apiKey');

    final response =
        await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData.fromOwmJson(json);
    } else if (response.statusCode == 401) {
      throw WeatherException('Invalid API key.');
    } else if (response.statusCode == 404) {
      throw WeatherException('City "$city" not found.');
    } else {
      throw WeatherException(
          'Weather API error ${response.statusCode}.');
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH 5-DAY FORECAST (OWM returns 3-hourly — we aggregate to daily)
  // ---------------------------------------------------------------------------
  static Future<List<ForecastDay>> _fetchForecast(String city) async {
    final uri = Uri.parse(
        '$_baseUrl/forecast?q=${Uri.encodeComponent(city)}&appid=$_apiKey');

    final response =
        await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['list'] as List;

    // Group 3-hourly slots by date
    final Map<String, List<Map<String, dynamic>>> byDay = {};
    for (final slot in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          (slot['dt'] as int) * 1000);
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => []);
      byDay[key]!.add(slot as Map<String, dynamic>);
    }

    // Aggregate each day
    final days = <ForecastDay>[];
    for (final entry in byDay.entries) {
      final slots = entry.value;
      final temps = slots
          .map((s) =>
              (s['main']['temp'] as num).toDouble() - 273.15)
          .toList();
      final pops = slots
          .map((s) =>
              ((s['pop'] as num?)?.toDouble() ?? 0) * 100)
          .toList();
      final rains = slots
          .map((s) =>
              (s['rain'] as Map?)?['3h'] != null
                  ? ((s['rain'] as Map)['3h'] as num).toDouble()
                  : 0.0)
          .toList();
      final humidities =
          slots.map((s) => s['main']['humidity'] as int).toList();
      final winds = slots
          .map((s) =>
              (s['wind']['speed'] as num?)?.toDouble() ?? 0)
          .toList();

      // Representative slot: midday if available, else first
      final repSlot = slots.firstWhere(
        (s) {
          final h = DateTime.fromMillisecondsSinceEpoch(
              (s['dt'] as int) * 1000).hour;
          return h >= 11 && h <= 14;
        },
        orElse: () => slots.first,
      );
      final weather =
          (repSlot['weather'] as List).first as Map<String, dynamic>;

      days.add(ForecastDay(
        date: DateTime.parse(entry.key),
        tempMinC: temps.reduce((a, b) => a < b ? a : b),
        tempMaxC: temps.reduce((a, b) => a > b ? a : b),
        tempAvgC: temps.reduce((a, b) => a + b) / temps.length,
        humidity:
            (humidities.reduce((a, b) => a + b) / humidities.length)
                .round(),
        windSpeedMs:
            winds.reduce((a, b) => a + b) / winds.length,
        condition: weather['main'] as String,
        description: weather['description'] as String,
        iconCode: weather['icon'] as String,
        rainMm: rains.fold(0.0, (a, b) => a + b),
        rainChance: pops.reduce((a, b) => a > b ? a : b).round(),
      ));
    }

    // Sort by date, return up to 6 days (skip today which is in current)
    days.sort((a, b) => a.date.compareTo(b.date));
    return days.take(6).toList();
  }

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------
  static WeatherResult? _loadCache(SharedPreferences prefs,
      {bool ignoreAge = false}) {
    final tsStr = prefs.getString(_cacheTimestampKey);
    if (tsStr == null) return null;

    if (!ignoreAge) {
      final ts = DateTime.parse(tsStr);
      final age = DateTime.now().difference(ts).inMinutes;
      if (age > _cacheMaxAgeMinutes) return null;
    }

    try {
      final currentJson = prefs.getString(_cacheCurrentKey);
      final forecastJson = prefs.getString(_cacheForecastKey);
      if (currentJson == null) return null;

      final current = WeatherData.fromJson(
          jsonDecode(currentJson) as Map<String, dynamic>,
          fromCache: true);

      final forecast = forecastJson != null
          ? (jsonDecode(forecastJson) as List)
              .map((e) =>
                  ForecastDay.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ForecastDay>[];

      return WeatherResult(
        current: current,
        forecast: forecast,
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(SharedPreferences prefs,
      WeatherData current, List<ForecastDay> forecast) async {
    await prefs.setString(
        _cacheCurrentKey, jsonEncode(current.toJson()));
    await prefs.setString(
        _cacheForecastKey,
        jsonEncode(forecast.map((f) => f.toJson()).toList()));
    await prefs.setString(
        _cacheTimestampKey, DateTime.now().toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // FARM ADVISORY — rule-based advice from weather conditions
  // ---------------------------------------------------------------------------
  static List<FarmAdvisory> getFarmAdvisories(WeatherData w) {
    final advisories = <FarmAdvisory>[];
    final cond = w.condition.toLowerCase();
    final desc = w.description.toLowerCase();

    // Rain advisories
    if (cond == 'rain' || cond == 'drizzle' || cond == 'thunderstorm') {
      advisories.add(const FarmAdvisory(
        icon: '🚫',
        title: 'Do not spray today',
        body:
            'Rain will wash off pesticides and fungicides. Reschedule spraying to a dry day with no rain forecast for 4+ hours.',
        color: 'error',
      ));
      if (w.rainMm1h != null && w.rainMm1h! > 10) {
        advisories.add(const FarmAdvisory(
          icon: '🌊',
          title: 'Heavy rain — check drainage',
          body:
              'Heavy rainfall can cause waterlogging. Check field drainage channels and protect seedlings from erosion.',
          color: 'warning',
        ));
      }
      advisories.add(const FarmAdvisory(
        icon: '💧',
        title: 'Skip irrigation today',
        body:
            'Natural rainfall is sufficient. Irrigating now wastes water and increases disease risk from overwatering.',
        color: 'info',
      ));
    }

    // Hot / dry conditions
    if (w.tempC > 32) {
      advisories.add(FarmAdvisory(
        icon: '☀️',
        title: 'High heat — ${w.tempDisplay}',
        body:
            'Heat stress risk for leafy vegetables. Irrigate early morning or evening. Consider shade nets above 35°C. Avoid transplanting today.',
        color: 'warning',
      ));
    }

    if (w.tempC > 35) {
      advisories.add(const FarmAdvisory(
        icon: '🌡️',
        title: 'Extreme heat — livestock alert',
        body:
            'Ensure all livestock have shade and abundant clean water. Reduce stocking density in enclosed spaces. Check for heat stress signs.',
        color: 'error',
      ));
    }

    // Good spray conditions
    if (cond == 'clear' || cond == 'clouds') {
      if (w.windSpeedKmh < 15 && w.humidity < 85) {
        advisories.add(FarmAdvisory(
          icon: '✅',
          title: 'Good conditions for spraying',
          body:
              'Wind at ${w.windDisplay} — low drift risk. Apply pesticides/fungicides early morning (before 9 AM) or late afternoon for best results.',
          color: 'success',
        ));
      }
    }

    // High wind
    if (w.windSpeedKmh > 25) {
      advisories.add(FarmAdvisory(
        icon: '💨',
        title: 'Strong winds — do not spray',
        body:
            'Wind at ${w.windDisplay}. Spraying now causes chemical drift onto non-target areas. Stakes and trellis systems may need checking.',
        color: 'warning',
      ));
    }

    // Cold / frost
    if (w.tempC < 8) {
      advisories.add(FarmAdvisory(
        icon: '🥶',
        title: 'Cold stress risk — ${w.tempDisplay}',
        body:
            'Frost risk for tomatoes, peppers, and sensitive seedlings. Cover nursery beds overnight. Delay transplanting until temperatures recover.',
        color: 'warning',
      ));
    }

    if (w.tempMinC < 2) {
      advisories.add(const FarmAdvisory(
        icon: '❄️',
        title: 'Frost likely overnight',
        body:
            'Protect sensitive crops — cover with frost cloth or plastic. Move pot plants indoors. Harvest any mature crops at risk.',
        color: 'error',
      ));
    }

    // High humidity / disease risk
    if (w.humidity > 80 && (cond == 'clouds' || cond == 'rain')) {
      advisories.add(const FarmAdvisory(
        icon: '🍄',
        title: 'High disease risk',
        body:
            'High humidity and cloud favour fungal diseases: early blight, downy mildew, Botrytis. Apply preventive fungicide (Mancozeb) if not done in last 7 days.',
        color: 'warning',
      ));
    }

    // Good planting conditions
    if (w.tempC >= 18 &&
        w.tempC <= 28 &&
        w.humidity >= 40 &&
        w.humidity <= 70 &&
        (cond == 'clouds' || cond == 'clear') &&
        w.windSpeedKmh < 20) {
      advisories.add(const FarmAdvisory(
        icon: '🌱',
        title: 'Ideal transplanting conditions',
        body:
            'Temperature, humidity, and wind are ideal for transplanting seedlings. Overcast or late afternoon planting reduces transplant shock.',
        color: 'success',
      ));
    }

    // Default — no specific advisory
    if (advisories.isEmpty) {
      advisories.add(FarmAdvisory(
        icon: '📋',
        title: 'Normal farming conditions',
        body:
            'No weather alerts today. ${w.tempDisplay}, ${w.description}. Proceed with normal farm activities.',
        color: 'info',
      ));
    }

    return advisories;
  }

  // ---------------------------------------------------------------------------
  // ZIMBABWE CITIES (for city picker)
  // ---------------------------------------------------------------------------
  static const List<String> zimbabweCities = [
    'Harare', 'Bulawayo', 'Mutare', 'Gweru', 'Kwekwe',
    'Kadoma', 'Masvingo', 'Chinhoyi', 'Marondera',
    'Norton', 'Chegutu', 'Zvishavane', 'Bindura',
    'Beitbridge', 'Hwange', 'Victoria Falls',
    'Rusape', 'Kariba', 'Chipinge', 'Chiredzi',
  ];
}

// ---------------------------------------------------------------------------
// ADVISORY MODEL
// ---------------------------------------------------------------------------
class FarmAdvisory {
  final String icon;
  final String title;
  final String body;
  final String color; // 'success' | 'warning' | 'error' | 'info'

  const FarmAdvisory({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// EXCEPTION
// ---------------------------------------------------------------------------
class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);
}