// lib/providers/ai_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/ai_database_service.dart';

// ── Diagnosis state ──────────────────────────────────────
enum AiState { idle, loading, success, error }

class AiProvider extends ChangeNotifier {
  // ── Shared ───────────────────────────────────────────────
  AiState _state = AiState.idle;
  String _errorMessage = '';
  AiState get state => _state;
  String get errorMessage => _errorMessage;

  // ── Diagnosis ────────────────────────────────────────────
  DiagnosisResult? _diagnosisResult;
  List<Map<String, dynamic>> _diagnosisHistory = [];
  DiagnosisResult? get diagnosisResult => _diagnosisResult;
  List<Map<String, dynamic>> get diagnosisHistory => _diagnosisHistory;

  Future<void> runDiagnosis({
    required String userId,
    required String symptoms,
    required String subjectType,
    String? cropOrAnimalName,
    File? photo,
  }) async {
    _state = AiState.loading;
    _diagnosisResult = null;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await AiService.diagnose(
        symptoms: symptoms,
        subjectType: subjectType,
        cropOrAnimalName: cropOrAnimalName,
        photo: photo,
      );
      _diagnosisResult = result;

      // Save to SQLite
      await AiDatabaseService.saveDiagnosis(
        userId: userId,
        symptoms: symptoms,
        subjectType: subjectType,
        cropOrAnimalName: cropOrAnimalName ?? '',
        result: result,
      );

      _state = AiState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('AiException: ', '');
      _state = AiState.error;
    }
    notifyListeners();
  }

  Future<void> loadDiagnosisHistory(String userId) async {
    _diagnosisHistory = await AiDatabaseService.getDiagnosisHistory(userId);
    notifyListeners();
  }

  // ── Yield Prediction ─────────────────────────────────────
  YieldResult? _yieldResult;
  List<Map<String, dynamic>> _yieldHistory = [];
  YieldResult? get yieldResult => _yieldResult;
  List<Map<String, dynamic>> get yieldHistory => _yieldHistory;

  Future<void> predictYield({
    required String userId,
    required String cropType,
    required double fieldSizeHa,
    required String soilType,
    required double rainfallMm,
    required String fertilizerUsed,
    required String agroRegion,
  }) async {
    _state = AiState.loading;
    _yieldResult = null;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await AiService.predictYield(
        cropType: cropType,
        fieldSizeHa: fieldSizeHa,
        soilType: soilType,
        rainfallMm: rainfallMm,
        fertilizerUsed: fertilizerUsed,
        agroRegion: agroRegion,
      );
      _yieldResult = result;

      await AiDatabaseService.saveYieldPrediction(
        userId: userId,
        cropType: cropType,
        fieldSizeHa: fieldSizeHa,
        result: result,
      );

      _state = AiState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('AiException: ', '');
      _state = AiState.error;
    }
    notifyListeners();
  }

  Future<void> loadYieldHistory(String userId) async {
    _yieldHistory = await AiDatabaseService.getYieldHistory(userId);
    notifyListeners();
  }

  // ── Chat ─────────────────────────────────────────────────
  List<ChatMessage> _chatMessages = [];
  bool _chatLoading = false;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get chatLoading => _chatLoading;

  Future<void> loadChatHistory(String userId) async {
    final rows = await AiDatabaseService.getChatHistory(userId);
    _chatMessages = rows
        .map((r) => ChatMessage(
              role: r['role'] as String,
              content: r['content'] as String,
              timestamp: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
    notifyListeners();
  }

  Future<void> sendChatMessage({
    required String userId,
    required String message,
    String? agroRegion,
  }) async {
    // Add user message immediately
    final userMsg = ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    _chatLoading = true;
    notifyListeners();

    try {
      // Build history for API (last 20 messages to stay within context)
      final history = _chatMessages
          .take(_chatMessages.length - 1)
          .takeLast(20)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await AiService.chat(
        history: history,
        userMessage: message,
        agroRegion: agroRegion,
      );

      final assistantMsg = ChatMessage(
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );
      _chatMessages.add(assistantMsg);

      // Persist both to SQLite
      await AiDatabaseService.saveChatMessage(
          userId: userId, role: 'user', content: message);
      await AiDatabaseService.saveChatMessage(
          userId: userId, role: 'assistant', content: reply);
    } catch (e) {
      _chatMessages.add(ChatMessage(
        role: 'assistant',
        content:
            '⚠️ Sorry, I could not connect to the AI advisor. Please check your internet connection and try again.',
        timestamp: DateTime.now(),
        isError: true,
      ));
    }

    _chatLoading = false;
    notifyListeners();
  }

  Future<void> clearChatHistory(String userId) async {
    await AiDatabaseService.clearChatHistory(userId);
    _chatMessages = [];
    notifyListeners();
  }

  void resetDiagnosis() {
    _diagnosisResult = null;
    _state = AiState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void resetYield() {
    _yieldResult = null;
    _state = AiState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}

// ── Chat message model ────────────────────────────────────
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == 'user';
}

// Extension for takeLast
extension TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    return list.length <= n ? list : list.sublist(list.length - n);
  }
}