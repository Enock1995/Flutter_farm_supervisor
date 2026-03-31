// lib/services/vet_database_service.dart
// Developed by Sir Enocks Cor Technologies
// Veterinary Services Database Operations

import '../models/vet_model.dart';
import 'database_service.dart';

class VetDatabaseService {
  // ══════════════════════════════════════════════════════════════════════════
  // CREATE ALL TABLES
  // ══════════════════════════════════════════════════════════════════════════
  
  static Future<void> createTables(dynamic db) async {
    // ── 1. VET PROFILES ─────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        registration_number TEXT NOT NULL,
        specialization TEXT DEFAULT 'general',
        qualification TEXT NOT NULL,
        years_experience INTEGER DEFAULT 0,
        district TEXT NOT NULL,
        wards TEXT NOT NULL DEFAULT '',
        province TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT DEFAULT '',
        id_photo_path TEXT DEFAULT '',
        certificate_photo_path TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // ── 2. VET KNOWLEDGE POSTS ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_knowledge_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        vet_id INTEGER NOT NULL,
        district TEXT NOT NULL,
        wards TEXT NOT NULL DEFAULT '',
        post_type TEXT DEFAULT 'article',
        category TEXT DEFAULT 'general',
        animal_type TEXT DEFAULT 'all',
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        photo_path TEXT DEFAULT '',
        is_urgent INTEGER DEFAULT 0,
        views INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── 3. VET Q&A QUESTIONS ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_qa_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        animal_count INTEGER DEFAULT 1,
        district TEXT NOT NULL,
        ward TEXT NOT NULL,
        target_vet_id TEXT DEFAULT '',
        is_public INTEGER DEFAULT 0,
        question TEXT NOT NULL,
        symptoms TEXT DEFAULT '',
        duration TEXT DEFAULT '',
        photo_path TEXT DEFAULT '',
        answer TEXT DEFAULT '',
        answered_by TEXT DEFAULT '',
        answered_by_vet INTEGER DEFAULT 0,
        diagnosis TEXT DEFAULT '',
        treatment_plan TEXT DEFAULT '',
        upvotes INTEGER DEFAULT 0,
        upvoted_by TEXT NOT NULL DEFAULT '',
        made_public INTEGER DEFAULT 0,
        urgency TEXT DEFAULT 'normal',
        created_at TEXT NOT NULL,
        answered_at TEXT DEFAULT ''
      )
    ''');

    // ── 4. VET FARM VISITS ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_farm_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        farmer_name TEXT NOT NULL,
        farmer_phone TEXT NOT NULL,
        vet_id TEXT NOT NULL,
        vet_name TEXT NOT NULL,
        district TEXT NOT NULL,
        ward TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        animal_count INTEGER DEFAULT 1,
        preferred_date TEXT NOT NULL,
        confirmed_date TEXT DEFAULT '',
        visit_time TEXT DEFAULT '',
        status TEXT DEFAULT 'requested',
        visit_notes TEXT DEFAULT '',
        diagnosis TEXT DEFAULT '',
        treatment_given TEXT DEFAULT '',
        follow_up_needed INTEGER DEFAULT 0,
        follow_up_date TEXT DEFAULT '',
        visit_fee_usd REAL DEFAULT 0.0,
        is_paid INTEGER DEFAULT 0,
        latitude REAL DEFAULT 0.0,
        longitude REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        completed_at TEXT DEFAULT ''
      )
    ''');

    // ── 5. VET DISEASE REPORTS ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_disease_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reporter_id TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        reporter_type TEXT NOT NULL,
        district TEXT NOT NULL,
        ward TEXT NOT NULL,
        disease_name TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        affected_count INTEGER DEFAULT 1,
        deaths INTEGER DEFAULT 0,
        symptoms TEXT NOT NULL,
        outbreak_level TEXT DEFAULT 'isolated',
        latitude REAL DEFAULT 0.0,
        longitude REAL DEFAULT 0.0,
        photo_path TEXT DEFAULT '',
        is_verified INTEGER DEFAULT 0,
        verified_by TEXT DEFAULT '',
        verified_at TEXT DEFAULT '',
        is_resolved INTEGER DEFAULT 0,
        resolved_at TEXT DEFAULT '',
        action_taken TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // ── 6. VACCINATION SCHEDULES ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccination_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        vet_id TEXT DEFAULT '',
        animal_type TEXT NOT NULL,
        vaccine_name TEXT NOT NULL,
        vaccination_date TEXT NOT NULL,
        next_dose_date TEXT DEFAULT '',
        animal_count INTEGER DEFAULT 1,
        batch_number TEXT DEFAULT '',
        administered_by TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        reminder_sent INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── 7. VET COMMUNITY POSTS ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_community_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_type TEXT NOT NULL,
        district TEXT NOT NULL,
        ward TEXT NOT NULL,
        post_type TEXT DEFAULT 'text',
        animal_type TEXT DEFAULT 'general',
        content TEXT NOT NULL,
        photo_path TEXT DEFAULT '',
        reactions INTEGER DEFAULT 0,
        comments INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── 8. VET TREATMENTS ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        vet_id TEXT NOT NULL,
        visit_id INTEGER DEFAULT NULL,
        animal_type TEXT NOT NULL,
        animal_count INTEGER DEFAULT 1,
        diagnosis TEXT NOT NULL,
        treatment TEXT NOT NULL,
        medication TEXT DEFAULT '',
        dosage TEXT DEFAULT '',
        duration_days INTEGER DEFAULT 0,
        follow_up_needed INTEGER DEFAULT 0,
        follow_up_date TEXT DEFAULT '',
        cost_usd REAL DEFAULT 0.0,
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // ── 9. VET PRESCRIPTIONS ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        vet_id TEXT NOT NULL,
        treatment_id INTEGER DEFAULT NULL,
        animal_type TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        duration_days INTEGER DEFAULT 0,
        quantity TEXT NOT NULL,
        instructions TEXT NOT NULL,
        warnings TEXT DEFAULT '',
        prescription_date TEXT NOT NULL,
        is_dispensed INTEGER DEFAULT 0,
        dispensed_at TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // ── 10. ANIMAL HEALTH RECORDS ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS animal_health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        animal_id TEXT DEFAULT '',
        breed TEXT DEFAULT '',
        age_months INTEGER DEFAULT 0,
        gender TEXT DEFAULT '',
        weight_kg REAL DEFAULT 0.0,
        health_status TEXT DEFAULT 'healthy',
        last_checkup_date TEXT DEFAULT '',
        last_vaccination_date TEXT DEFAULT '',
        current_treatment TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ── 11. VET AVAILABILITY ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_availability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vet_id TEXT NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_available INTEGER DEFAULT 1,
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // ── 12. VET EMERGENCY CONTACTS ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        district TEXT NOT NULL,
        ward TEXT DEFAULT '',
        contact_name TEXT NOT NULL,
        contact_phone TEXT NOT NULL,
        contact_type TEXT NOT NULL,
        specialization TEXT DEFAULT '',
        address TEXT DEFAULT '',
        is_24_7 INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── 13. VET RESOURCES ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vet_id TEXT DEFAULT '',
        resource_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        animal_type TEXT DEFAULT 'all',
        category TEXT NOT NULL,
        file_path TEXT DEFAULT '',
        external_url TEXT DEFAULT '',
        views INTEGER DEFAULT 0,
        downloads INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── 14. VET NOTIFICATIONS ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        vet_id TEXT DEFAULT '',
        notification_type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        related_id TEXT DEFAULT '',
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VET PROFILE OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<int> saveProfile(VetProfile profile) async {
    final db = await DatabaseService().database;
    return db.insert('vet_profiles', profile.toMap());
  }

  static Future<VetProfile?> getProfileByUserId(String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VetProfile.fromMap(rows.first);
  }

  static Future<VetProfile?> getProfileById(int id) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VetProfile.fromMap(rows.first);
  }

  static Future<void> updateProfileStatus(int id, String status) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_profiles',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<VetProfile>> getAllVetProfiles() async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_profiles',
      orderBy: 'created_at DESC',
    );
    return rows.map(VetProfile.fromMap).toList();
  }

  static Future<List<VetProfile>> getVerifiedVetsByDistrict(
      String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_profiles',
      where: 'district = ? AND status = ?',
      whereArgs: [district, 'verified'],
      orderBy: 'full_name ASC',
    );
    return rows.map(VetProfile.fromMap).toList();
  }

  static Future<List<VetProfile>> getVerifiedVetsByWard(String ward) async {
    final db = await DatabaseService().database;
    final rows = await db.rawQuery('''
      SELECT * FROM vet_profiles 
      WHERE status = 'verified' 
      AND (wards LIKE ? OR wards LIKE ? OR wards LIKE ? OR wards = ?)
      ORDER BY full_name ASC
    ''', ['%,$ward,%', '$ward,%', '%,$ward', ward]);
    return rows.map(VetProfile.fromMap).toList();
  }

  static Future<List<VetProfile>> getPendingVets() async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_profiles',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetProfile.fromMap).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KNOWLEDGE POSTS OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<int> savePost(VetKnowledgePost post) async {
    final db = await DatabaseService().database;
    return db.insert('vet_knowledge_posts', post.toMap());
  }

  static Future<List<VetKnowledgePost>> getPostsByDistrict(
      String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_knowledge_posts',
      where: 'district = ?',
      whereArgs: [district],
      orderBy: 'is_urgent DESC, created_at DESC',
    );
    return rows.map(VetKnowledgePost.fromMap).toList();
  }

  static Future<List<VetKnowledgePost>> getPostsByAnimalType(
      String animalType, String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_knowledge_posts',
      where: 'district = ? AND (animal_type = ? OR animal_type = ?)',
      whereArgs: [district, animalType, 'all'],
      orderBy: 'is_urgent DESC, created_at DESC',
    );
    return rows.map(VetKnowledgePost.fromMap).toList();
  }

  static Future<List<VetKnowledgePost>> getUrgentPosts(String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_knowledge_posts',
      where: 'district = ? AND is_urgent = 1',
      whereArgs: [district],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetKnowledgePost.fromMap).toList();
  }

  static Future<void> incrementViews(int id) async {
    final db = await DatabaseService().database;
    await db.rawUpdate(
      'UPDATE vet_knowledge_posts SET views = views + 1 WHERE id = ?',
      [id],
    );
  }

  static Future<void> markPostRead(int id) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_knowledge_posts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Q&A OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<int> saveQuestion(VetQuestion question) async {
    final db = await DatabaseService().database;
    return db.insert('vet_qa_questions', question.toMap());
  }

  static Future<List<VetQuestion>> getPublicQuestions(String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_qa_questions',
      where: 'district = ? AND is_public = 1',
      whereArgs: [district],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetQuestion.fromMap).toList();
  }

  static Future<List<VetQuestion>> getPrivateQuestions(
      String farmerId, String vetId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_qa_questions',
      where: 'author_id = ? AND target_vet_id = ? AND is_public = 0',
      whereArgs: [farmerId, vetId],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetQuestion.fromMap).toList();
  }

  static Future<List<VetQuestion>> getPrivateQuestionsForVet(
      String vetId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_qa_questions',
      where: 'target_vet_id = ? AND is_public = 0',
      whereArgs: [vetId],
      orderBy: 'urgency DESC, created_at DESC',
    );
    return rows.map(VetQuestion.fromMap).toList();
  }

  static Future<void> answerQuestion({
    required int id,
    required String answer,
    required String answeredBy,
    required bool byVet,
    String diagnosis = '',
    String treatmentPlan = '',
  }) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_qa_questions',
      {
        'answer': answer,
        'answered_by': answeredBy,
        'answered_by_vet': byVet ? 1 : 0,
        'diagnosis': diagnosis,
        'treatment_plan': treatmentPlan,
        'answered_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> toggleUpvote(int questionId, String userId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_qa_questions',
      columns: ['upvotes', 'upvoted_by'],
      where: 'id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
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
        'vet_qa_questions',
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
        'vet_qa_questions',
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

  static Future<Set<int>> getUserUpvotedIds(String userId) async {
    if (userId.isEmpty) return {};
    try {
      final db = await DatabaseService().database;
      final rows = await db.query(
        'vet_qa_questions',
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

  static Future<void> makePublic(int id) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_qa_questions',
      {'made_public': 1, 'is_public': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FARM VISIT OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<int> saveVisitRequest(VetVisit visit) async {
    final db = await DatabaseService().database;
    return db.insert('vet_farm_visits', visit.toMap());
  }

  static Future<List<VetVisit>> getVisitsByVet(String vetId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_farm_visits',
      where: 'vet_id = ?',
      whereArgs: [vetId],
      orderBy: 'preferred_date ASC',
    );
    return rows.map(VetVisit.fromMap).toList();
  }

  static Future<List<VetVisit>> getVisitsByFarmer(String farmerId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_farm_visits',
      where: 'farmer_id = ?',
      whereArgs: [farmerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetVisit.fromMap).toList();
  }

  static Future<void> updateVisitStatus({
    required int id,
    required String status,
    String? confirmedDate,
    String? visitTime,
  }) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_farm_visits',
      {
        'status': status,
        if (confirmedDate != null) 'confirmed_date': confirmedDate,
        if (visitTime != null) 'visit_time': visitTime,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> completeVisit({
    required int id,
    required String diagnosis,
    required String treatment,
    String visitNotes = '',
    int followUpNeeded = 0,
    String followUpDate = '',
  }) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_farm_visits',
      {
        'status': 'completed',
        'diagnosis': diagnosis,
        'treatment_given': treatment,
        'visit_notes': visitNotes,
        'follow_up_needed': followUpNeeded,
        'follow_up_date': followUpDate,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DISEASE REPORT OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<int> saveDiseaseReport(VetDiseaseReport report) async {
    final db = await DatabaseService().database;
    return db.insert('vet_disease_reports', report.toMap());
  }

  static Future<List<VetDiseaseReport>> getReportsByDistrict(
      String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_disease_reports',
      where: 'district = ?',
      whereArgs: [district],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetDiseaseReport.fromMap).toList();
  }

  static Future<List<VetDiseaseReport>> getUnverifiedReports() async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_disease_reports',
      where: 'is_verified = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(VetDiseaseReport.fromMap).toList();
  }

  static Future<List<VetDiseaseReport>> getActiveOutbreaks(
      String district) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      'vet_disease_reports',
      where: 'district = ? AND is_resolved = 0',
      whereArgs: [district],
      orderBy: 'created_at DESC',
    );
    return rows.map(VetDiseaseReport.fromMap).toList();
  }

  static Future<void> verifyReport(int id, String vetName) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_disease_reports',
      {
        'is_verified': 1,
        'verified_by': vetName,
        'verified_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> resolveReport(int id, String actionTaken) async {
    final db = await DatabaseService().database;
    await db.update(
      'vet_disease_reports',
      {
        'is_resolved': 1,
        'resolved_at': DateTime.now().toIso8601String(),
        'action_taken': actionTaken,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}