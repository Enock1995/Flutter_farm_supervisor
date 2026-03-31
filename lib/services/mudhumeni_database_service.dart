// lib/services/mudhumeni_database_service.dart
// Developed by Sir Enocks Cor Technologies

import '../models/mudhumeni_model.dart';
import 'database_service.dart';

class MudhumeniDatabaseService {
  // ── Create all tables ─────────────────────────────────
  static Future<void> createTables(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mudhumeni_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        employee_id TEXT NOT NULL,
        ward TEXT NOT NULL,
        district TEXT NOT NULL,
        id_photo_path TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        ward TEXT NOT NULL,
        district TEXT NOT NULL,
        post_type TEXT DEFAULT 'tip',
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        photo_path TEXT DEFAULT '',
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS qa_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        ward TEXT NOT NULL,
        target_mudhumeni_id TEXT DEFAULT '',
        is_public INTEGER DEFAULT 0,
        question TEXT NOT NULL,
        answer TEXT DEFAULT '',
        answered_by TEXT DEFAULT '',
        answered_by_mudhumeni INTEGER DEFAULT 0,
        upvotes INTEGER DEFAULT 0,
        upvoted_by TEXT NOT NULL DEFAULT '',
        made_public INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        answered_at TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS community_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        ward TEXT NOT NULL,
        post_type TEXT DEFAULT 'text',
        content TEXT NOT NULL,
        photo_path TEXT DEFAULT '',
        poll_options TEXT DEFAULT '[]',
        reactions INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS field_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        farmer_name TEXT NOT NULL,
        farmer_phone TEXT NOT NULL DEFAULT '',
        mudhumeni_id TEXT DEFAULT '',
        mudhumeni_name TEXT DEFAULT '',
        ward TEXT NOT NULL,
        purpose TEXT NOT NULL,
        notes TEXT DEFAULT '',
        requested_date TEXT NOT NULL,
        scheduled_date TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS seasonal_calendar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mudhumeni_id TEXT NOT NULL,
        ward TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        notes TEXT DEFAULT '',
        is_done INTEGER DEFAULT 0,
        season TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS problem_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reporter_id TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        ward TEXT NOT NULL,
        district TEXT NOT NULL,
        problem_type TEXT NOT NULL,
        description TEXT NOT NULL,
        crop_affected TEXT DEFAULT '',
        latitude REAL DEFAULT 0.0,
        longitude REAL DEFAULT 0.0,
        is_resolved INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── MUDHUMENI PROFILE ─────────────────────────────────
  static Future<int> saveProfile(MudhumeniProfile p) async {
    final db = await DatabaseService().database;
    return db.insert('mudhumeni_profiles', p.toMap());
  }

  static Future<MudhumeniProfile?> getProfileByUserId(String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('mudhumeni_profiles',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return MudhumeniProfile.fromMap(rows.first);
  }

  static Future<void> updateProfileStatus(int id, String status) async {
    final db = await DatabaseService().database;
    await db.update(
      'mudhumeni_profiles',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<MudhumeniProfile>> getAllMudhumeniProfiles() async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'mudhumeni_profiles',
      orderBy: 'created_at DESC',
    );
    return rows.map(MudhumeniProfile.fromMap).toList();
  }

  static Future<List<MudhumeniProfile>> getVerifiedMudhumeniByWard(
      String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'mudhumeni_profiles',
      where: 'ward = ? AND status = ?',
      whereArgs: [ward, 'verified'],
    );
    return rows.map(MudhumeniProfile.fromMap).toList();
  }

  // ── KNOWLEDGE POSTS ───────────────────────────────────
  static Future<int> savePost(KnowledgePost post) async {
    final db = await DatabaseService().database;
    return db.insert('knowledge_posts', post.toMap());
  }

  static Future<List<KnowledgePost>> getPostsByWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('knowledge_posts',
        where: 'ward = ?',
        whereArgs: [ward],
        orderBy: 'created_at DESC');
    return rows.map(KnowledgePost.fromMap).toList();
  }

  static Future<void> markPostRead(int id) async {
    final db = await DatabaseService().database;
    await db.update('knowledge_posts', {'is_read': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> countUnreadPosts(String ward) async {
    final db = await DatabaseService().database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM knowledge_posts WHERE ward = ? AND is_read = 0',
        [ward]);
    return result.first['cnt'] as int? ?? 0;
  }

  // ── Q&A ───────────────────────────────────────────────
  static Future<int> saveQuestion(QaQuestion q) async {
    final db = await DatabaseService().database;
    return db.insert('qa_questions', q.toMap());
  }

  static Future<List<QaQuestion>> getPublicQuestions(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('qa_questions',
        where: 'ward = ? AND is_public = 1',
        whereArgs: [ward],
        orderBy: 'created_at DESC');
    return rows.map(QaQuestion.fromMap).toList();
  }

  static Future<List<QaQuestion>> getPrivateQuestions(
      String farmerId, String mudhumeniId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('qa_questions',
        where:
            'author_id = ? AND target_mudhumeni_id = ? AND is_public = 0',
        whereArgs: [farmerId, mudhumeniId],
        orderBy: 'created_at DESC');
    return rows.map(QaQuestion.fromMap).toList();
  }

  static Future<List<QaQuestion>> getPrivateQuestionsForMudhumeni(
      String mudhumeniId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('qa_questions',
        where: 'target_mudhumeni_id = ? AND is_public = 0',
        whereArgs: [mudhumeniId],
        orderBy: 'created_at DESC');
    return rows.map(QaQuestion.fromMap).toList();
  }

  static Future<void> answerQuestion(int id, String answer,
      String answeredBy, bool byMudhumeni) async {
    final db = await DatabaseService().database;
    await db.update(
      'qa_questions',
      {
        'answer': answer,
        'answered_by': answeredBy,
        'answered_by_mudhumeni': byMudhumeni ? 1 : 0,
        'answered_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> toggleUpvote(int questionId, String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('qa_questions',
        columns: ['upvotes', 'upvoted_by'],
        where: 'id = ?',
        whereArgs: [questionId],
        limit: 1);
    if (rows.isEmpty) return false;

    final currentUpvotes = rows.first['upvotes'] as int? ?? 0;
    final upvotedBy = rows.first['upvoted_by'] as String? ?? '';
    final voters = upvotedBy.isEmpty
        ? <String>[]
        : upvotedBy.split(',').map((e) => e.trim()).toList();

    final alreadyVoted = voters.contains(userId);

    if (alreadyVoted) {
      voters.remove(userId);
      await db.update(
        'qa_questions',
        {
          'upvotes': (currentUpvotes - 1).clamp(0, 99999),
          'upvoted_by': voters.join(','),
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
      return false;
    } else {
      voters.add(userId);
      await db.update(
        'qa_questions',
        {
          'upvotes': currentUpvotes + 1,
          'upvoted_by': voters.join(','),
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
      return true;
    }
  }

  static Future<void> upvoteQuestion(int id) async {
    final db = await DatabaseService().database;
    await db.rawUpdate(
        'UPDATE qa_questions SET upvotes = upvotes + 1 WHERE id = ?', [id]);
  }

  static Future<Set<int>> getUserUpvotedIds(String userId) async {
    if (userId.isEmpty) return {};
    try {
      final db = await DatabaseService().database;
      final rows = await db.query(
        'qa_questions',
        columns: ['id', 'upvoted_by'],
        where: "upvoted_by LIKE ?",
        whereArgs: ['%$userId%'],
      );
      final Set<int> result = {};
      for (final row in rows) {
        final id = row['id'] as int?;
        final upvotedBy = row['upvoted_by'] as String? ?? '';
        if (id != null &&
            upvotedBy.split(',').map((e) => e.trim()).contains(userId)) {
          result.add(id);
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> incrementQuestionUpvotes(int questionId) async {
    final db = await DatabaseService().database;
    await db.rawUpdate(
      'UPDATE qa_questions SET upvotes = upvotes + 1 WHERE id = ?',
      [questionId],
    );
  }

  static Future<void> decrementQuestionUpvotes(int questionId) async {
    final db = await DatabaseService().database;
    await db.rawUpdate(
      'UPDATE qa_questions SET upvotes = CASE WHEN upvotes > 0 THEN upvotes - 1 ELSE 0 END WHERE id = ?',
      [questionId],
    );
  }

  static Future<void> makePublic(int id) async {
    final db = await DatabaseService().database;
    await db.update('qa_questions',
        {'made_public': 1, 'is_public': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── COMMUNITY POSTS ───────────────────────────────────
  static Future<int> saveCommunityPost(CommunityPost post) async {
    final db = await DatabaseService().database;
    return db.insert('community_posts', post.toMap());
  }

  static Future<List<CommunityPost>> getCommunityPosts(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('community_posts',
        where: 'ward = ? AND is_deleted = 0',
        whereArgs: [ward],
        orderBy: 'created_at DESC');
    return rows.map(CommunityPost.fromMap).toList();
  }

  static Future<void> reactToPost(int id) async {
    final db = await DatabaseService().database;
    await db.rawUpdate(
        'UPDATE community_posts SET reactions = reactions + 1 WHERE id = ?',
        [id]);
  }

  static Future<void> deletePost(int id) async {
    final db = await DatabaseService().database;
    await db.update('community_posts', {'is_deleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── FIELD VISITS ──────────────────────────────────────
  static Future<int> saveVisitRequest(FieldVisit visit) async {
    final db = await DatabaseService().database;
    return db.insert('field_visits', visit.toMap());
  }

  static Future<List<FieldVisit>> getVisitsByMudhumeni(String mudhumeniId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('field_visits',
        where: 'mudhumeni_id = ?',
        whereArgs: [mudhumeniId],
        orderBy: 'requested_date DESC');
    return rows.map(FieldVisit.fromMap).toList();
  }

  static Future<List<FieldVisit>> getVisitsByFarmer(String farmerId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('field_visits',
        where: 'farmer_id = ?',
        whereArgs: [farmerId],
        orderBy: 'created_at DESC');
    return rows.map(FieldVisit.fromMap).toList();
  }

  static Future<List<FieldVisit>> getPendingVisitsInWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('field_visits',
        where: 'ward = ? AND status = ?',
        whereArgs: [ward, 'pending'],
        orderBy: 'requested_date DESC');
    return rows.map(FieldVisit.fromMap).toList();
  }

  static Future<List<FieldVisit>> getAllVisitsInWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('field_visits',
        where: 'ward = ?',
        whereArgs: [ward],
        orderBy: 'requested_date DESC');
    return rows.map(FieldVisit.fromMap).toList();
  }

  static Future<void> createFieldVisit(FieldVisit visit) async {
    final db = await DatabaseService().database;
    await db.insert('field_visits', visit.toMap());
  }

  static Future<void> updateVisitStatus(
    int visitId,
    String status, {
    String? mudhumeniId,
    String? mudhumeniName,
    DateTime? scheduledDate,
  }) async {
    final db = await DatabaseService().database;
    final data = <String, dynamic>{'status': status};
    
    if (mudhumeniId != null) data['mudhumeni_id'] = mudhumeniId;
    if (mudhumeniName != null) data['mudhumeni_name'] = mudhumeniName;
    if (scheduledDate != null) data['scheduled_date'] = scheduledDate.toIso8601String();
    
    await db.update(
      'field_visits',
      data,
      where: 'id = ?',
      whereArgs: [visitId],
    );
  }

  // ── SEASONAL CALENDAR ─────────────────────────────────
  static Future<int> saveSeasonalEntry(SeasonalEntry entry) async {
    final db = await DatabaseService().database;
    return db.insert('seasonal_calendar', entry.toMap());
  }

  static Future<List<SeasonalEntry>> getCalendarByWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('seasonal_calendar',
        where: 'ward = ?',
        whereArgs: [ward],
        orderBy: 'scheduled_date ASC');
    return rows.map(SeasonalEntry.fromMap).toList();
  }

  static Future<void> markEntryDone(int id, bool done) async {
    final db = await DatabaseService().database;
    await db.update('seasonal_calendar', {'is_done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteEntry(int id) async {
    final db = await DatabaseService().database;
    await db.delete('seasonal_calendar',
        where: 'id = ?', whereArgs: [id]);
  }

  // ── PROBLEM REPORTS ───────────────────────────────────
  static Future<int> saveProblemReport(ProblemReport report) async {
    final db = await DatabaseService().database;
    return db.insert('problem_reports', report.toMap());
  }

  static Future<List<ProblemReport>> getReportsByWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.query('problem_reports',
        where: 'ward = ? AND is_resolved = 0',
        whereArgs: [ward],
        orderBy: 'created_at DESC');
    return rows.map(ProblemReport.fromMap).toList();
  }

  static Future<List<ProblemReport>> getAllReports() async {
    final db = await DatabaseService().database;
    final rows = await db.query('problem_reports',
        orderBy: 'created_at DESC');
    return rows.map(ProblemReport.fromMap).toList();
  }

  static Future<void> resolveReport(int id) async {
    final db = await DatabaseService().database;
    await db.update('problem_reports', {'is_resolved': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── ACTIVITY STATS (FOR AREA MANAGEMENT) ──────────────
  static Future<List<QaQuestion>> getQuestionsByUser(String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('qa_questions',
        where: 'author_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC');
    return rows.map(QaQuestion.fromMap).toList();
  }

  static Future<List<CommunityPost>> getCommunityPostsByUser(String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query('community_posts',
        where: 'author_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC');
    return rows.map(CommunityPost.fromMap).toList();
  }
}