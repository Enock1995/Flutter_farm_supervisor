// lib/services/ai_service.dart
// Developed by Sir Enocks — Cor Technologies
// Handles all Claude AI API calls for farm_supervisor premium features

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-opus-4-5';
  static const String _apiVersion = '2023-06-01';

  // ── Shared headers ──────────────────────────────────────
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': AppConfig.claudeApiKey,
        'anthropic-version': _apiVersion,
      };

  // =========================================================
  // 1. CROP & LIVESTOCK DIAGNOSIS
  // =========================================================
  static Future<DiagnosisResult> diagnose({
    required String symptoms,
    required String subjectType,
    String? cropOrAnimalName,
    File? photo,
  }) async {
    final subject = cropOrAnimalName != null
        ? '$subjectType ($cropOrAnimalName)'
        : subjectType;

    final List<Map<String, dynamic>> contentBlocks = [];

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(photo.path);
      contentBlocks.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mimeType,
          'data': base64Image,
        },
      });
    }

    contentBlocks.add({
      'type': 'text',
      'text': '''You are an expert agricultural diagnostic advisor for Zimbabwe.
A farmer reports the following symptoms for their $subject:

"$symptoms"

${photo != null ? 'I have also attached a photo of the affected ${subjectType == 'crop' ? 'plant/field' : 'animal'}.' : ''}

Respond ONLY with a valid JSON object in this exact format (no markdown, no preamble):
{
  "diagnosis": "Most likely condition name",
  "confidence": "High / Medium / Low",
  "severity": "Mild / Moderate / Severe / Critical",
  "description": "2-3 sentence explanation of what this condition is",
  "treatment": ["Step 1", "Step 2", "Step 3"],
  "prevention": ["Tip 1", "Tip 2", "Tip 3"],
  "local_products": "Mention any locally available treatments in Zimbabwe if known",
  "see_expert": true or false
}''',
    });

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1000,
      'messages': [
        {'role': 'user', 'content': contentBlocks}
      ],
    });

    final response = await http
        .post(Uri.parse(_apiUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiException('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'] as List)
        .firstWhere((b) => b['type'] == 'text')['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(clean) as Map<String, dynamic>;
    return DiagnosisResult.fromJson(json);
  }

  // =========================================================
  // 2. YIELD PREDICTION
  // =========================================================
  static Future<YieldResult> predictYield({
    required String cropType,
    required double fieldSizeHa,
    required String soilType,
    required double rainfallMm,
    required String fertilizerUsed,
    required String agroRegion,
  }) async {
    final prompt = '''You are an expert agronomist for Zimbabwe.
A farmer provides the following data for yield prediction:

- Crop: $cropType
- Field size: ${fieldSizeHa}ha
- Soil type: $soilType
- Rainfall this season: ${rainfallMm}mm
- Fertilizer used: $fertilizerUsed
- Agro-ecological region: $agroRegion

Respond ONLY with a valid JSON object (no markdown, no preamble):
{
  "predicted_yield_tonnes_per_ha": 2.4,
  "total_predicted_tonnes": 4.8,
  "confidence": "Medium",
  "zim_regional_average_tonnes_per_ha": 1.8,
  "comparison": "above average / below average / average",
  "comparison_percent": 33,
  "limiting_factors": ["Factor 1", "Factor 2"],
  "recommendations": ["Action 1", "Action 2", "Action 3"],
  "expected_harvest_window": "April – May 2025"
}''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 800,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    });

    final response = await http
        .post(Uri.parse(_apiUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiException('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'] as List)
        .firstWhere((b) => b['type'] == 'text')['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(clean) as Map<String, dynamic>;
    return YieldResult.fromJson(json);
  }

  // =========================================================
  // 3. FARM ADVISORY CHAT
  // =========================================================
  static Future<String> chat({
    required List<Map<String, String>> history,
    required String userMessage,
    String? agroRegion,
  }) async {
    final messages = [
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': userMessage},
    ];

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 800,
      'system':
          'You are an expert agricultural advisor for Zimbabwe. '
          'Give practical, locally-relevant farming advice. '
          'Consider Zimbabwe\'s agro-ecological regions, local crop varieties, '
          'EcoCash-accessible inputs, AGRITEX guidelines, and seasonal patterns. '
          '${agroRegion != null ? 'This farmer is in agro-ecological region $agroRegion.' : ''}'
          'Be concise, friendly, and use simple language. '
          'When recommending products, mention ones available in Zimbabwe.',
      'messages': messages,
    });

    final response = await http
        .post(Uri.parse(_apiUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiException('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return (data['content'] as List)
        .firstWhere((b) => b['type'] == 'text')['text'] as String;
  }

  // =========================================================
  // 4. HYPERLOCAL WEATHER AI ADVISORY  (NEW — Premium)
  // =========================================================
  /// Analyses current weather + 5-day forecast and produces a structured
  /// farming action plan for the next 7 days.
  static Future<WeatherAiAdvisory> weatherAiAdvisory({
    required String cityName,
    required double tempC,
    required double humidity,
    required double windSpeedKmh,
    required double rainMm,
    required String condition,
    required String district,
    required String agroRegion,
    required List<Map<String, dynamic>> forecastSummary,
  }) async {
    final forecastText = forecastSummary
        .map((d) =>
            '${d['day']}: ${d['condition']}, max ${d['max']}°C, '
            'min ${d['min']}°C, rain chance ${d['rain']}%')
        .join('\n');

    final prompt = '''You are an expert agricultural advisor for Zimbabwe.
Analyse this hyperlocal weather data and provide a comprehensive farming action plan.

CURRENT CONDITIONS — $cityName ($district, Region $agroRegion):
- Temperature: ${tempC.toStringAsFixed(1)}°C
- Humidity: $humidity%
- Wind: ${windSpeedKmh.toStringAsFixed(1)} km/h
- Rainfall (last 1h): ${rainMm.toStringAsFixed(1)} mm
- Condition: $condition

5-DAY FORECAST:
$forecastText

Respond ONLY with a valid JSON object (no markdown, no preamble):
{
  "overall_risk": "Low / Medium / High / Critical",
  "summary": "2-sentence overall weather assessment for farmers",
  "alerts": [
    {
      "type": "heat_stress / frost / heavy_rain / drought / strong_wind / disease_risk / spray_window",
      "severity": "Low / Medium / High / Critical",
      "title": "Short alert title",
      "message": "1-2 sentence actionable message",
      "icon": "🌡️ or ❄️ or 🌧️ or 🏜️ or 💨 or 🍄 or 🚿"
    }
  ],
  "spray_days": ["Mon", "Wed"],
  "irrigation_advice": "1 sentence on whether to irrigate today and how much",
  "planting_advice": "1 sentence on whether conditions are good for planting",
  "harvest_advice": "1 sentence on harvesting conditions",
  "this_week_plan": [
    {"day": "Monday", "priority": "High / Medium / Low", "action": "What to do"}
  ],
  "disease_pressure": "Low / Medium / High",
  "disease_risk_crops": ["Maize downy mildew risk", "Tomato blight risk"]
}''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1200,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    });

    final response = await http
        .post(Uri.parse(_apiUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw AiException('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'] as List)
        .firstWhere((b) => b['type'] == 'text')['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(clean) as Map<String, dynamic>;
    return WeatherAiAdvisory.fromJson(json);
  }

  // =========================================================
  // 5. IRRIGATION AI SCHEDULE  (NEW — Premium)
  // =========================================================
  /// Generates an optimised irrigation schedule for all active plots
  /// based on crops, growth stages, and current weather.
  static Future<IrrigationAiSchedule> irrigationAiSchedule({
    required List<Map<String, dynamic>> plots,
    required double currentTempC,
    required double humidity,
    required double rainMmToday,
    required double etoMmDay,
    required String condition,
    required List<Map<String, dynamic>> forecastSummary,
    required String district,
  }) async {
    final plotsText = plots
        .map((p) =>
            '- ${p['name']} (${p['area']}ha): crop=${p['crop'] ?? 'unset'}, '
            'stage=${p['stage'] ?? 'unknown'}, system=${p['system']}, '
            'last irrigated=${p['last_irrigated'] ?? 'never'}')
        .join('\n');

    final forecastText = forecastSummary
        .map((d) =>
            '${d['day']}: ${d['condition']}, max ${d['max']}°C, '
            'rain chance ${d['rain']}%')
        .join('\n');

    final prompt = '''You are an expert irrigation agronomist for Zimbabwe.
Generate an optimised 7-day irrigation schedule for these farm plots.

CURRENT WEATHER — $district:
- Temperature: ${currentTempC.toStringAsFixed(1)}°C
- Humidity: $humidity%
- Rain today: ${rainMmToday.toStringAsFixed(1)} mm
- ETo estimate: ${etoMmDay.toStringAsFixed(1)} mm/day
- Condition: $condition

7-DAY FORECAST:
$forecastText

FARM PLOTS:
$plotsText

Consider: FAO-56 Kc values, growth stage water demand, rainfall reducing irrigation need,
heat stress increasing demand, Zimbabwe seasonal patterns.

Respond ONLY with a valid JSON object (no markdown, no preamble):
{
  "summary": "1-2 sentence overall irrigation assessment",
  "eto_adjusted": 5.2,
  "schedule": [
    {
      "plot_name": "Block A Tomatoes",
      "crop": "Tomatoes",
      "stage": "Flowering",
      "irrigate_today": true,
      "next_irrigation_date": "2025-03-20",
      "frequency_days": 2,
      "water_mm_per_event": 28.5,
      "reason": "Why this schedule was chosen",
      "priority": "High / Medium / Low",
      "alert": "Any special note or warning"
    }
  ],
  "rain_benefit": "How much natural rainfall offsets irrigation this week",
  "water_saving_tip": "1 practical tip to save water this week",
  "best_time_to_irrigate": "Early morning (5–7am) — reason"
}''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1200,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    });

    final response = await http
        .post(Uri.parse(_apiUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw AiException('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'] as List)
        .firstWhere((b) => b['type'] == 'text')['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(clean) as Map<String, dynamic>;
    return IrrigationAiSchedule.fromJson(json);
  }

  // ── Helper ──────────────────────────────────────────────
  static String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

// =========================================================
// EXISTING RESULT MODELS — unchanged
// =========================================================

class DiagnosisResult {
  final String diagnosis;
  final String confidence;
  final String severity;
  final String description;
  final List<String> treatment;
  final List<String> prevention;
  final String localProducts;
  final bool seeExpert;

  const DiagnosisResult({
    required this.diagnosis,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.treatment,
    required this.prevention,
    required this.localProducts,
    required this.seeExpert,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> j) => DiagnosisResult(
        diagnosis: j['diagnosis'] ?? '',
        confidence: j['confidence'] ?? 'Medium',
        severity: j['severity'] ?? 'Unknown',
        description: j['description'] ?? '',
        treatment: List<String>.from(j['treatment'] ?? []),
        prevention: List<String>.from(j['prevention'] ?? []),
        localProducts: j['local_products'] ?? '',
        seeExpert: j['see_expert'] == true,
      );

  Map<String, dynamic> toMap() => {
        'diagnosis': diagnosis,
        'confidence': confidence,
        'severity': severity,
        'description': description,
        'treatment': jsonEncode(treatment),
        'prevention': jsonEncode(prevention),
        'local_products': localProducts,
        'see_expert': seeExpert ? 1 : 0,
      };
}

class YieldResult {
  final double predictedYieldPerHa;
  final double totalPredictedTonnes;
  final String confidence;
  final double zimAveragePerHa;
  final String comparison;
  final int comparisonPercent;
  final List<String> limitingFactors;
  final List<String> recommendations;
  final String harvestWindow;

  const YieldResult({
    required this.predictedYieldPerHa,
    required this.totalPredictedTonnes,
    required this.confidence,
    required this.zimAveragePerHa,
    required this.comparison,
    required this.comparisonPercent,
    required this.limitingFactors,
    required this.recommendations,
    required this.harvestWindow,
  });

  factory YieldResult.fromJson(Map<String, dynamic> j) => YieldResult(
        predictedYieldPerHa:
            (j['predicted_yield_tonnes_per_ha'] ?? 0).toDouble(),
        totalPredictedTonnes:
            (j['total_predicted_tonnes'] ?? 0).toDouble(),
        confidence: j['confidence'] ?? 'Medium',
        zimAveragePerHa:
            (j['zim_regional_average_tonnes_per_ha'] ?? 0).toDouble(),
        comparison: j['comparison'] ?? 'average',
        comparisonPercent: (j['comparison_percent'] ?? 0).toInt(),
        limitingFactors: List<String>.from(j['limiting_factors'] ?? []),
        recommendations: List<String>.from(j['recommendations'] ?? []),
        harvestWindow: j['expected_harvest_window'] ?? '',
      );
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => 'AiException: $message';
}

// =========================================================
// NEW RESULT MODELS — Weather AI Advisory
// =========================================================

class WeatherAlert {
  final String type;
  final String severity;
  final String title;
  final String message;
  final String icon;

  const WeatherAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.icon,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> j) => WeatherAlert(
        type: j['type'] ?? '',
        severity: j['severity'] ?? 'Low',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        icon: j['icon'] ?? '⚠️',
      );

  Color get severityColor {
    switch (severity) {
      case 'Critical': return const Color(0xFFC62828);
      case 'High':     return const Color(0xFFE65100);
      case 'Medium':   return const Color(0xFFF9A825);
      default:         return const Color(0xFF1E88E5);
    }
  }
}

class DayPlan {
  final String day;
  final String priority;
  final String action;

  const DayPlan({
    required this.day,
    required this.priority,
    required this.action,
  });

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        day: j['day'] ?? '',
        priority: j['priority'] ?? 'Medium',
        action: j['action'] ?? '',
      );
}

class WeatherAiAdvisory {
  final String overallRisk;
  final String summary;
  final List<WeatherAlert> alerts;
  final List<String> sprayDays;
  final String irrigationAdvice;
  final String plantingAdvice;
  final String harvestAdvice;
  final List<DayPlan> thisWeekPlan;
  final String diseasePressure;
  final List<String> diseaseRiskCrops;

  const WeatherAiAdvisory({
    required this.overallRisk,
    required this.summary,
    required this.alerts,
    required this.sprayDays,
    required this.irrigationAdvice,
    required this.plantingAdvice,
    required this.harvestAdvice,
    required this.thisWeekPlan,
    required this.diseasePressure,
    required this.diseaseRiskCrops,
  });

  factory WeatherAiAdvisory.fromJson(Map<String, dynamic> j) =>
      WeatherAiAdvisory(
        overallRisk: j['overall_risk'] ?? 'Low',
        summary: j['summary'] ?? '',
        alerts: (j['alerts'] as List? ?? [])
            .map((a) => WeatherAlert.fromJson(a))
            .toList(),
        sprayDays: List<String>.from(j['spray_days'] ?? []),
        irrigationAdvice: j['irrigation_advice'] ?? '',
        plantingAdvice: j['planting_advice'] ?? '',
        harvestAdvice: j['harvest_advice'] ?? '',
        thisWeekPlan: (j['this_week_plan'] as List? ?? [])
            .map((d) => DayPlan.fromJson(d))
            .toList(),
        diseasePressure: j['disease_pressure'] ?? 'Low',
        diseaseRiskCrops:
            List<String>.from(j['disease_risk_crops'] ?? []),
      );
}

// =========================================================
// NEW RESULT MODELS — Irrigation AI Schedule
// =========================================================

class PlotSchedule {
  final String plotName;
  final String crop;
  final String stage;
  final bool irrigateToday;
  final String nextIrrigationDate;
  final int frequencyDays;
  final double waterMmPerEvent;
  final String reason;
  final String priority;
  final String alert;

  const PlotSchedule({
    required this.plotName,
    required this.crop,
    required this.stage,
    required this.irrigateToday,
    required this.nextIrrigationDate,
    required this.frequencyDays,
    required this.waterMmPerEvent,
    required this.reason,
    required this.priority,
    required this.alert,
  });

  factory PlotSchedule.fromJson(Map<String, dynamic> j) => PlotSchedule(
        plotName: j['plot_name'] ?? '',
        crop: j['crop'] ?? '',
        stage: j['stage'] ?? '',
        irrigateToday: j['irrigate_today'] == true,
        nextIrrigationDate: j['next_irrigation_date'] ?? '',
        frequencyDays: (j['frequency_days'] ?? 3).toInt(),
        waterMmPerEvent: (j['water_mm_per_event'] ?? 0).toDouble(),
        reason: j['reason'] ?? '',
        priority: j['priority'] ?? 'Medium',
        alert: j['alert'] ?? '',
      );
}

class IrrigationAiSchedule {
  final String summary;
  final double etoAdjusted;
  final List<PlotSchedule> schedule;
  final String rainBenefit;
  final String waterSavingTip;
  final String bestTimeToIrrigate;

  const IrrigationAiSchedule({
    required this.summary,
    required this.etoAdjusted,
    required this.schedule,
    required this.rainBenefit,
    required this.waterSavingTip,
    required this.bestTimeToIrrigate,
  });

  factory IrrigationAiSchedule.fromJson(Map<String, dynamic> j) =>
      IrrigationAiSchedule(
        summary: j['summary'] ?? '',
        etoAdjusted: (j['eto_adjusted'] ?? 0).toDouble(),
        schedule: (j['schedule'] as List? ?? [])
            .map((s) => PlotSchedule.fromJson(s))
            .toList(),
        rainBenefit: j['rain_benefit'] ?? '',
        waterSavingTip: j['water_saving_tip'] ?? '',
        bestTimeToIrrigate: j['best_time_to_irrigate'] ?? '',
      );
}