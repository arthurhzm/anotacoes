import 'package:sqflite/sqflite.dart';

// DatabaseHelper class
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Create the database
  Future<Database> _initDatabase() async {
    return openDatabase(
      'lembretes.db',
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        password TEXT
      );

      CREATE TABLE lembretes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title VARCHAR(50) NOT NULL,
        description VARCHAR(MAX) ,
        remember INTEGER,
        remember_type VARCHAR(10), -- minutes, hours, days, weeks, months, years

        FOREIGN KEY(user_id) REFERENCES usuarios(id)
      );
    ''');
  }

  // Insert data
  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await database;
    return db.insert(table, data);
  }

  // Query data
  Future<List<Map<String, dynamic>>> query(String table) async {
    Database db = await database;
    return db.query(table);
  }
}
