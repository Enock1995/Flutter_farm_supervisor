// lib/services/ai_database_service.dart
// Developed by Sir Enocks — Cor Technologies
// Handles all SQLite operations for the 3 AI premium screens

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'ai_service.dart';

class AiDatabaseService {
  static Future<Database> get _db async =>
      DatabaseService().database;

  // =========================================================
  // DIAGNOSIS
  // =========================================================
  static Future<void> saveDiagnosis({
    required String userId,
    required String symptoms,
    required String subjectType,
    required String cropOrAnimalName,
    required DiagnosisResult result,
  }) async {
    final db = await _db;
    await db.insert(
      'ai_diagnosis_history',
      {
        'id': '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'subject_type': subjectType,
        'crop_or_animal': cropOrAnimalName,
        'symptoms': symptoms,
        'diagnosis': result.diagnosis,
        'confidence': result.confidence,
        'severity': result.severity,
        'description': result.description,
        'treatment': jsonEncode(result.treatment),
        'prevention': jsonEncode(result.prevention),
        'local_products': result.localProducts,
        'see_expert': result.seeExpert ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getDiagnosisHistory(
      String userId) async {
    final db = await _db;
    return db.query(
      'ai_diagnosis_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 50,
    );
  }

  // =========================================================
  // YIELD PREDICTION
  // =========================================================
  static Future<void> saveYieldPrediction({
    required String userId,
    required String cropType,
    required double fieldSizeHa,
    required YieldResult result,
  }) async {
    final db = await _db;
    await db.insert(
      'ai_yield_history',
      {
        'id': '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'crop_type': cropType,
        'field_size_ha': fieldSizeHa,
        'predicted_yield_per_ha': result.predictedYieldPerHa,
        'total_predicted_tonnes': result.totalPredictedTonnes,
        'confidence': result.confidence,
        'zim_average_per_ha': result.zimAveragePerHa,
        'comparison': result.comparison,
        'comparison_percent': result.comparisonPercent,
        'limiting_factors': jsonEncode(result.limitingFactors),
        'recommendations': jsonEncode(result.recommendations),
        'harvest_window': result.harvestWindow,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getYieldHistory(
      String userId) async {
    final db = await _db;
    return db.query(
      'ai_yield_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 30,
    );
  }

  // =========================================================
  // CHAT
  // =========================================================
  static Future<void> saveChatMessage({
    required String userId,
    required String role,
    required String content,
  }) async {
    final db = await _db;
    await db.insert('ai_chat_history', {
      'id': '${userId}_${role}_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(
      String userId) async {
    final db = await _db;
    return db.query(
      'ai_chat_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  static Future<void> clearChatHistory(String userId) async {
    final db = await _db;
    await db.delete('ai_chat_history',
        where: 'user_id = ?', whereArgs: [userId]);
  }
}