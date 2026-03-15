// lib/services/task_activity_database_service.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/task_activity_model.dart';

class TaskActivityDatabaseService {
  static Future<Database> get _db async => DatabaseService().database;

  // =========================================================
  // TABLE CREATION — call from database_service onCreate/onUpgrade
  // =========================================================
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        assigned_worker_id TEXT,
        assigned_worker_name TEXT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        status TEXT NOT NULL DEFAULT 'pending',
        due_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        field_or_plot TEXT,
        completion_note TEXT,
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_feed (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        type TEXT NOT NULL,
        actor_name TEXT NOT NULL,
        title TEXT NOT NULL,
        detail TEXT,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');
  }

  // =========================================================
  // TASKS — CRUD
  // =========================================================

  static Future<TaskModel> insertTask(TaskModel task) async {
    final db = await _db;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return task;
  }

  static Future<List<TaskModel>> getTasksByFarm(
    String farmId, {
    TaskStatus? filterStatus,
    String? filterWorkerId,
    int limit = 100,
  }) async {
    final db = await _db;

    String where = 'farm_id = ?';
    final args = <dynamic>[farmId];

    if (filterStatus != null) {
      where += ' AND status = ?';
      args.add(filterStatus.name);
    }
    if (filterWorkerId != null) {
      where += ' AND assigned_worker_id = ?';
      args.add(filterWorkerId);
    }

    final rows = await db.query(
      'tasks',
      where: where,
      whereArgs: args,
      orderBy: 'due_date ASC, created_at DESC',
      limit: limit,
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  static Future<List<TaskModel>> getTasksByWorker(String workerId) async {
  final db = await DatabaseService().database;
  final rows = await db.query('tasks',
    where: 'assigned_worker_id = ?',
    whereArgs: [workerId],
    orderBy: 'created_at DESC');
  return rows.map(TaskModel.fromMap).toList();
}

  static Future<TaskModel?> getTaskById(String id) async {
    final db = await _db;
    final rows =
        await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : TaskModel.fromMap(rows.first);
  }

  static Future<void> updateTaskStatus(
    String taskId,
    TaskStatus status, {
    String? completionNote,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'status': status.name};

    if (status == TaskStatus.inProgress) updates['started_at'] = now;
    if (status == TaskStatus.completed) {
      updates['completed_at'] = now;
      if (completionNote != null) updates['completion_note'] = completionNote;
    }

    await db.update('tasks', updates,
        where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> updateTask(TaskModel task) async {
    final db = await _db;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  static Future<void> deleteTask(String taskId) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  /// Summary counts by status for a farm
  static Future<Map<String, int>> getTaskSummary(String farmId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      WHERE farm_id = ?
      GROUP BY status
    ''', [farmId]);

    final summary = <String, int>{
      'pending': 0,
      'inProgress': 0,
      'completed': 0,
      'cancelled': 0,
    };
    for (final row in rows) {
      summary[row['status'] as String] = row['count'] as int;
    }
    return summary;
  }

  // =========================================================
  // ACTIVITY FEED
  // =========================================================

  static Future<void> logActivity(ActivityItem item) async {
    final db = await _db;
    await db.insert('activity_feed', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ActivityItem>> getActivityFeed(
    String farmId, {
    int limit = 60,
    ActivityType? filterType,
  }) async {
    final db = await _db;

    String where = 'farm_id = ?';
    final args = <dynamic>[farmId];

    if (filterType != null) {
      where += ' AND type = ?';
      args.add(filterType.name);
    }

    final rows = await db.query(
      'activity_feed',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(ActivityItem.fromMap).toList();
  }

  static Future<void> clearOldActivity(
      String farmId, int keepDays) async {
    final db = await _db;
    final cutoff = DateTime.now()
        .subtract(Duration(days: keepDays))
        .toIso8601String();
    await db.delete(
      'activity_feed',
      where: 'farm_id = ? AND created_at < ?',
      whereArgs: [farmId, cutoff],
    );
  }
}