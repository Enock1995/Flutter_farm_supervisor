// lib/providers/weather_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherResult? _result;
  bool _isLoading = false;
  String _city = 'Harare'; // fallback only

  WeatherResult? get result => _result;
  bool get isLoading => _isLoading;
  String get city => _city;
  WeatherData? get current => _result?.current;
  List<ForecastDay> get forecast => _result?.forecast ?? [];
  bool get hasData => _result?.hasData ?? false;
  String? get error => _result?.error;
  bool get isFromCache => _result?.isFromCache ?? false;

  /// Call this from WeatherScreen, passing the user's registered district.
  /// If the user has previously manually selected a city, that takes priority.
  Future<void> init({String? userDistrict}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has ever manually picked a city
    final savedCity = prefs.getString('weather_city');

    if (savedCity != null) {
      // User manually chose a city before — respect that choice
      _city = savedCity;
    } else if (userDistrict != null && userDistrict.isNotEmpty) {
      // First launch — use farmer's registered district
      _city = _mapDistrictToCity(userDistrict);
    }
    // else: keep 'Harare' as last resort fallback

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

  /// Maps a Zimbabwe district name to the nearest OWM-recognised city.
  /// OWM knows major towns — we map rural districts to their nearest town.
  static String _mapDistrictToCity(String district) {
    final d = district.toLowerCase().trim();

    // Direct city matches
    const directCities = {
      'harare', 'bulawayo', 'mutare', 'gweru', 'kwekwe',
      'kadoma', 'masvingo', 'chinhoyi', 'marondera',
      'norton', 'chegutu', 'zvishavane', 'bindura',
      'beitbridge', 'hwange', 'kariba', 'rusape',
      'chipinge', 'chiredzi', 'victoria falls',
    };
    if (directCities.contains(d)) {
      // Capitalise properly
      return district
          .split(' ')
          .map((w) => w.isEmpty
              ? w
              : w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }

    // District → nearest major city mapping
    const Map<String, String> districtToCity = {
      // Harare Province
      'harare urban': 'Harare',
      'harare rural': 'Harare',
      'chitungwiza': 'Harare',
      'epworth': 'Harare',

      // Mashonaland East
      'marondera': 'Marondera',
      'murehwa': 'Marondera',
      'mudzi': 'Marondera',
      'mutoko': 'Marondera',
      'goromonzi': 'Harare',
      'seke': 'Harare',
      'wedza': 'Marondera',
      'chikomba': 'Marondera',
      'uzumba maramba pfungwe': 'Marondera',

      // Mashonaland West
      'chinhoyi': 'Chinhoyi',
      'makonde': 'Chinhoyi',
      'hurungwe': 'Kariba',
      'kariba': 'Kariba',
      'zvimba': 'Chinhoyi',
      'chegutu': 'Chegutu',
      'mhondoro-ngezi': 'Kadoma',
      'kadoma': 'Kadoma',
      'sanyati': 'Kadoma',

      // Mashonaland Central
      'bindura': 'Bindura',
      'shamva': 'Bindura',
      'mazowe': 'Bindura',
      'mt darwin': 'Bindura',
      'mount darwin': 'Bindura',
      'centenary': 'Bindura',
      'guruve': 'Bindura',
      'rushinga': 'Bindura',
      'muzarabani': 'Bindura',

      // Manicaland
      'mutare': 'Mutare',
      'makoni': 'Rusape',
      'rusape': 'Rusape',
      'chipinge': 'Chipinge',
      'chimanimani': 'Chipinge',
      'buhera': 'Mutare',
      'nyanga': 'Mutare',
      'mutasa': 'Mutare',

      // Masvingo
      'masvingo': 'Masvingo',
      'chiredzi': 'Chiredzi',
      'mwenezi': 'Masvingo',
      'gutu': 'Masvingo',
      'zaka': 'Masvingo',
      'bikita': 'Masvingo',
      'chivi': 'Masvingo',

      // Midlands
      'gweru': 'Gweru',
      'kwekwe': 'Kwekwe',
      'zvishavane': 'Zvishavane',
      'shurugwi': 'Gweru',
      'gokwe north': 'Kwekwe',
      'gokwe south': 'Kwekwe',
      'mberengwa': 'Zvishavane',
      'chirumanzu': 'Gweru',
      'lower gweru': 'Gweru',
      'vungu': 'Gweru',

      // Matabeleland North
      'bulawayo': 'Bulawayo',
      'hwange': 'Hwange',
      'lupane': 'Hwange',
      'nkayi': 'Hwange',
      'binga': 'Kariba',
      'tsholotsho': 'Bulawayo',
      'umguza': 'Bulawayo',
      'victoria falls': 'Victoria Falls',

      // Matabeleland South
      'beitbridge': 'Beitbridge',
      'gwanda': 'Beitbridge',
      'insiza': 'Bulawayo',
      'matobo': 'Bulawayo',
      'umzingwane': 'Bulawayo',
      'bulilima': 'Bulawayo',
      'mangwe': 'Bulawayo',
    };

    return districtToCity[d] ?? 'Harare';
  }
}