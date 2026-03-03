// lib/providers/farm_calendar_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/farm_calendar_service.dart';

class FarmCalendarProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<CalendarTask> _tasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime _focusedMonth = DateTime.now();

  List<CalendarTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get focusedMonth => _focusedMonth;

  // ---------------------------------------------------------------------------
  // FILTERED VIEWS
  // ---------------------------------------------------------------------------

  List<CalendarTask> tasksForDay(DateTime day) => _tasks
      .where((t) =>
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<CalendarTask> tasksForMonth(DateTime month) => _tasks
      .where((t) =>
          t.date.year == month.year &&
          t.date.month == month.month)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<CalendarTask> get upcomingTasks => _tasks
      .where((t) =>
          !t.isCompleted &&
          (t.date.isAfter(DateTime.now()) || t.isToday))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<CalendarTask> get overdueTasks => _tasks
      .where((t) => t.isOverdue)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<CalendarTask> get todayTasks => _tasks
      .where((t) => t.isToday)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  int get todayCount => todayTasks.length;
  int get overdueCount => overdueTasks.length;
  int get upcomingCount => upcomingTasks.length;

  /// Days in the focused month that have tasks
  Set<int> get daysWithTasks => tasksForMonth(_focusedMonth)
      .map((t) => t.date.day)
      .toSet();

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DB SETUP & LOAD
  // ---------------------------------------------------------------------------

  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS farm_calendar_tasks (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'Other',
          linked_crop TEXT,
          linked_plot TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          is_smart_suggestion INTEGER NOT NULL DEFAULT 0,
          priority TEXT NOT NULL DEFAULT 'medium',
          created_at TEXT NOT NULL
        )
      ''');
      final maps = await db.query(
        'farm_calendar_tasks',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date ASC',
      );
      _tasks = maps.map(CalendarTask.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // SMART SUGGESTIONS
  // ---------------------------------------------------------------------------

  Future<void> loadSmartSuggestions({
    required String userId,
    required List<Map<String, dynamic>> activeCrops,
    required List<Map<String, dynamic>> activePlots,
  }) async {
    // Remove old smart suggestions that are not yet completed
    _tasks.removeWhere(
        (t) => t.isSmartSuggestion && !t.isCompleted);

    final suggestions =
        FarmCalendarService.generateSmartSuggestions(
      userId: userId,
      activeCrops: activeCrops,
      activePlots: activePlots,
    );

    // Add new suggestions to memory only (don't persist to DB —
    // they regenerate fresh each session)
    _tasks.addAll(suggestions);
    _tasks.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<CalendarTask?> addTask({
    required String userId,
    required String title,
    String? description,
    required DateTime date,
    required String category,
    String? linkedCrop,
    String? linkedPlot,
    String priority = 'medium',
  }) async {
    try {
      final db = await _db.database;
      final id =
          'task_${DateTime.now().millisecondsSinceEpoch}';
      final task = CalendarTask(
        id: id,
        userId: userId,
        title: title,
        description: description,
        date: date,
        category: category,
        linkedCrop: linkedCrop,
        linkedPlot: linkedPlot,
        priority: priority,
        createdAt: DateTime.now(),
      );
      await db.insert('farm_calendar_tasks', task.toMap());
      _tasks.add(task);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final task = _tasks[idx];
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    _tasks[idx] = updated;
    notifyListeners();

    // Only persist real tasks (not in-memory smart suggestions)
    if (!task.isSmartSuggestion) {
      try {
        final db = await _db.database;
        await db.update(
          'farm_calendar_tasks',
          {'is_completed': updated.isCompleted ? 1 : 0},
          where: 'id = ?',
          whereArgs: [taskId],
        );
      } catch (e) {
        _error = e.toString();
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId,
        orElse: () => _tasks.first);

    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();

    if (!task.isSmartSuggestion) {
      try {
        final db = await _db.database;
        await db.delete('farm_calendar_tasks',
            where: 'id = ?', whereArgs: [taskId]);
      } catch (e) {
        _error = e.toString();
      }
    }
  }
}