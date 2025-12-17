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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tạo bảng decks
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Tạo bảng vocabularies (thông tin từ vựng cơ bản, KHÔNG chứa trạng thái SRS)
    await db.execute('''
      CREATE TABLE vocabularies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        front_image_url TEXT,
        front_image_path TEXT,
        back_image_url TEXT,
        back_image_path TEXT,
        front_extra_json TEXT,
        back_extra_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        card_type TEXT DEFAULT 'basis',
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng vocabulary_srs chứa toàn bộ trạng thái SRS cho từng vocabulary
    await db.execute('''
      CREATE TABLE vocabulary_srs (
        vocabulary_id INTEGER PRIMARY KEY,
        mastery_level INTEGER DEFAULT 0,
        review_count INTEGER DEFAULT 0,
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
        FOREIGN KEY (vocabulary_id) REFERENCES vocabularies (id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng study_sessions để theo dõi lịch sử học
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        vocabulary_id INTEGER NOT NULL,
        session_type TEXT NOT NULL, -- 'learn', 'review', 'test'
        result TEXT NOT NULL, -- 'correct', 'incorrect', 'skipped'
        time_spent INTEGER DEFAULT 0, -- thời gian tính bằng giây
        created_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabularies (id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng pronunciation_session_history để lưu lịch sử phiên luyện phát âm
    await _createPronunciationSessionHistoryTable(db);

    // Tạo indexes để tối ưu hiệu suất
    await db.execute(
        'CREATE INDEX idx_vocabularies_deck_id ON vocabularies(deck_id)');
    await db.execute(
        'CREATE INDEX idx_vocabulary_srs_next_review ON vocabulary_srs(next_review)');
    await db.execute(
        'CREATE INDEX idx_vocabulary_srs_srs_due ON vocabulary_srs(srs_due)');
    await db.execute(
        'CREATE INDEX idx_study_sessions_deck_id ON study_sessions(deck_id)');
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

    // Tạo bảng notifications
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        time TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        type TEXT,
        vocabulary_id INTEGER,
        deck_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabularies (id) ON DELETE CASCADE,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_notifications_time ON notifications(time DESC)');
    await db.execute(
        'CREATE INDEX idx_notifications_is_read ON notifications(is_read)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Thêm bảng notifications cho version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          time TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          type TEXT,
          vocabulary_id INTEGER,
          deck_id INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (vocabulary_id) REFERENCES vocabularies (id) ON DELETE CASCADE,
          FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_notifications_time ON notifications(time DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read)');
    }
    if (oldVersion < 3) {
      // Thêm cột is_favorite cho version 3
      try {
        await db.execute(
            'ALTER TABLE decks ADD COLUMN is_favorite INTEGER DEFAULT 0');
      } catch (e) {
        // Cột có thể đã tồn tại, bỏ qua lỗi
        print('Column is_favorite might already exist: $e');
      }
    }
    if (oldVersion < 4) {
      await _createPronunciationSessionHistoryTable(db);
    }
  }

  Future<void> _createPronunciationSessionHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pronunciation_session_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER,
        deck_name TEXT NOT NULL,
        total_words INTEGER NOT NULL,
        practiced_words INTEGER NOT NULL,
        avg_overall REAL NOT NULL,
        avg_accuracy REAL NOT NULL,
        avg_fluency REAL NOT NULL,
        avg_completeness REAL NOT NULL,
        high_count INTEGER NOT NULL,
        low_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pron_sess_created_at ON pronunciation_session_history(created_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pron_sess_deck_id ON pronunciation_session_history(deck_id)');
  }

  // Đóng database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Xóa database
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'vocab_plus.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
