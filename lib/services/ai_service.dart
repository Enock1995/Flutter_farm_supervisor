// lib/services/ai_service.dart
// Developed by Sir Enocks — Cor Technologies
// Handles all Claude AI API calls for farm_supervisor premium features

import 'dart:convert';
import 'dart:io';
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
  /// Sends symptom text and optional base64 image to Claude.
  /// Returns a structured DiagnosisResult.
  static Future<DiagnosisResult> diagnose({
    required String symptoms,
    required String subjectType, // 'crop' or 'livestock'
    String? cropOrAnimalName,
    File? photo,
  }) async {
    final subject = cropOrAnimalName != null
        ? '$subjectType ($cropOrAnimalName)'
        : subjectType;

    final List<Map<String, dynamic>> contentBlocks = [];

    // Add photo block first if provided
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

    // Add text prompt
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

    // Strip any accidental markdown fences
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
    // Build messages array from history + new message
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
// RESULT MODELS
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