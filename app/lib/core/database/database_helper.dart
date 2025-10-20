import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vocab_plus.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tạo bảng desks
    await db.execute('''
      CREATE TABLE desks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT DEFAULT '#2196F3',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Tạo bảng vocabularies
    await db.execute('''
      CREATE TABLE vocabularies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        desk_id INTEGER NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        image_url TEXT,
        image_path TEXT,
        back_image_url TEXT,
        back_image_path TEXT,
        front_extra_json TEXT,
        back_extra_json TEXT,
        mastery_level INTEGER DEFAULT 0,
        last_reviewed TEXT,
        next_review TEXT,
        -- SRS fields (SM-2)
        srs_ease_factor REAL DEFAULT 2.5,
        srs_interval INTEGER DEFAULT 0, -- days
        srs_repetitions INTEGER DEFAULT 0,
        srs_due TEXT,
        -- Anki-like scheduler state
        srs_type INTEGER DEFAULT 0, -- 0=new, 1=learning, 2=review
        srs_queue INTEGER DEFAULT 0, -- 0=new, 1=learning, 2=review
        srs_lapses INTEGER DEFAULT 0,
        srs_left INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        card_type TEXT DEFAULT 'basis',
        FOREIGN KEY (desk_id) REFERENCES desks (id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng study_sessions để theo dõi lịch sử học
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        desk_id INTEGER NOT NULL,
        vocabulary_id INTEGER NOT NULL,
        session_type TEXT NOT NULL, -- 'learn', 'review', 'test'
        result TEXT NOT NULL, -- 'correct', 'incorrect', 'skipped'
        time_spent INTEGER DEFAULT 0, -- thời gian tính bằng giây
        created_at TEXT NOT NULL,
        FOREIGN KEY (desk_id) REFERENCES desks (id) ON DELETE CASCADE,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabularies (id) ON DELETE CASCADE
      )
    ''');

    // Tạo indexes để tối ưu hiệu suất
    await db.execute(
        'CREATE INDEX idx_vocabularies_desk_id ON vocabularies(desk_id)');
    await db.execute(
        'CREATE INDEX idx_vocabularies_next_review ON vocabularies(next_review)');
    await db.execute(
        'CREATE INDEX idx_vocabularies_srs_due ON vocabularies(srs_due)');
    await db.execute(
        'CREATE INDEX idx_study_sessions_desk_id ON study_sessions(desk_id)');
    await db.execute(
        'CREATE INDEX idx_study_sessions_vocabulary_id ON study_sessions(vocabulary_id)');

    // Tạo bảng search_history
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_search_history_created_at ON search_history(created_at DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No upgrades needed - all fields are in CREATE TABLE from the start
  }

  // Đóng database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Xóa database (dùng cho testing hoặc reset)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'vocab_plus.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
