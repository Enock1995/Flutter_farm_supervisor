// lib/services/database_service.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../constants/app_theme.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        email TEXT,
        district TEXT NOT NULL,
        province TEXT NOT NULL,
        agro_region TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        registered_at TEXT NOT NULL,
        trial_ends_at TEXT NOT NULL,
        is_subscribed INTEGER NOT NULL DEFAULT 0,
        subscribed_at TEXT,
        password_hash TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE farm_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        farm_size_hectares REAL NOT NULL,
        farm_size_category TEXT NOT NULL,
        crops TEXT NOT NULL DEFAULT '',
        livestock TEXT NOT NULL DEFAULT '',
        soil_type TEXT NOT NULL,
        water_source TEXT NOT NULL,
        has_irrigation INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE unknown_districts (
        id TEXT PRIMARY KEY,
        district_name TEXT NOT NULL,
        province_suggested TEXT,
        submitted_by_user_id TEXT NOT NULL,
        submitted_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        region_assigned TEXT,
        verified_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE learned_districts (
        district_name TEXT PRIMARY KEY,
        province TEXT NOT NULL,
        agro_region TEXT NOT NULL,
        district_code TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_id_counter (
        district_code TEXT PRIMARY KEY,
        next_number INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE advisory_tips (
        id TEXT PRIMARY KEY,
        region TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        season TEXT,
        is_urgent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE crop_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        field_size_ha REAL,
        planting_date TEXT,
        expected_harvest_date TEXT,
        actual_harvest_date TEXT,
        yield_kg REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE livestock_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        count INTEGER NOT NULL,
        breed TEXT,
        notes TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS finance_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        crop_or_animal TEXT,
        notes TEXT
      )
    ''');
  }

  // ===========================================================================
  // USER OPERATIONS
  // ===========================================================================

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'phone = ?', whereArgs: [phone], limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByPublicId(String userId) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<bool> isPhoneRegistered(String phone) async {
    final db = await database;
    final result = await db.query('users',
        columns: ['id'],
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1);
    return result.isNotEmpty;
  }

  Future<void> updateSubscription(String userId, bool isSubscribed) async {
    final db = await database;
    await db.update(
      'users',
      {
        'is_subscribed': isSubscribed ? 1 : 0,
        'subscribed_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ===========================================================================
  // USER_ID COUNTER
  // ===========================================================================

  Future<int> getNextUserNumber(String districtCode) async {
    final db = await database;
    final code = districtCode.toUpperCase();

    final existing = await db.query('user_id_counter',
        where: 'district_code = ?', whereArgs: [code], limit: 1);

    if (existing.isEmpty) {
      await db.insert('user_id_counter', {
        'district_code': code,
        'next_number': 2,
      });
      return 1;
    }

    final current = existing.first['next_number'] as int;
    await db.update(
      'user_id_counter',
      {'next_number': current + 1},
      where: 'district_code = ?',
      whereArgs: [code],
    );
    return current;
  }

  // ===========================================================================
  // DISTRICT LEARNING
  // ===========================================================================

  Future<void> submitUnknownDistrict(UnknownDistrict district) async {
    final db = await database;
    await db.insert('unknown_districts', district.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Map<String, dynamic>?> getLearnedDistrict(
      String districtName) async {
    final db = await database;
    final key = districtName.trim().toLowerCase();
    final result = await db.query('learned_districts',
        where: 'LOWER(district_name) = ?', whereArgs: [key], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<void> saveLearnedDistrict({
    required String districtName,
    required String province,
    required String agroRegion,
    required String districtCode,
  }) async {
    final db = await database;
    await db.insert(
      'learned_districts',
      {
        'district_name': districtName,
        'province': province,
        'agro_region': agroRegion,
        'district_code': districtCode,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // FARM PROFILE
  // ===========================================================================

  Future<void> saveFarmProfile(FarmProfile profile) async {
    final db = await database;
    final existing = await db.query('farm_profiles',
        where: 'user_id = ?', whereArgs: [profile.userId], limit: 1);

    final map = profile.toMap()..['id'] = profile.userId;

    if (existing.isEmpty) {
      await db.insert('farm_profiles', map);
    } else {
      await db.update('farm_profiles', map,
          where: 'user_id = ?', whereArgs: [profile.userId]);
    }
  }

  Future<FarmProfile?> getFarmProfile(String userId) async {
    final db = await database;
    final maps = await db.query('farm_profiles',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (maps.isEmpty) return null;
    return FarmProfile.fromMap(maps.first);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('farm_profiles');
    await db.delete('unknown_districts');
    await db.delete('user_id_counter');
    await db.delete('learned_districts');
  }
}