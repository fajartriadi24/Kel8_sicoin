import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ==========================================// MODEL USER
// ==========================================
class User {
  final int? id;
  final String name;
  final String email;
  final String password;

  User({this.id, required this.name, required this.email, required this.password});

  User copyWith({int? id, String? name, String? email, String? password}) =>
      User(id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, password: password ?? this.password);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email, 'password': password};

  factory User.fromMap(Map<String, dynamic> map) =>
      User(id: map['id'], name: map['name'], email: map['email'], password: map['password']);
}

// ==========================================
// MODEL TARGET (DIPERBARUI)
// ==========================================
class TargetModel {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String savingPlan; // Tambahan: 'daily', 'weekly', atau 'monthly'

  TargetModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.endDate,
    this.savingPlan = 'daily', // Default ke harian
  });

  double get progress {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  TargetModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? savingPlan,
  }) => TargetModel(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    savingPlan: savingPlan ?? this.savingPlan,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'savingPlan': savingPlan, // Masuk ke Database
  };

  factory TargetModel.fromMap(Map<String, dynamic> map) => TargetModel(
    id: map['id'],
    name: map['name'],
    targetAmount: map['targetAmount'],
    currentAmount: map['currentAmount'],
    startDate: DateTime.parse(map['startDate']),
    endDate: DateTime.parse(map['endDate']),
    savingPlan: map['savingPlan'] ?? 'daily', // Ambil dari Database
  );
}

// ==========================================
// DATABASE SERVICE (DIPERBARUI)
// ==========================================
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  int? _activeUserId;
  static Database? _globalDatabase;

  Future<Database> get _globalDb async {
    if (_globalDatabase != null) return _globalDatabase!;
    _globalDatabase = await _initializeGlobalDatabase();
    return _globalDatabase!;
  }

  Future<Database> _initializeGlobalDatabase() async {
    String path = join(await getDatabasesPath(), 'sicoin_global.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            reset_code TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE users ADD COLUMN reset_code TEXT;");
        }
      },
    );
  }

  // --- Database Per User ---
  Future<Database> getDatabaseForUser(int userId) async {
    if (_database != null && _activeUserId == userId) return _database!;
    _activeUserId = userId;
    _database = await _initializeUserDatabase(userId);
    return _database!;
  }

  Future<Database> _initializeUserDatabase(int userId) async {
    String path = join(await getDatabasesPath(), 'sicoin_user_$userId.db');
    return await openDatabase(
      path,
      version: 2, // Naikkan versi ke 2 untuk kolom baru
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE targets (
            id TEXT PRIMARY KEY, 
            name TEXT, 
            targetAmount REAL, 
            currentAmount REAL, 
            startDate TEXT, 
            endDate TEXT,
            savingPlan TEXT -- Kolom Baru
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Jika user lama update app, kolom savingPlan ditambahkan otomatis
          await db.execute("ALTER TABLE targets ADD COLUMN savingPlan TEXT DEFAULT 'daily'");
        }
      },
    );
  }

  // --- Operasi CRUD Target ---
  Future<void> insertTarget(int userId, TargetModel target) async {
    final db = await getDatabaseForUser(userId);
    await db.insert('targets', target.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TargetModel>> getTargets(int userId) async {
    final db = await getDatabaseForUser(userId);
    final maps = await db.query('targets');
    return List.generate(maps.length, (i) => TargetModel.fromMap(maps[i]));
  }

  Future<void> updateTarget(int userId, TargetModel target) async {
    final db = await getDatabaseForUser(userId);
    await db.update('targets', target.toMap(), where: 'id = ?', whereArgs: [target.id]);
  }

  Future<void> deleteTarget(int userId, String targetId) async {
    final db = await getDatabaseForUser(userId);
    await db.delete('targets', where: 'id = ?', whereArgs: [targetId]);
  }

  // --- Operasi User Global ---
  Future<int> insertUser(User user) async {
    final db = await _globalDb;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _globalDb;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<User?> getUserById(int userId) async {
    final db = await _globalDb;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<void> updateUserProfile(User user) async {
    final db = await _globalDb;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> updateUserPassword(int userId, String newPassword) async {
    final db = await _globalDb;
    await db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [userId]);
  }

  // --- Lupa Password (Console Debug) ---
  Future<String?> generateAndSaveResetCode(String email) async {
    final db = await _globalDb;
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);

    if (users.isNotEmpty) {
      String code = (100000 + Random().nextInt(900000)).toString();
      await db.update('users', {'reset_code': code}, where: 'email = ?', whereArgs: [email]);

      debugPrint("\n************************************************************");
      debugPrint(">>> KODE VERIFIKASI UNTUK $email ADALAH: $code <<<");
      debugPrint("************************************************************\n");

      return code;
    }
    return null;
  }

  Future<bool> verifyCodeAndResetPassword(String email, String code, String newPassword) async {
    final db = await _globalDb;
    final users = await db.query('users', where: 'email = ? AND reset_code = ?', whereArgs: [email, code]);
    if (users.isNotEmpty) {
      await db.update('users', {'password': newPassword, 'reset_code': null}, where: 'email = ?', whereArgs: [email]);
      return true;
    }
    return false;
  }

  Future<void> deleteUserAccount(int userId) async {
    final db = await _globalDb;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    String path = join(await getDatabasesPath(), 'sicoin_user_$userId.db');
    try {
      await deleteDatabase(path);
      debugPrint("Database user $userId dihapus.");
    } catch (e) {
      debugPrint("Gagal menghapus database: $e");
    }
    _database = null;
    _activeUserId = null;
  }
}
