// lib/services/farm_calendar_service.dart
// Farm Calendar — task management with smart suggestions from active crops.
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

class CalendarTask {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime date;
  final String category;
  final String? linkedCrop;
  final String? linkedPlot;
  final bool isCompleted;
  final bool isSmartSuggestion;
  final String priority; // 'high' | 'medium' | 'low'
  final DateTime createdAt;

  const CalendarTask({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.category,
    this.linkedCrop,
    this.linkedPlot,
    this.isCompleted = false,
    this.isSmartSuggestion = false,
    this.priority = 'medium',
    required this.createdAt,
  });

  String get categoryEmoji {
    switch (category) {
      case 'Irrigation':   return '💧';
      case 'Spraying':     return '🧪';
      case 'Fertilizing':  return '🌱';
      case 'Harvesting':   return '🌾';
      case 'Planting':     return '🪴';
      case 'Scouting':     return '🔍';
      case 'Weeding':      return '🌿';
      case 'Maintenance':  return '🔧';
      case 'Market':       return '🏪';
      case 'Finance':      return '💰';
      case 'Livestock':    return '🐄';
      default:             return '📋';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':  return const Color(0xFFD32F2F);
      case 'low':   return const Color(0xFF388E3C);
      default:      return const Color(0xFFF57C00);
    }
  }

  bool get isOverdue =>
      !isCompleted &&
      date.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  CalendarTask copyWith({bool? isCompleted}) => CalendarTask(
        id: id,
        userId: userId,
        title: title,
        description: description,
        date: date,
        category: category,
        linkedCrop: linkedCrop,
        linkedPlot: linkedPlot,
        isCompleted: isCompleted ?? this.isCompleted,
        isSmartSuggestion: isSmartSuggestion,
        priority: priority,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'category': category,
        'linked_crop': linkedCrop,
        'linked_plot': linkedPlot,
        'is_completed': isCompleted ? 1 : 0,
        'is_smart_suggestion': isSmartSuggestion ? 1 : 0,
        'priority': priority,
        'created_at': createdAt.toIso8601String(),
      };

  factory CalendarTask.fromMap(Map<String, dynamic> m) =>
      CalendarTask(
        id: m['id'],
        userId: m['user_id'],
        title: m['title'],
        description: m['description'],
        date: DateTime.parse(m['date']),
        category: m['category'] ?? 'Other',
        linkedCrop: m['linked_crop'],
        linkedPlot: m['linked_plot'],
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        isSmartSuggestion:
            (m['is_smart_suggestion'] as int? ?? 0) == 1,
        priority: m['priority'] ?? 'medium',
        createdAt: DateTime.parse(m['created_at']),
      );
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class FarmCalendarService {
  static const List<String> categories = [
    'Irrigation',
    'Spraying',
    'Fertilizing',
    'Harvesting',
    'Planting',
    'Scouting',
    'Weeding',
    'Maintenance',
    'Market',
    'Finance',
    'Livestock',
    'Other',
  ];

  static const List<String> priorities = [
    'high',
    'medium',
    'low',
  ];

  /// Generate smart task suggestions based on active crops / plots.
  static List<CalendarTask> generateSmartSuggestions({
    required String userId,
    required List<Map<String, dynamic>> activeCrops,
    required List<Map<String, dynamic>> activePlots,
  }) {
    final suggestions = <CalendarTask>[];
    final now = DateTime.now();

    // --- Crop-based suggestions ---
    for (final crop in activeCrops) {
      final cropName = crop['crop_name'] as String? ?? '';
      final plantingDate = crop['planting_date'] != null
          ? DateTime.tryParse(crop['planting_date'])
          : null;

      if (plantingDate == null) continue;

      final daysGrowing = now.difference(plantingDate).inDays;

      // Weekly scouting reminder
      suggestions.add(CalendarTask(
        id: 'scout_${crop['id']}_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Scout $cropName for pests & disease',
        description:
            'Check leaves (top and bottom), stems, and soil. '
            'Look for unusual spots, wilting, insect damage, or webbing.',
        date: _nextOccurrence(now, DateTime.monday),
        category: 'Scouting',
        linkedCrop: cropName,
        isSmartSuggestion: true,
        priority: 'medium',
        createdAt: now,
      ));

      // Fertilizer top-dress reminder by stage
      if (daysGrowing >= 18 && daysGrowing <= 25) {
        suggestions.add(CalendarTask(
          id: 'fert1_${crop['id']}',
          userId: userId,
          title: 'Top dress $cropName — 1st application',
          description:
              'Apply CAN or AN34 at recommended rate. '
              'Broadcast between rows and water in.',
          date: now.add(const Duration(days: 2)),
          category: 'Fertilizing',
          linkedCrop: cropName,
          isSmartSuggestion: true,
          priority: 'high',
          createdAt: now,
        ));
      }

      // Irrigation reminder every 3 days
      suggestions.add(CalendarTask(
        id: 'irrig_${crop['id']}_${now.weekday}',
        userId: userId,
        title: 'Irrigate $cropName',
        description:
            'Check soil moisture first. Apply water early morning '
            'to reduce evaporation losses.',
        date: now.add(const Duration(days: 3)),
        category: 'Irrigation',
        linkedCrop: cropName,
        isSmartSuggestion: true,
        priority: 'medium',
        createdAt: now,
      ));

      // Harvest approaching
      final expectedHarvest = crop['expected_harvest_date'] != null
          ? DateTime.tryParse(crop['expected_harvest_date'])
          : null;
      if (expectedHarvest != null) {
        final daysToHarvest =
            expectedHarvest.difference(now).inDays;
        if (daysToHarvest > 0 && daysToHarvest <= 14) {
          suggestions.add(CalendarTask(
            id: 'harvest_${crop['id']}',
            userId: userId,
            title:
                'Prepare for $cropName harvest — $daysToHarvest days away',
            description:
                'Arrange transport, labour, packaging, and buyers. '
                'Check market prices now for best timing.',
            date: expectedHarvest
                .subtract(const Duration(days: 3)),
            category: 'Harvesting',
            linkedCrop: cropName,
            isSmartSuggestion: true,
            priority: 'high',
            createdAt: now,
          ));
        }
      }
    }

    // --- Horticulture plot suggestions ---
    for (final plot in activePlots) {
      final cropName = plot['crop_name'] as String? ?? '';
      final plantingDate = plot['planting_date'] != null
          ? DateTime.tryParse(plot['planting_date'])
          : null;

      if (plantingDate == null) continue;

      // Weekly spray schedule
      suggestions.add(CalendarTask(
        id: 'spray_${plot['id']}_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Spray $cropName — fungicide/pesticide',
        description:
            'Apply preventive fungicide (Mancozeb) if not done '
            'in last 7 days. Check for pest pressure first.',
        date: _nextOccurrence(now, DateTime.wednesday),
        category: 'Spraying',
        linkedCrop: cropName,
        linkedPlot: plot['id'],
        isSmartSuggestion: true,
        priority: 'medium',
        createdAt: now,
      ));

      // Harvest approaching for horti plots
      final expectedHarvest =
          plot['expected_harvest_date'] != null
              ? DateTime.tryParse(plot['expected_harvest_date'])
              : null;
      if (expectedHarvest != null) {
        final daysToHarvest =
            expectedHarvest.difference(now).inDays;
        if (daysToHarvest > 0 && daysToHarvest <= 10) {
          suggestions.add(CalendarTask(
            id: 'hortiharv_${plot['id']}',
            userId: userId,
            title: 'Harvest $cropName plot — $daysToHarvest days',
            description:
                'Grade, package, and contact buyers before harvest. '
                'Harvest early morning for best quality.',
            date: expectedHarvest,
            category: 'Harvesting',
            linkedCrop: cropName,
            linkedPlot: plot['id'],
            isSmartSuggestion: true,
            priority: 'high',
            createdAt: now,
          ));
        }
      }
    }

    // --- General weekly reminders ---
    suggestions.add(CalendarTask(
      id: 'market_check_${now.millisecondsSinceEpoch}',
      userId: userId,
      title: 'Check market prices this week',
      description:
          'Review current commodity prices in the Market Prices module. '
          'Plan selling schedule based on price trends.',
      date: _nextOccurrence(now, DateTime.friday),
      category: 'Market',
      isSmartSuggestion: true,
      priority: 'low',
      createdAt: now,
    ));

    suggestions.add(CalendarTask(
      id: 'finance_review_${now.millisecondsSinceEpoch}',
      userId: userId,
      title: 'Record this week\'s farm expenses',
      description:
          'Log inputs, labour, and other costs in the Finance module '
          'while they are fresh.',
      date: _nextOccurrence(now, DateTime.saturday),
      category: 'Finance',
      isSmartSuggestion: true,
      priority: 'low',
      createdAt: now,
    ));

    return suggestions;
  }

  /// Returns the next occurrence of a given weekday from today.
  static DateTime _nextOccurrence(DateTime from, int weekday) {
    var d = from.add(const Duration(days: 1));
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day, 7, 0);
  }
}