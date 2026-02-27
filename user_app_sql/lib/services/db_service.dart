import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _database;
  bool _isInitializing = false;

  // 🔹 Obtener la factory correcta según la plataforma
  DatabaseFactory get _dbFactory {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  // 🔹 Obtener instancia de la BD
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    
    // Evitar inicialización concurrente
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    if (_database != null && _database!.isOpen) return _database!;
    
    _isInitializing = true;
    try {
      _database = await _initDb();
      return _database!;
    } finally {
      _isInitializing = false;
    }
  }

  // 🔹 Inicializar BD
  Future<Database> _initDb() async {
    final dbPath = await _dbFactory.getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return await _dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              email TEXT,
              password TEXT
            )
          ''');
        },
      ),
    );
  }

  // 🔹 INSERT
  Future<int> insertUser(User user) async {
    final db = await database;
    final map = user.toMap();
    map.remove('id'); // Eliminar id para que SQLite genere uno nuevo
    return await db.insert(
      'users',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔹 GET ALL
  Future<List<User>> getUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'id DESC');
    return res.map((e) => User.fromMap(e)).toList();
  }

  // 🔹 UPDATE
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // 🔹 DELETE
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
