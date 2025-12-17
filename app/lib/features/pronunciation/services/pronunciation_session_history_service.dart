import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/pronunciation_session_history.dart';

class PronunciationSessionHistoryService {
  PronunciationSessionHistoryService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  static const int maxSessions = 100;

  Future<int> addSession({
    required Deck deck,
    required int totalWords,
    required int practicedWords,
    required double avgOverall,
    required double avgAccuracy,
    required double avgFluency,
    required double avgCompleteness,
    required int highCount,
    required int lowCount,
  }) async {
    final db = await _databaseHelper.database;
    // Đảm bảo bảng tồn tại trước khi insert
    await _ensureTableExists(db);
    final now = DateTime.now().toIso8601String();
    final row = {
      'deck_id': deck.id,
      'deck_name': deck.name,
      'total_words': totalWords,
      'practiced_words': practicedWords,
      'avg_overall': avgOverall,
      'avg_accuracy': avgAccuracy,
      'avg_fluency': avgFluency,
      'avg_completeness': avgCompleteness,
      'high_count': highCount,
      'low_count': lowCount,
      'created_at': now,
    };

    final id = await db.insert('pronunciation_session_history', row);

    // Trim bảng để không phình quá to
    await db.delete(
      'pronunciation_session_history',
      where:
          'id NOT IN (SELECT id FROM pronunciation_session_history ORDER BY created_at DESC LIMIT ?)',
      whereArgs: [maxSessions],
    );
    return id;
  }

  Future<List<PronunciationSessionHistory>> getRecent({
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;
    try {
      final rows = await db.query(
        'pronunciation_session_history',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows.map(PronunciationSessionHistory.fromMap).toList();
    } catch (e) {
      // Nếu bảng chưa tồn tại, thử tạo lại
      debugPrint('[PronunHistory] Table not found, attempting to create: $e');
      await _ensureTableExists(db);
      // Thử query lại
      final rows = await db.query(
        'pronunciation_session_history',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows.map(PronunciationSessionHistory.fromMap).toList();
    }
  }

  Future<void> _ensureTableExists(Database db) async {
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

  Future<void> clear() async {
    final db = await _databaseHelper.database;
    await db.delete('pronunciation_session_history');
  }

  Future<void> deleteById(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'pronunciation_session_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
